# Fizzy SDK

Official multi-language SDK for the [Fizzy](https://fizzy.do) API.

## Languages

### Go

```go
import "github.com/basecamp/fizzy-sdk/go/pkg/fizzy"

client := fizzy.NewClient(cfg, fizzy.NewStaticTokenProvider(token))
account := client.ForAccount("12345")

boards, err := account.Boards.List(ctx, nil)
```

### TypeScript

```typescript
import { createFizzyClient } from "@37signals/fizzy";

const client = createFizzyClient({ accessToken: "tok_..." });
const account = client.forAccount("12345");

const boards = await account.boards.list();
```

### Ruby

```ruby
require "fizzy"

client = Fizzy.client(access_token: "tok_...")
account = client.for_account("12345")

boards = account.boards.list
```

### Swift

```swift
import Fizzy

let client = FizzyClient(accessToken: "tok_...", userAgent: "MyApp/1.0")
let account = client.forAccount("12345")

let boards = try await account.boards.list()
```

### Kotlin

```kotlin
val client = FizzyClient {
    accessToken("tok_...")
}
val account = client.forAccount("12345")

val boards = account.boards.list()
```

### Rust

```rust
use fizzy_sdk::{Client, Config, StaticTokenProvider};

let client = Client::new(Config::default(), StaticTokenProvider::new("tok_..."))?;
let account = client.for_account("12345")?;

let boards = account.boards().list().await?;
```

`cargo add fizzy-sdk tokio --features tokio/macros,tokio/rt-multi-thread` — the client is async on Tokio, so the snippet runs inside a `#[tokio::main]` function; `rustls` TLS, MSRV 1.88. On
[crates.io](https://crates.io/crates/fizzy-sdk) and [docs.rs](https://docs.rs/fizzy-sdk);
the [crate README](rust/fizzy-sdk/README.md) covers auth, pagination, errors, hooks and the
develop loop.

## Features

| Feature | Go | TS | Ruby | Swift | Kotlin | Rust |
|---------|----|----|------|-------|--------|------|
| Bearer token auth | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Cookie session auth | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Magic link flow | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Retry + backoff | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Pagination | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| ETag caching | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Webhook verification | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Observability hooks | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Structured errors | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Circuit breaker | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

## License

MIT
