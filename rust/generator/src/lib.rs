//! The generator behind `rust/fizzy-sdk/src/generated`: a model read from `openapi.json`
//! and `behavior-model.json`, named by `names.toml`, and rendered into Rust.

#![allow(clippy::missing_errors_doc)]

pub mod emit;
pub mod model;
pub mod naming;

use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::{env, fs};

use model::{Model, ResourceTypes};
use naming::Naming;

/// Where the generator's output goes.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Mode {
    /// Replace `rust/fizzy-sdk/src/generated` under the root.
    Write,
    /// Write to a directory of the caller's choosing, leaving the checked-in code alone.
    WriteTo(PathBuf),
    /// Write nothing; fail when the checked-in code differs from what would be generated.
    Check,
}

/// What a run needs to know.
#[derive(Debug, Clone)]
pub struct Options {
    /// The repository root: where `openapi.json`, `behavior-model.json` and
    /// `rust/generator/names.toml` are read from.
    pub root: PathBuf,
    /// Where the output goes.
    pub mode: Mode,
}

impl Options {
    /// Options that regenerate the checked-in code under `root`.
    pub fn new(root: PathBuf) -> Options {
        Options {
            root,
            mode: Mode::Write,
        }
    }
}

/// Reads the inputs, builds the model and writes or verifies the generated code.
pub fn run(options: Options) -> Result<(), String> {
    let files = render_from(&options.root)?;
    let checked_in = options.root.join("rust/fizzy-sdk/src/generated");
    match options.mode {
        Mode::Write => write(&checked_in, &files),
        Mode::WriteTo(target) => write(&target, &files),
        Mode::Check => verify(&checked_in, &files),
    }
}

/// Every generated file, keyed by its path under the generated directory, unformatted.
pub fn render_from(root: &Path) -> Result<BTreeMap<PathBuf, String>, String> {
    let openapi = read_json(&root.join("openapi.json"))?;
    let behavior = read_json(&root.join("behavior-model.json"))?;
    let names = read(&root.join("rust/generator/names.toml"))?;
    let naming = Naming::parse(&names)?;
    let resource_types = ResourceTypes::parse(&names)?;
    let model = Model::build(&openapi, &behavior, &naming, &resource_types)?;
    Ok(render(&model))
}

/// Renders a model into its files, unformatted.
pub fn render(model: &Model) -> BTreeMap<PathBuf, String> {
    let mut files = BTreeMap::new();
    files.insert(PathBuf::from("mod.rs"), emit::render_mod(model));
    files.insert(PathBuf::from("types.rs"), emit::types::render(model));
    files.insert(PathBuf::from("routes.rs"), emit::routes::render(model));
    files.insert(
        PathBuf::from("redaction.rs"),
        emit::redaction::render(model),
    );
    files.insert(
        PathBuf::from("accessors.rs"),
        emit::accessors::render(model),
    );
    files.insert(
        PathBuf::from("services/mod.rs"),
        emit::services::render_mod(model),
    );
    for service in &model.services {
        files.insert(
            PathBuf::from(format!("services/{}.rs", service.name)),
            emit::services::render_service(service),
        );
    }
    files
}

fn write(target: &Path, files: &BTreeMap<PathBuf, String>) -> Result<(), String> {
    if target.exists() {
        fs::remove_dir_all(target).map_err(|error| format!("{}: {error}", target.display()))?;
    }
    let paths = write_all(target, files)?;
    format(&paths)?;
    println!("Generated {} files in {}", paths.len(), target.display());
    Ok(())
}

fn verify(target: &Path, files: &BTreeMap<PathBuf, String>) -> Result<(), String> {
    let scratch = env::temp_dir().join(format!("fizzy-sdk-generator-{}", std::process::id()));
    let paths = write_all(&scratch, files)?;
    let formatted = format(&paths);
    let mut stale = Vec::new();
    for relative in files.keys() {
        let expected = fs::read_to_string(scratch.join(relative)).unwrap_or_default();
        let actual = fs::read_to_string(target.join(relative)).unwrap_or_default();
        if expected != actual {
            stale.push(relative.display().to_string());
        }
    }
    for existing in list_files(target, target) {
        if !files.contains_key(&existing) {
            stale.push(format!("{} (unexpected)", existing.display()));
        }
    }
    let _ = fs::remove_dir_all(&scratch);
    formatted?;
    if stale.is_empty() {
        println!("{} is up to date", target.display());
        Ok(())
    } else {
        Err(format!(
            "{} is out of date. Run `make rs-generate`. Stale files:\n  {}",
            target.display(),
            stale.join("\n  ")
        ))
    }
}

/// Writes every file under `target` and answers the paths written.
pub fn write_all(target: &Path, files: &BTreeMap<PathBuf, String>) -> Result<Vec<PathBuf>, String> {
    let mut paths = Vec::new();
    for (relative, content) in files {
        let path = target.join(relative);
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).map_err(|error| format!("{}: {error}", parent.display()))?;
        }
        fs::write(&path, content).map_err(|error| format!("{}: {error}", path.display()))?;
        paths.push(path);
    }
    Ok(paths)
}

/// Runs `rustfmt` over the files, with the workspace's own `rustfmt.toml` and toolchain: the
/// checked-in code has to match what `cargo fmt` would leave, or the drift check would
/// disagree with the format check.
pub fn format(paths: &[PathBuf]) -> Result<(), String> {
    let workspace = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("..");
    let status = Command::new("rustfmt")
        .current_dir(&workspace)
        .arg("--edition")
        .arg("2024")
        .arg("--config-path")
        .arg(workspace.join("rustfmt.toml"))
        .args(paths)
        .status()
        .map_err(|error| format!("rustfmt: {error}"))?;
    if status.success() {
        Ok(())
    } else {
        Err("rustfmt failed".into())
    }
}

fn list_files(root: &Path, directory: &Path) -> Vec<PathBuf> {
    let mut files = Vec::new();
    if let Ok(entries) = fs::read_dir(directory) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                files.extend(list_files(root, &path));
            } else if let Ok(relative) = path.strip_prefix(root) {
                files.push(relative.to_path_buf());
            }
        }
    }
    files
}

fn read(path: &Path) -> Result<String, String> {
    fs::read_to_string(path).map_err(|error| format!("{}: {error}", path.display()))
}

fn read_json(path: &Path) -> Result<serde_json::Value, String> {
    serde_json::from_str(&read(path)?).map_err(|error| format!("{}: {error}", path.display()))
}
