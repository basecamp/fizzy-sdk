//! Streams every board in an account, page after page, then the closed cards of the first
//! one.
//!
//! ```sh
//! FIZZY_TOKEN=tok_... FIZZY_ACCOUNT=999 cargo run --example list_boards
//! ```

use fizzy_sdk::{Client, Config, Error, StaticTokenProvider};
use futures_util::TryStreamExt;

#[tokio::main]
async fn main() -> Result<(), Error> {
    let token = std::env::var("FIZZY_TOKEN").unwrap_or_default();
    let client = Client::new(
        Config::default().with_env(),
        StaticTokenProvider::new(token),
    )?;
    let account = client.for_configured_account()?;

    let mut first_board = None;
    let mut boards = std::pin::pin!(client.items(account.boards().list().await?));
    while let Some(board) = boards.try_next().await? {
        println!("{} ({})", board.name, board.id);
        first_board.get_or_insert(board.id);
    }

    if let Some(board_id) = first_board {
        let closed = account.boards().list_closed(&board_id).await?;
        let mut cards = std::pin::pin!(client.items(closed));
        while let Some(card) = cards.try_next().await? {
            println!("  closed: {}", card.title);
        }
    }
    Ok(())
}
