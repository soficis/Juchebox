import Combine
import Foundation
import WebKit

/// Read-only WebKit bridge that extracts the Juchify SPA player's state (track metadata,
/// play/pause status, stream URL) via a polling WKUserScript and sends control commands
/// by clicking the site's existing UI buttons. Conforms to `JSExtractorProtocol`.
@MainActor
final class JSPlayerBridge: NSObject, JSExtractorProtocol, WKScriptMessageHandler, ObservableObject {

    private(set) var latestState: PlayerState = .empty

    /// Number of state messages parsed from the injected script. 0 = the bridge
    /// has not heard from the page yet (script not installed, page not loaded,
    /// or JS error). Monotonic once connected — the probe view renders it.
    @Published private(set) var messageCount = 0

    private weak var webView: WKWebView?
    private let contentWorld = WKContentWorld.world(name: "juchebox_player")
    private let messageHandlerName = "playerBridge"

    // MARK: - JSExtractorProtocol

    /// Attaches the polling script and message handler to the given WebView.
    /// Safe to call multiple times (re-attach is idempotent — old handler and script
    /// are removed first).
    func attach(to webView: WKWebView) {
        let controller = webView.configuration.userContentController

        // Remove previous registration so re-attach is safe.
        controller.removeScriptMessageHandler(forName: messageHandlerName)
        removeAllScripts(from: controller, in: contentWorld)

        // Inject polling script.
        controller.addUserScript(Self.playerBridgeScript())

        // Register message handler for state updates.
        controller.add(self, name: messageHandlerName)

        self.webView = webView
    }

    /// Returns the most recently parsed player state.
    func extractState() async -> PlayerState {
        latestState
    }

    /// Sends a control command by evaluating JavaScript that clicks the site's
    /// corresponding player-bar button.
    func sendCommand(_ command: PlayerCommand) async {
        guard let webView else { return }
        guard let js = clickScript(for: command) else { return }

        _ = try? await webView.evaluateJavaScript(js, in: nil, contentWorld: contentWorld)
    }

    // MARK: - WKScriptMessageHandler

    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? [String: Any] else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.latestState = self.parseState(from: body)
            self.messageCount += 1
        }
    }

    // MARK: - Script

    /// Returns a `WKUserScript` that polls the Juchify SPA player bar every second,
    /// extracts track metadata and stream URL, and posts a JSON message to the
    /// native message handler.
    static func playerBridgeScript() -> WKUserScript {
        let source = """
        (function(){
            if (window.__juchebox_bridge_installed) return;
            window.__juchebox_bridge_installed = true;

            function scan() {
                var data = {};

                // --- playing / paused -------------------------------------------------
                var pauseBtn = document.querySelector('button.player-btn .lucide-pause');
                var playBtn  = document.querySelector('button.player-btn .lucide-play');
                data.playing = !!pauseBtn;

                // --- track title / artist (scan the player-bar region) -----------------
                data.title  = null;
                data.artist = null;

                // Try aria-labels on player-region elements.
                var playerBar = document.querySelector('[class*="player"],[class*="Player"]');
                if (playerBar) {
                    // Walk descendants and collect text from visible text nodes.
                    var texts = [];
                    var walker = document.createTreeWalker(playerBar, NodeFilter.SHOW_TEXT, null, false);
                    while (walker.nextNode()) {
                        var t = (walker.currentNode.textContent || '').trim();
                        if (t) texts.push(t);
                    }
                    // First non-trivial text tends to be the song title; second = artist.
                    if (texts.length >= 1) data.title = texts[0];
                    if (texts.length >= 2) data.artist = texts[1];
                }

                // Fallback: look for any visible heading or label near the player buttons.
                if (!data.title) {
                    var h = document.querySelector('button.player-btn')?.closest('[class*="player"]')?.querySelector('h1,h2,h3,h4,h5,h6,[aria-label]');
                    if (h) {
                        data.title = (h.getAttribute('aria-label') || h.textContent || '').trim() || null;
                    }
                }

                // --- artwork URL -------------------------------------------------------
                data.artUrl = null;
                if (playerBar) {
                    var img = playerBar.querySelector('img');
                    if (img && img.src) data.artUrl = img.src;
                }

                // --- stream URL (audio / video element src) ----------------------------
                data.streamUrl = null;
                var media = document.querySelector('audio') || document.querySelector('video');
                if (media && media.src) data.streamUrl = media.src;

                // --- time --------------------------------------------------------------
                data.currentTime = (media && !isNaN(media.currentTime)) ? media.currentTime : null;
                data.duration     = (media && !isNaN(media.duration) && isFinite(media.duration)) ? media.duration : null;

                window.webkit.messageHandlers.playerBridge.postMessage(JSON.stringify(data));
            }

            setInterval(scan, 1000);
            scan();  // immediate first scan
        })();
        """

        return WKUserScript(
            source: source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true,
            in: WKContentWorld.world(name: "juchebox_player")
        )
    }

    // MARK: - Helpers

    /// Parses the dictionary received from the JS polling script into a `PlayerState`.
    // @testable — internal so tests can exercise parsing directly.
    func parseState(from body: [String: Any]) -> PlayerState {
        let isPlaying = body["playing"] as? Bool ?? false
        let currentTime = (body["currentTime"] as? NSNumber)?.doubleValue ?? 0
        let duration = (body["duration"] as? NSNumber)?.doubleValue ?? 0
        let streamURL: URL? = {
            guard let urlString = body["streamUrl"] as? String else { return nil }
            return URL(string: urlString)
        }()

        let artworkURL: URL? = {
            guard let urlString = body["artUrl"] as? String else { return nil }
            return URL(string: urlString)
        }()

        let title = body["title"] as? String
        let artist = body["artist"] as? String

        let track: TrackInfo? = {
            guard title != nil || artist != nil || artworkURL != nil else { return nil }
            return TrackInfo(
                id: nil,
                title: title,
                artist: artist,
                album: nil,
                albumId: nil,
                artistId: nil,
                duration: duration > 0 ? duration : nil,
                artworkURL: artworkURL
            )
        }()

        return PlayerState(
            currentTrack: track,
            isPlaying: isPlaying,
            currentTime: currentTime,
            duration: duration,
            isStalled: false,
            streamURL: streamURL
        )
    }

    /// Maps a `PlayerCommand` to a JavaScript snippet that clicks the corresponding
    /// site player-bar button. Returns `nil` for unsupported commands (e.g. `.seek`).
    private func clickScript(for command: PlayerCommand) -> String? {
        switch command {
        case .play:
            return "document.querySelector('button.player-btn .lucide-play')?.closest('button')?.click()"
        case .pause:
            return "document.querySelector('button.player-btn .lucide-pause')?.closest('button')?.click()"
        case .togglePlayPause:
            return """
            (document.querySelector('button.player-btn .lucide-play')  ||
             document.querySelector('button.player-btn .lucide-pause'))?.closest('button')?.click()
            """
        case .nextTrack:
            return "document.querySelector('button[class*=\"next\"],button[class*=\"skip-forward\"],button[class*=\"forward\"]')?.click()"
        case .previousTrack:
            return "document.querySelector('button[class*=\"prev\"],button[class*=\"skip-back\"],button[class*=\"back\"]')?.click()"
        case .seek:
            // WebKit audio seek via injected JS is unreliable; skip silently.
            return nil
        }
    }

    /// Removes every user script associated with the given content world from
    /// the provided user-content controller.
    private func removeAllScripts(
        from controller: WKUserContentController,
        in world: WKContentWorld
    ) {
        controller.removeAllUserScripts()
    }
}
