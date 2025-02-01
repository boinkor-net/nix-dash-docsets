use std::collections::{BTreeMap, BTreeSet};
use std::fs::{create_dir_all, File};
use std::io::Write as _;
use std::path::{Path, PathBuf};
use std::process::Command;

use anyhow::Context as _;
use clap::Parser;
use tracing::level_filters::LevelFilter;
use tracing_subscriber::prelude::__tracing_subscriber_SubscriberExt as _;
use tracing_subscriber::util::SubscriberInitExt as _;
use tracing_subscriber::EnvFilter;

/// Partitions a nixos/nix-darwin style options.json into multiple files, according to SPLITS.
///
/// Each split gives the name of the super-key that should be split
/// into multiple output documents, meaning if you specify `services`,
/// then there will be one document per subkey of `services.<name>`:
/// e.g., `services.nginx`, `services.unbound`, and so on.
///
/// The remaining (non-split) keys will be collected in a single,
/// document named "other".
#[derive(Clone, PartialEq, Eq, Debug, Parser)]
struct Cmdline {
    /// path to the options.json file
    #[clap(long)]
    options_file: PathBuf,

    #[clap(long, short, default_value = "3")]
    merge_threshold: usize,

    /// Directory to write manuals in
    #[clap(long, short)]
    output_dir: PathBuf,

    /// Name of the book (title of all options pages)
    #[clap(long)]
    book_name: String,

    /// ID (without the leading "#") that is attached to the root element of options reference pages
    #[clap(long)]
    root_id: String,

    /// Key paths to split out into their own index pages.
    splits: Vec<String>,
}

fn main() -> anyhow::Result<()> {
    tracing_subscriber::registry()
        .with(tracing_subscriber::fmt::layer())
        .with(
            EnvFilter::builder()
                .with_default_directive(LevelFilter::INFO.into())
                .from_env_lossy(),
        )
        .init();

    let cmdline = Cmdline::parse();
    let input = File::open(&cmdline.options_file)
        .with_context(|| format!("Opening {:?}", cmdline.options_file))?;
    let all_options: BTreeMap<String, serde_json::Value> = serde_json::from_reader(input)
        .with_context(|| format!("Parsing {:?}", cmdline.options_file))?;

    tracing::info!(number_options = all_options.len(), "Parsed options");

    // Let's pick out the splits, ensuring we look at the longer
    // (i.e., more likely to contain subkeys) keys first:
    let mut picks = BTreeMap::new();
    let remaining: BTreeSet<String> = {
        let mut all_keys = all_options.keys().cloned().collect::<Vec<_>>();
        let mut splits = cmdline.splits;
        splits.sort_by_key(|split| usize::MAX - split.len()); // longest first
        for split in splits.iter() {
            let subset = all_keys.iter().map(|s| s.to_string()).collect::<Vec<_>>();
            all_keys = split_into_subkeys(subset, &mut picks, &split)
                .iter()
                .map(|s| s.to_string())
                .collect();
        }
        all_keys.clone().into_iter().collect()
    };
    merge_some_picks(&mut picks, cmdline.merge_threshold);
    // tracing::info!(picks=?picks.iter().map(|(k, v)| (k, v.len())).collect::<BTreeMap<_, _>>(), len_rest = remaining.len(), "Split out keys");

    // Now write each of these out:
    {
        let mut to_write = BTreeMap::new();
        for key in remaining {
            to_write.insert(
                key.to_string(),
                all_options.get(&key).expect("should have a key").clone(),
            );
        }
        generate_docs_for_subkeys(
            &cmdline.output_dir,
            "_other",
            to_write,
            &cmdline.book_name,
            &cmdline.root_id,
        )
        .context("all remaining options")?;
    }
    for (superkey, subkeys) in picks.into_iter() {
        let mut to_write = BTreeMap::new();
        for key in subkeys {
            to_write.insert(
                key.to_string(),
                all_options.get(&key).expect("should have a key").clone(),
            );
        }
        generate_docs_for_subkeys(
            &cmdline.output_dir,
            &superkey,
            to_write,
            &cmdline.book_name,
            &cmdline.root_id,
        )
        .context(superkey)?;
    }
    Ok(())
}

