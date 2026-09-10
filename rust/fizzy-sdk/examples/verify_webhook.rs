//! Verifies a webhook delivery's signature the way a receiving endpoint should, in constant
//! time, before trusting the payload.
//!
//! ```sh
//! WEBHOOK_SECRET=whsec_... cargo run --example verify_webhook -- '<signature>' < payload.json
//! ```

use std::io::{self, Read};

use fizzy_sdk::webhooks::{SIGNATURE_HEADER, verify_signature};

fn main() {
    let signature = std::env::args().nth(1).unwrap_or_default();
    let secret = std::env::var("WEBHOOK_SECRET").unwrap_or_default();
    let mut payload = Vec::new();
    if io::stdin().read_to_end(&mut payload).is_err() {
        eprintln!("could not read the payload from stdin");
        std::process::exit(2);
    }

    if verify_signature(&payload, &signature, &secret) {
        println!("{SIGNATURE_HEADER} verified");
    } else {
        eprintln!("{SIGNATURE_HEADER} does not match");
        std::process::exit(1);
    }
}
