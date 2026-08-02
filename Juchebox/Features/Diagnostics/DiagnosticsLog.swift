import Foundation
import UIKit

@MainActor
final class DiagnosticsLog: ObservableObject {
    @Published private(set) var entries: [DiagnosticsEntry] = []
    @Published private(set) var breadcrumbs: [NavigationBreadcrumb] = []

    private let maximumEntryCount = 50

    func record(error: WebContentError, url: URL?, sessionMode: PrivacySettings.SessionMode) {
        let entry = DiagnosticsEntry(
            timestamp: Date(),
            errorDomain: error.diagnosticDomain,
            errorCode: error.diagnosticCode,
            sanitizedHost: Self.sanitizedHost(from: url),
            sessionMode: sessionMode
        )

        entries.append(entry)

        if entries.count > maximumEntryCount {
            entries.removeFirst(entries.count - maximumEntryCount)
        }
    }

    func recordBreadcrumb(_ event: NavigationBreadcrumb.Event, url: URL?, sessionMode: PrivacySettings.SessionMode) {
        breadcrumbs.append(
            NavigationBreadcrumb(
                timestamp: Date(),
                event: event,
                sanitizedHost: SanitizedHost(from: url),
                sessionMode: sessionMode
            )
        )

        if breadcrumbs.count > maximumEntryCount {
            breadcrumbs.removeFirst(breadcrumbs.count - maximumEntryCount)
        }
    }

    func exportText(sessionMode: PrivacySettings.SessionMode) -> String {
        var lines: [String] = [
            "주체박스 (주체음악) 검열보고서 / Juchebox Inspection Report",
            "Generated/생성일: \(Self.timestampFormatter.string(from: Date()))",
            "App Version: \(Self.appVersion)",
            "iOS Version: \(UIDevice.current.systemVersion)",
            "Device Class: \(Self.deviceClass)",
            "Current Session: \(sessionMode.rawValue)",
            "",
            "Navigation Timeline / 페지 련결 기록:"
        ]

        if breadcrumbs.isEmpty {
            lines.append("- None recorded")
        } else {
            lines.append(contentsOf: breadcrumbs.map { $0.redactedDescription })
        }

        lines.append("")
        lines.append("Error Events / 오유 기록:")

        if entries.isEmpty {
            lines.append("- None recorded")
        } else {
            lines.append(contentsOf: entries.map { $0.redactedDescription })
        }

        return lines.joined(separator: "\n")
    }

    static func sanitizedHost(from url: URL?) -> String {
        guard let host = DomainPolicy.normalizedHost(url?.host) else {
            return "none"
        }

        return host
    }

    private static var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private static var deviceClass: String {
        UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
    }

    nonisolated(unsafe) private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

struct DiagnosticsEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let errorDomain: String
    let errorCode: Int
    let sanitizedHost: String
    let sessionMode: PrivacySettings.SessionMode

    var redactedDescription: String {
        let timestampText = ISO8601DateFormatter().string(from: timestamp)
        return "- \(timestampText) domain=\(errorDomain) code=\(errorCode) host=\(sanitizedHost) session=\(sessionMode.rawValue)"
    }
}