fn generate_docs_for_subkeys(
    output_dir: &Path,
    superkey: &str,
    to_write: BTreeMap<String, serde_json::Value>,
    book_name: &str,
    root_id: &str,
) -> anyhow::Result<()> {
    create_dir_all(output_dir).with_context(|| format!("Creating dir {:?}", output_dir))?;
    let json_path = output_dir.join(format!("{superkey}.json"));
    let json = File::create(&json_path)
        .with_context(|| format!("Creating output json {:?}", json_path))?;
    serde_json::to_writer_pretty(json, &to_write)
        .with_context(|| format!("Writing json to {:?}", json_path))?;

    let md_path = output_dir.join(format!("{superkey}.md"));
    let mut md =
        File::create(&md_path).with_context(|| format!("Creating output json {:?}", json_path))?;
    write!(
        md,
        "{}",
        markdown_template(book_name, "0.0.0", root_id, &json_path, superkey,)
    )
    .with_context(|| format!("Writing markdown to {:?}", &md_path))?;

    let exit_status = Command::new("nixos-render-docs")
        .arg(&md_path)
        .status()
        .with_context(|| format!("Executing the docs-rendering command for {:?}", &md_path))?;
    if !exit_status.success() {
        anyhow::bail!("Could not render docs for {:?}", &md_path);
    }
    Ok(())
}

fn split_into_subkeys<'a, 'b>(
    keys: impl IntoIterator<Item = String>,
    picks: &mut BTreeMap<String, BTreeSet<String>>,
    superkey: &'b str,
) -> Vec<String> {
    let mut remainder = vec![];
    for key in keys {
        // For `services`, will pick `services` and `services.nginx` but not `servicesIssues`.
        if key == superkey {
            picks.entry(key.to_string()).or_default().insert(key);
        } else if key.starts_with(superkey) && key.chars().nth(superkey.len()) == Some('.') {
            let next_dot = key
                .chars()
                .enumerate()
                .skip(superkey.len() + 1)
                .find(|(_, c)| *c == '.');
            if let Some((i, _)) = next_dot {
                picks.entry(key[0..i].to_string()).or_default().insert(key);
            } else if next_dot.is_none() {
                picks.entry(key.to_string()).or_default().insert(key);
            }
        } else {
            remainder.push(key);
        }
    }
    remainder
}

fn merge_some_picks<'a>(picks: &mut BTreeMap<String, BTreeSet<String>>, merge_threshold: usize) {
    let mut merged_superkeys = BTreeSet::new();
    loop {
        merged_superkeys.clear();
        for (key, value) in picks.clone() {
            if value.len() >= merge_threshold {
                // We have enough elements to be satisfying, skip:
                continue;
            }
            let Some((superkey, _sub)) = key.rsplit_once(".") else {
                // This has no superkey to merge into, skip:
                continue;
            };
            merged_superkeys.insert(superkey.to_string());
        }
        tracing::debug!(?merged_superkeys, picks=?picks.iter().map(|(k, v)| (k, v.len())).collect::<BTreeMap<_, _>>(), "to merge");

        for superkey in merged_superkeys.iter() {
            let mut collected: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
            for (key, value) in picks.iter_mut() {
                if key.starts_with(superkey) && value.len() < merge_threshold {
                    tracing::debug!(?key, ?superkey, "merging");
                    collected
                        .entry(superkey.to_string())
                        .or_default()
                        .append(value);
                }
            }
            for (superkey, value) in collected.iter_mut() {
                picks.entry(superkey.to_string()).or_default().append(value);
            }
            picks.retain(|_, v| v.len() > 0);
        }

        if merged_superkeys.is_empty() {
            return;
        }
    }
}

fn markdown_template(
    name: &str,
    version: &str,
    book_id: &str,
    json_path: &Path,
    subkey: &str,
) -> String {
    let json_file = json_path
        .file_name()
        .map(|s| s.to_string_lossy())
        .expect("pathname should render");
    format!(
        r#"
# {name} Configuration Options - `{subkey}` {{#{book_id}}}
## Version {version}

```{{=include=}} options
id-prefix: opt-
list-id: configuration-variable-list
source: {json_file}
```
"#
    )
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn splitting_subkeys() {
        let keys = [
            "programs.bash",
            "programs.bash.enable",
            "programs.bash.completion.enable",
            "programs.bash.shellInit",
            "users.notpicked",
        ];
        let mut picks = BTreeMap::new();
        let rest = split_into_subkeys(
            keys.into_iter().map(|s| s.to_string()),
            &mut picks,
            "programs",
        );
        assert_eq!(vec!["users.notpicked"], rest);
        assert_eq!(
            vec!["programs.bash"],
            picks.keys().cloned().collect::<Vec<String>>()
        );
        assert_eq!(4, picks["programs.bash"].len());
    }
}
