import Foundation
import Crypto

/// Utilities for verifying Fizzy webhook signatures.
///
/// Fizzy signs webhook payloads with HMAC-SHA256. Use these methods to
/// verify that incoming webhooks are authentic.
///
/// ```swift
/// let isValid = WebhookVerifier.verify(
///     payload: requestBody,
///     signature: request.headers["X-Fizzy-Signature"]!,
///     secret: "your-webhook-secret"
/// )
/// ```
public enum WebhookVerifier {
    /// Verifies a webhook payload against its HMAC-SHA256 signature.
    ///
    /// - Parameters:
    ///   - payload: The raw webhook request body.
    ///   - signature: The signature from the `X-Fizzy-Signature` header.
    ///   - secret: The webhook signing secret.
    /// - Returns: `true` if the signature is valid.
    public static func verify(payload: Data, signature: String, secret: String) -> Bool {
        let computed = computeSignature(payload: payload, secret: secret)
        return constantTimeEqual(computed, signature)
    }

    /// Verifies a webhook payload string against its HMAC-SHA256 signature.
    ///
    /// - Parameters:
    ///   - payload: The raw webhook request body as a string.
    ///   - signature: The signature from the `X-Fizzy-Signature` header.
    ///   - secret: The webhook signing secret.
    /// - Returns: `true` if the signature is valid.
    public static func verify(payload: String, signature: String, secret: String) -> Bool {
        guard let data = payload.data(using: .utf8) else { return false }
        return verify(payload: data, signature: signature, secret: secret)
    }

    /// Computes the HMAC-SHA256 signature for a payload.
    ///
    /// - Parameters:
    ///   - payload: The raw payload data.
    ///   - secret: The signing secret.
    /// - Returns: The hex-encoded HMAC-SHA256 signature.
    public static func computeSignature(payload: Data, secret: String) -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: payload, using: key)
        return Data(mac).map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Private

    /// Constant-time string comparison to prevent timing attacks.
    private static func constantTimeEqual(_ a: String, _ b: String) -> Bool {
        let aBytes = Array(a.utf8)
        let bBytes = Array(b.utf8)

        guard aBytes.count == bBytes.count else { return false }

        var result: UInt8 = 0
        for i in 0..<aBytes.count {
            result |= aBytes[i] ^ bBytes[i]
        }
        return result == 0
    }
}
