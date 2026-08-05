import Foundation
import CryptoKit
import Security

/// Per-note password protection. Each locked note is encrypted at rest with AES-GCM using a key
/// derived from THAT note's own password + a random per-note salt — so every note can have a
/// different password, and nothing on disk reveals the content without it. Fully on-device.
enum NoteCrypto {
    /// Derive a 256-bit key from the password + salt. (SHA-256 over salt‖password — GCM's auth tag
    /// already makes a wrong password fail cleanly, so no separate verifier is stored.)
    private static func key(_ password: String, salt: Data) -> SymmetricKey {
        var material = salt
        material.append(Data(password.utf8))
        return SymmetricKey(data: SHA256.hash(data: material))
    }

    /// Returns nil when the system RNG fails. The old code discarded SecRandomCopyBytes' status and
    /// returned the zero-filled buffer, so an RNG failure silently produced an ALL-ZERO salt: every
    /// note locked in that state shares one key derivation, which is exactly the property the
    /// per-note salt exists to prevent. A lock that cannot be made safely must fail, not degrade.
    private static func randomSalt(_ n: Int = 16) -> Data? {
        var d = Data(count: n)
        let ok = d.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, n, $0.baseAddress!) }
        return ok == errSecSuccess ? d : nil
    }

    /// Encrypt plaintext → (base64 ciphertext, base64 salt). Returns nil only on a crypto failure.
    static func encrypt(_ plaintext: String, password: String) -> (cipher: String, salt: String)? {
        guard let salt = randomSalt() else { return nil }
        guard let sealed = try? AES.GCM.seal(Data(plaintext.utf8), using: key(password, salt: salt)),
              let combined = sealed.combined else { return nil }
        return (combined.base64EncodedString(), salt.base64EncodedString())
    }

    /// Decrypt → plaintext, or nil if the password is wrong (GCM tag mismatch) or data is corrupt.
    static func decrypt(_ cipher: String, password: String, salt: String) -> String? {
        guard let cData = Data(base64Encoded: cipher), let sData = Data(base64Encoded: salt),
              let box = try? AES.GCM.SealedBox(combined: cData),
              let pt = try? AES.GCM.open(box, using: key(password, salt: sData)) else { return nil }
        return String(data: pt, encoding: .utf8)
    }

    // The two text fields of a note are packed into one blob with a NUL separator before encrypting.
    static let sep = "\u{0000}"
    static func pack(original: String, formatted: String) -> String { original + sep + formatted }
    static func unpack(_ s: String) -> (original: String, formatted: String) {
        let parts = s.components(separatedBy: sep)
        return (parts.first ?? "", parts.count > 1 ? parts.dropFirst().joined(separator: sep) : "")
    }
}
