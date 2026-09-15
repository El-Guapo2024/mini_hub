//! Offline check of the speaking note type: add two cards to a brand-new
//! local collection through the C functions, as Dart does. The first makes
//! the note type, the second reuses it. No AnkiWeb, no account.
//!
//!   cargo run -p mini_hub_bridge --example notetype

use std::ffi::CStr;
use std::ffi::CString;

use mini_hub_bridge::anki_bridge_call;
use mini_hub_bridge::anki_bridge_free;
use serde_json::json;

fn call(method: &str, args: &serde_json::Value) -> String {
    let m = CString::new(method).unwrap();
    let a = CString::new(args.to_string()).unwrap();
    unsafe {
        let out = anki_bridge_call(m.as_ptr(), a.as_ptr());
        let text = CStr::from_ptr(out).to_string_lossy().into_owned();
        anki_bridge_free(out);
        text
    }
}

fn main() {
    let dir = std::env::temp_dir().join("mini_hub_bridge_notetype");
    let _ = std::fs::remove_dir_all(&dir);
    let add = |word: &str| {
        json!({
            "dir": dir.to_string_lossy(),
            "deck": "Chinese::Reader",
            "notetype": "mini_hub Chinese",
            "create_notetype": {
                "fields": ["Word", "Pinyin", "Meaning", "Sentence"],
                "front": "<div>{{Word}}</div>\n{{tts zh_CN:Word}}",
                "back": "{{FrontSide}}<hr id=answer>{{Pinyin}}<br>{{Meaning}}<br>{{Sentence}}\n{{tts zh_CN:Sentence}}",
            },
            "fields": [word, "le", "done", "他来了"],
            "tags": ["mini_hub"],
        })
    };
    println!("add 1 -> {}", call("add", &add("了")));
    println!("add 2 -> {}", call("add", &add("走")));
    println!("decks -> {}", call("decks", &json!({ "dir": dir.to_string_lossy() })));

    // What Anki would render for the first card's question side.
    let db = dir.join("collection.anki2");
    let out = std::process::Command::new("sqlite3")
        .arg("-readonly")
        .arg(&db)
        .arg("select name from notetypes where name like 'mini_hub%'; select count(*) from notes; select count(*) from cards;")
        .output()
        .unwrap();
    println!("db ->\n{}", String::from_utf8_lossy(&out.stdout));
}
