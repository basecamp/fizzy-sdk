//! The conformance runner for the Rust Fizzy SDK.
//!
//! It reads the shared case definitions from `conformance/tests/` and drives each one
//! through the SDK's raw verbs against a loopback mock server, the way the Go, TypeScript
//! and Ruby runners do. Operation ids are checked against the generated route table, so a
//! fixture naming an operation the SDK does not know fails rather than being skipped.

mod assertions;
mod fixtures;
mod operations;
mod server;

use std::io;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

use assertions::Run;
use fixtures::TestCase;
use server::MockServer;

#[tokio::main]
async fn main() -> ExitCode {
    let directory = std::env::args().nth(1).map_or_else(
        || Path::new(env!("CARGO_MANIFEST_DIR")).join("../../tests"),
        PathBuf::from,
    );
    let files = match case_files(&directory) {
        Ok(files) => files,
        Err(error) => {
            eprintln!(
                "Error finding test files in {}: {error}",
                directory.display()
            );
            return ExitCode::FAILURE;
        }
    };
    if files.is_empty() {
        eprintln!("No test files found in {}", directory.display());
        return ExitCode::FAILURE;
    }

    let mut passed = 0;
    let mut failed = 0;
    for file in &files {
        // A file the runner cannot read or parse is a failure, not a file with no cases in
        // it: skipping it quietly would let a broken fixture pass the gate.
        let cases = match load_cases(file) {
            Ok(cases) => cases,
            Err(error) => {
                failed += 1;
                println!("\n=== {} ===\n  FAIL  {error}", file.display());
                continue;
            }
        };
        println!(
            "\n=== {} ({} tests) ===",
            file.file_name().unwrap_or_default().display(),
            cases.len()
        );
        for case in &cases {
            match run_case(case).await {
                Ok(()) => {
                    passed += 1;
                    println!("  PASS  {}", case.name);
                }
                Err(message) => {
                    failed += 1;
                    println!("  FAIL  {}\n        {message}", case.name);
                }
            }
        }
    }

    println!(
        "\nPassed: {passed}, Failed: {failed}, Total: {}",
        passed + failed
    );
    if failed > 0 {
        ExitCode::FAILURE
    } else {
        ExitCode::SUCCESS
    }
}

fn case_files(directory: &Path) -> Result<Vec<PathBuf>, io::Error> {
    let mut files: Vec<PathBuf> = std::fs::read_dir(directory)?
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .filter(|path| {
            path.extension()
                .is_some_and(|extension| extension == "json")
        })
        .collect();
    files.sort();
    Ok(files)
}

fn load_cases(file: &Path) -> Result<Vec<TestCase>, String> {
    let contents = std::fs::read(file).map_err(|error| error.to_string())?;
    serde_json::from_slice(&contents).map_err(|error| error.to_string())
}

async fn run_case(case: &TestCase) -> Result<(), String> {
    operations::validate(case)?;
    if case.expects_client_construction_failure() {
        let outcome = operations::construct_client(case);
        return assertions::check_all(&Run {
            case,
            outcome: &outcome,
            recorded: &[],
            base_url: case.link_origin(),
        });
    }
    let server = MockServer::start(&case.mock_responses, case.link_origin())
        .await
        .map_err(|error| format!("Failed to start the mock server: {error}"))?;
    let base_url = server.base_url().to_string();
    let outcome = operations::execute(case, &base_url).await;
    let recorded = server.shutdown();
    assertions::check_all(&Run {
        case,
        outcome: &outcome,
        recorded: &recorded,
        base_url: &base_url,
    })
}
