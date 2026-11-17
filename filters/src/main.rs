use adblock::lists::{FilterSet, ParseOptions};
use serde_json::Value;
use std::{env, fs, path::Path};

const RULES_PER_FILE: usize = 40_000;

fn convert(list_text: String) -> Vec<String> {
    let mut filters = FilterSet::new(true);
    filters.add_filter_list(list_text, ParseOptions::default());
    let (rules, _) = filters
        .into_content_blocking()
        .expect("filter set keeps the raw rules");
    let (exceptions, blocking): (Vec<Value>, Vec<Value>) = rules
        .iter()
        .map(|rule| serde_json::to_value(rule).expect("rules serialize to JSON"))
        .partition(|rule| rule["action"]["type"] == "ignore-previous-rules");
    blocking
        .chunks(RULES_PER_FILE)
        .map(|chunk| Value::from([chunk, exceptions.as_slice()].concat()).to_string())
        .collect()
}

fn main() {
    let mut args = env::args().skip(1);
    let out_dir = args.next().expect("usage: nada-filters <out-dir> <list>...");
    fs::create_dir_all(&out_dir).expect("output directory is writable");
    for list in args {
        let name = Path::new(&list)
            .file_stem()
            .and_then(|stem| stem.to_str())
            .expect("list path has a file name")
            .to_owned();
        let text = fs::read_to_string(&list).expect("list file is readable");
        for (index, json) in convert(text).into_iter().enumerate() {
            fs::write(Path::new(&out_dir).join(format!("{name}-{index}.json")), json)
                .expect("rule file is writable");
        }
    }
}

#[cfg(test)]
mod tests {
    use super::convert;

    #[test]
    fn requests_to_an_ad_server_are_blocked_so_ads_never_download() {
        let files = convert("||ads.example.com^".to_owned());
        assert_eq!(files.len(), 1);
        assert!(files[0].contains(r#""type":"block""#));
        assert!(files[0].contains("ads"));
    }

    #[test]
    fn leftover_ad_boxes_are_hidden_so_pages_do_not_show_empty_slots() {
        let files = convert("example.com##.ad-banner".to_owned());
        assert!(files[0].contains(r#""type":"css-display-none""#));
        assert!(files[0].contains(".ad-banner"));
    }

    #[test]
    fn exceptions_reach_every_file_because_webkit_applies_each_file_on_its_own() {
        let mut list: String = (0..super::RULES_PER_FILE + 1)
            .map(|index| format!("||ads{index}.example.com^\n"))
            .collect();
        list.push_str("@@||ads0.example.com^$domain=allowed.example\n");
        let files = convert(list);
        assert_eq!(files.len(), 2);
        assert!(files.iter().all(|file| file.contains("ignore-previous-rules")));
    }

    #[test]
    fn large_lists_are_split_because_webkit_rejects_oversized_rule_files() {
        let list: String = (0..super::RULES_PER_FILE + 1)
            .map(|index| format!("||ads{index}.example.com^\n"))
            .collect();
        assert_eq!(convert(list).len(), 2);
    }
}
