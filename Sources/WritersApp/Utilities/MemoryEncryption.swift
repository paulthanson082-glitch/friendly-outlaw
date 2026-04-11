import Foundation
import CommonCrypto

/// Memory encryption utilities for protecting sensitive stored data
public enum MemoryEncryption {
    private static let algorithm = CCAlgorithm(kCCAlgorithmAES128)
    private static let options = CCOptions(kCCOptionPKCS7Padding)
    private static let keyLength = kCCKeySizeAES256

    /// Encrypts a string using AES-256
    /// - Parameters:
    ///   - plaintext: The text to encrypt
    ///   - key: Encryption key (should be 32 bytes for AES-256)
    /// - Returns: Base64-encoded encrypted data
    /// - Throws: Encryption errors
    public static func encryptMemory(_ plaintext: String, key: String) throws -> String {
        let plaintextData = plaintext.data(using: .utf8) ?? Data()
        let keyData = deriveKey(from: key, length: keyLength)

        // Use a random IV
        var iv = [UInt8](repeating: 0, count: kCCBlockSizeAES128)
        guard SecRandomCopyBytes(kSecRandomDefault, iv.count, &iv) == errSecSuccess else {
            throw NSError(domain: "MemoryEncryption", code: -1, userInfo: ["error": "Failed to generate IV"])
        }

        var encryptedBytes = [UInt8](repeating: 0, count: plaintextData.count + kCCBlockSizeAES128)
        var encryptedLength = 0

        let status = CCCrypt(
            CCOperation(kCCEncrypt),
            CCAlgorithm(kCCAlgorithmAES128),
            CCOptions(kCCOptionPKCS7Padding),
            (keyData as NSData).bytes,
            keyLength,
            iv,
            (plaintextData as NSData).bytes,
            plaintextData.count,
            &encryptedBytes,
            encryptedBytes.count,
            &encryptedLength
        )

        guard status == kCCSuccess else {
            throw NSError(domain: "MemoryEncryption", code: Int(status), userInfo: ["error": "Encryption failed"])
        }

        // Prepend IV to encrypted data for decryption
        var result = iv
        result.append(contentsOf: encryptedBytes.prefix(encryptedLength))

        return Data(result).base64EncodedString()
    }

    /// Decrypts a string encrypted with encryptMemory
    /// - Parameters:
    ///   - ciphertext: Base64-encoded encrypted data (with IV prepended)
    ///   - key: Encryption key used during encryption
    /// - Returns: Decrypted plaintext
    /// - Throws: Decryption errors
    public static func decryptMemory(_ ciphertext: String, key: String) throws -> String {
        guard let encryptedData = Data(base64Encoded: ciphertext) else {
            throw NSError(domain: "MemoryEncryption", code: -1, userInfo: ["error": "Invalid base64 input"])
        }

        guard encryptedData.count > kCCBlockSizeAES128 else {
            throw NSError(domain: "MemoryEncryption", code: -1, userInfo: ["error": "Encrypted data too short"])
        }

        let keyData = deriveKey(from: key, length: keyLength)

        // Extract IV (first block size bytes)
        let iv = [UInt8](encryptedData.prefix(kCCBlockSizeAES128))
        let ciphertextBytes = [UInt8](encryptedData.dropFirst(kCCBlockSizeAES128))

        var decryptedBytes = [UInt8](repeating: 0, count: ciphertextBytes.count)
        var decryptedLength = 0

        let status = CCCrypt(
            CCOperation(kCCDecrypt),
            CCAlgorithm(kCCAlgorithmAES128),
            CCOptions(kCCOptionPKCS7Padding),
            (keyData as NSData).bytes,
            keyLength,
            iv,
            ciphertextBytes,
            ciphertextBytes.count,
            &decryptedBytes,
            decryptedBytes.count,
            &decryptedLength
        )

        guard status == kCCSuccess else {
            throw NSError(domain: "MemoryEncryption", code: Int(status), userInfo: ["error": "Decryption failed"])
        }

        let plaintext = String(data: Data(decryptedBytes.prefix(decryptedLength)), encoding: .utf8)
        guard let result = plaintext else {
            throw NSError(domain: "MemoryEncryption", code: -1, userInfo: ["error": "Invalid UTF-8 data"])
        }

        return result
    }

    /// Derives a fixed-length key from a variable-length string using SHA-256
    private static func deriveKey(from keyString: String, length: Int) -> Data {
        let keyData = keyString.data(using: .utf8) ?? Data()
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        _ = keyData.withUnsafeBytes { buffer in
            CC_SHA256(buffer.baseAddress, CC_LONG(keyData.count), &digest)
        }

        // Truncate or pad to desired length
        if digest.count >= length {
            return Data(digest.prefix(length))
        } else {
            var result = digest
            result.append(contentsOf: [UInt8](repeating: 0, count: length - digest.count))
            return Data(result)
        }
    }
}
