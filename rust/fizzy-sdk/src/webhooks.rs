//! Verifying what Fizzy posts to a webhook. Every delivery carries an `X-Webhook-Signature`
//! header: the hex HMAC-SHA256 of the raw body under the webhook's secret.
//!
//! ```
//! use fizzy_sdk::webhooks::{SIGNATURE_HEADER, compute_signature, verify_signature};
//!
//! let secret = "whsec_test";
//! let body = br#"{"event":"card.created"}"#;
//! let signature = compute_signature(body, secret);
//! assert!(verify_signature(body, &signature, secret));
//! assert!(!verify_signature(b"tampered", &signature, secret));
//! assert_eq!(SIGNATURE_HEADER, "X-Webhook-Signature");
//! ```

use sha2::{Digest, Sha256};

/// The header a delivery's signature arrives in.
pub const SIGNATURE_HEADER: &str = "X-Webhook-Signature";

const BLOCK_SIZE: usize = 64;

/// Whether `signature` is the HMAC-SHA256 of `payload` under `secret`, compared in constant
/// time. An empty secret or signature never verifies.
pub fn verify_signature(payload: &[u8], signature: &str, secret: &str) -> bool {
    if secret.is_empty() || signature.is_empty() {
        return false;
    }
    constant_time_eq(
        compute_signature(payload, secret).as_bytes(),
        signature.trim().as_bytes(),
    )
}

/// The hex HMAC-SHA256 of `payload` under `secret`, as Fizzy signs a delivery.
pub fn compute_signature(payload: &[u8], secret: &str) -> String {
    hex(&hmac_sha256(secret.as_bytes(), payload))
}

/// HMAC as RFC 2104 defines it over SHA-256: a key longer than the block is hashed first,
/// then padded; the inner hash goes over `ipad ‖ message`, the outer over
/// `opad ‖ inner`.
fn hmac_sha256(key: &[u8], message: &[u8]) -> [u8; 32] {
    let mut block = [0u8; BLOCK_SIZE];
    if key.len() > BLOCK_SIZE {
        block[..32].copy_from_slice(&Sha256::digest(key));
    } else {
        block[..key.len()].copy_from_slice(key);
    }
    let mut inner = Sha256::new();
    inner.update(block.map(|byte| byte ^ 0x36));
    inner.update(message);
    let inner = inner.finalize();
    let mut outer = Sha256::new();
    outer.update(block.map(|byte| byte ^ 0x5c));
    outer.update(inner);
    outer.finalize().into()
}

/// Whether two byte strings are equal, taking the same time whatever the answer: the
/// comparison walks every byte of both and folds the differences, so a mismatch in the
/// first byte costs no less than one in the last. Lengths are folded in the same way.
fn constant_time_eq(a: &[u8], b: &[u8]) -> bool {
    let mut difference = a.len() ^ b.len();
    for index in 0..a.len().max(b.len()) {
        let left = a.get(index).copied().unwrap_or(0);
        let right = b.get(index).copied().unwrap_or(0);
        difference |= usize::from(left ^ right);
    }
    difference == 0
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|byte| format!("{byte:02x}")).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    /// RFC 4231 test case 2: the key "Jefe" over "what do ya want for nothing?".
    #[test]
    fn hmac_matches_the_rfc_4231_vector() {
        assert_eq!(
            compute_signature(b"what do ya want for nothing?", "Jefe"),
            "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843"
        );
    }

    /// RFC 4231 test case 6: a key longer than the block size is hashed first.
    #[test]
    fn a_long_key_is_hashed_before_use() {
        let key = "\u{aa}".repeat(131).into_bytes();
        let key: Vec<u8> = key.iter().filter(|byte| **byte == 0xaa).copied().collect();
        assert_eq!(key.len(), 131);
        let message = b"Test Using Larger Than Block-Size Key - Hash Key First";
        assert_eq!(
            hex(&hmac_sha256(&key, message)),
            "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54"
        );
    }

    #[test]
    fn verification_needs_a_secret_and_a_signature_and_the_same_bytes() {
        let signature = compute_signature(b"payload", "secret");
        assert!(verify_signature(b"payload", &signature, "secret"));
        assert!(verify_signature(
            b"payload",
            &format!(" {signature}\n"),
            "secret"
        ));
        assert!(!verify_signature(b"payload", &signature, "other"));
        assert!(!verify_signature(b"other", &signature, "secret"));
        assert!(!verify_signature(b"payload", "", "secret"));
        assert!(!verify_signature(b"payload", &signature, ""));
        assert!(!verify_signature(b"payload", &signature[..10], "secret"));
    }

    #[test]
    fn constant_time_comparison_is_exact() {
        assert!(constant_time_eq(b"abc", b"abc"));
        assert!(!constant_time_eq(b"abc", b"abd"));
        assert!(!constant_time_eq(b"abc", b"ab"));
        assert!(!constant_time_eq(b"", b"a"));
        assert!(constant_time_eq(b"", b""));
    }
}
