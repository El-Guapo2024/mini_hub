//! What mini_hub needs from Anki, as two C functions Dart calls over FFI:
//! log in, keep a copy of the user's collection in step with AnkiWeb, and
//! add or remove notes in it. Everything else (review, scheduling) stays
//! Anki's job in Anki's own apps.
//!
//! `anki_bridge_call(method, json_args)` returns `{"ok": ...}` or
//! `{"error": "..."}` as a JSON string the caller frees with
//! `anki_bridge_free`. Calls block (network, SQLite), so Dart makes them off
//! the UI isolate.
//!
//! Methods (dir = folder holding the phone's collection copy):
//!   login    {user, pass}                     -> {hkey}
//!   sync     {dir, hkey, endpoint?}           -> {status, endpoint?}
//!              status: ok | full_download_required | full_upload_required
//!   download {dir, hkey, endpoint?}           -> {notes}
//!   add      {dir, deck, fields, tags?, notetype?, create_notetype?} -> {id}
//!              create_notetype {fields, front, back}: made if notetype is missing
//!   remove   {dir, ids}                       -> {removed}
//!   decks    {dir}                            -> {decks: [name]}  (sorted, "A::B")
//!
//! Never uploads over the cloud copy: a full upload would wipe reviews made
//! on the user's other devices, so `full_upload_required` is reported, not
//! acted on.

use std::ffi::c_char;
use std::ffi::CStr;
use std::ffi::CString;
use std::panic::catch_unwind;
use std::panic::AssertUnwindSafe;
use std::path::Path;

use anki::collection::CollectionBuilder;
use anki::notetype::CardTemplate;
use anki::notetype::NoteField;
use anki::prelude::*;
use anki::sync::collection::normal::SyncActionRequired;
use anki::sync::login::sync_login;
use anki::sync::login::SyncAuth;
use serde_json::json;
use serde_json::Value;

type Out = std::result::Result<Value, String>;

fn err(e: impl std::fmt::Debug) -> String {
    format!("{e:?}")
}

/// HTTP/1 only, as Anki's backend builds it: over HTTP/2 AnkiWeb's
/// anki-original-size header didn't arrive and downloads failed.
fn client() -> reqwest::Client {
    reqwest::Client::builder().http1_only().build().unwrap()
}

fn block_on<F: std::future::Future>(f: F) -> F::Output {
    tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .unwrap()
        .block_on(f)
}

fn text(args: &Value, key: &str) -> std::result::Result<String, String> {
    args.get(key)
        .and_then(Value::as_str)
        .map(String::from)
        .ok_or_else(|| format!("missing {key}"))
}

fn open(args: &Value) -> std::result::Result<Collection, String> {
    let dir = text(args, "dir")?;
    std::fs::create_dir_all(&dir).map_err(err)?;
    CollectionBuilder::new(Path::new(&dir).join("collection.anki2"))
        .build()
        .map_err(err)
}

/// Closed after every call so the file on disk is always complete — the
/// app can be killed at any moment.
fn close(col: Collection) -> std::result::Result<(), String> {
    col.close(None).map_err(err)
}

fn auth(args: &Value) -> std::result::Result<SyncAuth, String> {
    let endpoint = match args.get("endpoint").and_then(Value::as_str) {
        Some(e) if !e.is_empty() => Some(e.parse::<reqwest::Url>().map_err(err)?),
        _ => None,
    };
    Ok(SyncAuth {
        hkey: text(args, "hkey")?,
        endpoint,
        io_timeout_secs: None,
    })
}

