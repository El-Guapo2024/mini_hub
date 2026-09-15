//! Calls the bridge through its C functions, the way Dart will, using the
//! sync key the poc login saved. Read-only against AnkiWeb: sync and
//! download into a scratch folder, no adds.
//!
//!   cargo run -p mini_hub_bridge --example smoke

use std::ffi::CStr;
use std::ffi::CString;

use mini_hub_bridge::anki_bridge_call;
use mini_hub_bridge::anki_bridge_free;

fn call(method: &str, args: serde_json::Value) -> String {
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
    let hkey = std::fs::read_to_string("poc_data/hkey").expect("run the poc login first");
    let endpoint = std::fs::read_to_string("poc_data/endpoint").unwrap_or_default();
    let dir = std::env::temp_dir().join("mini_hub_bridge_smoke");
    let _ = std::fs::remove_dir_all(&dir);
    let args = serde_json::json!({
        "dir": dir.to_string_lossy(),
        "hkey": hkey.trim(),
        "endpoint": endpoint.trim(),
    });
    println!("sync     -> {}", call("sync", args.clone()));
    println!("download -> {}", call("download", args.clone()));
    println!("sync     -> {}", call("sync", args.clone()));
    println!("bad      -> {}", call("nope", args));
}
