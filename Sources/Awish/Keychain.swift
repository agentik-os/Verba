import Foundation
import Security

/// Tiny Keychain wrapper for BYOK API keys. Keys never touch UserDefaults or disk in plaintext.
enum Keychain {
    private static let service = "com.agentik.awish"

    static func set(_ value: String, for account: String) {
        let data = Data(value.utf8)
        // Delete any existing item first, then add fresh.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        guard !value.isEmpty else { return }
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    static func get(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    // Convenience accounts
    static var openAIKey: String? { get { get("openai_api_key") } set { set(newValue ?? "", for: "openai_api_key") } }
    static var anthropicKey: String? { get { get("anthropic_api_key") } set { set(newValue ?? "", for: "anthropic_api_key") } }
}
