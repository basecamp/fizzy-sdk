//! Generates the Rust Fizzy SDK's types, services and route table.
//!
//! Reads `openapi.json` and `behavior-model.json` from the repository root and writes
//! `rust/fizzy-sdk/src/generated/`. With `--check` it writes nothing and exits non-zero when
//! the checked-in files differ from what it would generate.

use std::path::PathBuf;
use std::process::ExitCode;
use std::{env, fs};

use fizzy_sdk_generator::{Mode, Options, run};

fn main() -> ExitCode {
    match parse(env::args().skip(1)).and_then(run) {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("error: {error}");
            ExitCode::FAILURE
        }
    }
}

fn parse(mut arguments: impl Iterator<Item = String>) -> Result<Options, String> {
    let mut options = Options::new(default_root()?);
    while let Some(argument) = arguments.next() {
        match argument.as_str() {
            "--check" => options.mode = Mode::Check,
            "--root" => {
                options.root = PathBuf::from(arguments.next().ok_or("--root needs a path")?);
            }
            "--out" => {
                options.mode =
                    Mode::WriteTo(PathBuf::from(arguments.next().ok_or("--out needs a path")?));
            }
            other => return Err(format!("unknown argument {other}")),
        }
    }
    Ok(options)
}

fn default_root() -> Result<PathBuf, String> {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../..");
    fs::canonicalize(&root).map_err(|error| format!("{}: {error}", root.display()))
}
