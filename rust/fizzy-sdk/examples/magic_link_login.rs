//! Signs in with a magic link: asks Fizzy to email a code, reads it from stdin, redeems it
//! for a session, and proves the session works by fetching the identity behind it.
//!
//! ```sh
//! cargo run --example magic_link_login -- you@example.com
//! ```

use std::io::{self, BufRead, Write};

use fizzy_sdk::{Client, Config, Error, MagicLinkFlow};

#[tokio::main]
async fn main() -> Result<(), Error> {
    let email = std::env::args()
        .nth(1)
        .ok_or_else(|| Error::usage("usage: magic_link_login <email>"))?;
    let config = Config::default().with_env();

    let flow = MagicLinkFlow::new(config.clone())?;
    flow.create_session(&email).await?;

    print!("Code from the email: ");
    io::stdout().flush().map_err(Error::from_std)?;
    let mut code = String::new();
    io::stdin()
        .lock()
        .read_line(&mut code)
        .map_err(Error::from_std)?;

    let session = flow.redeem(code.trim()).await?;
    let client = Client::builder(config)
        .session_token(session.session_token.clone())
        .build()?;
    let identity = client.identity().get_my_identity().await?;
    println!(
        "Signed in; {} account(s) available",
        identity.accounts.len()
    );
    Ok(())
}
