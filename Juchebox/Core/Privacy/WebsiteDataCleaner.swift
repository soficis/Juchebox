import Foundation
import WebKit

@MainActor
enum WebsiteDataCleaner {
    static func clearPersistentWebsiteData() async {
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            dataStore.removeData(ofTypes: dataTypes, modifiedSince: .distantPast) {
                continuation.resume()
            }
        }
    }
}