fn dispatch(method: &str, args: &Value) -> Out {
    match method {
        "login" => {
            let auth = block_on(sync_login(
                text(args, "user")?,
                text(args, "pass")?,
                None,
                client(),
            ))
            .map_err(err)?;
            // Only the key goes back; the password is dropped here.
            Ok(json!({ "hkey": auth.hkey }))
        }
        "sync" => {
            let mut col = open(args)?;
            let out = block_on(col.normal_sync(auth(args)?, client()));
            close(col)?;
            let out = out.map_err(err)?;
            let status = match out.required {
                // A completed normal sync reports NoChanges once both sides
                // match, so both of these mean "in step".
                SyncActionRequired::NoChanges | SyncActionRequired::NormalSyncRequired => "ok",
                SyncActionRequired::FullSyncRequired { download_ok, .. } => {
                    if download_ok {
                        "full_download_required"
                    } else {
                        "full_upload_required"
                    }
                }
            };
            Ok(json!({ "status": status, "endpoint": out.new_endpoint }))
        }
        "download" => {
            let col = open(args)?;
            block_on(col.full_download(auth(args)?, client())).map_err(err)?;
            let mut col = open(args)?;
            let notes = col.search_notes_unordered("").map_err(err)?.len();
            close(col)?;
            Ok(json!({ "notes": notes }))
        }
        "add" => {
            let mut col = open(args)?;
            let result = add(&mut col, args);
            close(col)?;
            result
        }
        "decks" => {
            let mut col = open(args)?;
            let names = col.get_all_normal_deck_names(false).map_err(err);
            close(col)?;
            let mut names: Vec<String> = names?
                .into_iter()
                // Stored with a unit separator between levels; people write ::
                .map(|(_, name)| name.replace('\x1f', "::"))
                .collect();
            names.sort();
            Ok(json!({ "decks": names }))
        }
        "remove" => {
            let ids: Vec<NoteId> = args
                .get("ids")
                .and_then(Value::as_array)
                .ok_or("missing ids")?
                .iter()
                .filter_map(Value::as_i64)
                .map(NoteId)
                .collect();
            let mut col = open(args)?;
            let result = col.remove_notes(&ids).map_err(err);
            close(col)?;
            Ok(json!({ "removed": result?.output }))
        }
        other => Err(format!("unknown method {other}")),
    }
}

fn add(col: &mut Collection, args: &Value) -> Out {
    let notetype_name = args
        .get("notetype")
        .and_then(Value::as_str)
        .unwrap_or("Basic");
    let notetype = match col.get_notetype_by_name(notetype_name).map_err(err)? {
        Some(nt) => nt,
        // The app's own note type, made in the user's collection the first
        // time a card needs it. Adding a note type syncs normally; only
        // changing an existing one's fields or templates forces a full sync.
        None => {
            let spec = args
                .get("create_notetype")
                .ok_or_else(|| format!("no note type {notetype_name}"))?;
            let mut nt = Notetype {
                name: notetype_name.to_string(),
                ..Default::default()
            };
            for field in spec
                .get("fields")
                .and_then(Value::as_array)
                .ok_or("create_notetype needs fields")?
            {
                nt.fields.push(NoteField::new(field.as_str().unwrap_or_default()));
            }
            nt.templates.push(CardTemplate::new(
                "Card 1",
                text(spec, "front")?,
                text(spec, "back")?,
            ));
            col.add_notetype(&mut nt, false).map_err(err)?;
            col.get_notetype_by_name(notetype_name)
                .map_err(err)?
                .ok_or("the note type was not saved")?
        }
    };
    let deck = col
        .get_or_create_normal_deck(&text(args, "deck")?)
        .map_err(err)?;
    let mut note = notetype.new_note();
    let fields = args
        .get("fields")
        .and_then(Value::as_array)
        .ok_or("missing fields")?;
    for (i, field) in fields.iter().enumerate() {
        note.set_field(i, field.as_str().unwrap_or_default())
            .map_err(err)?;
    }
    note.tags = args
        .get("tags")
        .and_then(Value::as_array)
        .map(|t| t.iter().filter_map(Value::as_str).map(String::from).collect())
        .unwrap_or_default();
    col.add_note(&mut note, deck.id).map_err(err)?;
    Ok(json!({ "id": note.id.0 }))
}

/// # Safety
/// `method` and `args` must be valid NUL-terminated strings.
#[no_mangle]
pub unsafe extern "C" fn anki_bridge_call(method: *const c_char, args: *const c_char) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let method = CStr::from_ptr(method).to_string_lossy().into_owned();
        let args: Value =
            serde_json::from_str(&CStr::from_ptr(args).to_string_lossy()).map_err(err)?;
        dispatch(&method, &args)
    }));
    let out = match result {
        Ok(Ok(value)) => json!({ "ok": value }),
        Ok(Err(e)) => json!({ "error": e }),
        Err(_) => json!({ "error": "the Anki bridge crashed" }),
    };
    CString::new(out.to_string()).unwrap().into_raw()
}

/// # Safety
/// `s` must come from `anki_bridge_call`, freed once.
#[no_mangle]
pub unsafe extern "C" fn anki_bridge_free(s: *mut c_char) {
    if !s.is_null() {
        drop(CString::from_raw(s));
    }
}
