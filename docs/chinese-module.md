# Interlinear — a Chinese reader with the AI built in

**Status: decided, not started.** Existing apps were evaluated and rejected:
Pleco has the best dictionary and reader on iOS but is a closed app with no
plugin API; an iOS Shortcut on the share sheet gets AI next to any reader but
is one-shot, with no follow-up conversation. Neither gives integration, and
integration is the feature. Building it.

Design conversation, with the reasoning and every rejected alternative:
https://claude.ai/code/artifact/25f2c0e5-6ee3-409d-a09e-f72a912c8bae

## What it is

A reader for iPhone where the explanation, the dictionary and the tone check
are *in the app* — not in a second app you switch to.

That integration is the point. Reading, looking up, and asking are all
available separately today; having them in one place is the feature.

## Two findings that hold regardless of platform

**Word glossing does not work for Chinese.** `走进` is not `走` + `进`; `看见`
is not `看` + `见`; `不好意思` has nothing to do with "meaning". Meaning lives
in the clause, and much of it is never written — dropped subjects, unmarked
conditionals, aspect particles. The prepared unit is the **sentence**, with
notes on what is *implied rather than written*. That test is narrow enough to
apply consistently.

**Nothing judges your tones.** Everything else in this design exists somewhere
already. Tone judging is the only genuinely missing capability, and the only
reason to build rather than assemble.

## Before building: what to check in the existing apps

The evaluation that decides whether this project is needed at all.

| Question | Why it matters |
| --- | --- |
| Tap a word for pinyin + gloss, inline, without leaving the page? | this is 90% of a beginner's lookups |
| Can I get a sentence out to an AI in one action? | share sheet or copy; determines how bad the switching is |
| Do cards carry the sentence I met the word in? | the thing a generic HSK deck can't do |
| Does anything score my pronunciation? | expect no from all of them |
| Does it open my book, in my format? | |

Candidates: **Pleco** (best dictionary + reader on iOS; Document Reader is a
paid one-time add-on; closed app, no plugin API), **Readest** (OSS,
cross-platform incl. iOS, no built-in Chinese dictionary), **Anki** (cards).
KOReader and Librera are Android/e-ink only — not options on iPhone.

If Pleco covers reading, lookup and cards, the gap is AI-in-the-app plus tone
judging. That's a much smaller thing to build, and worth knowing before
starting.

## If it gets built: architecture

**The one call that decides feasibility — render in a WebView, and embed a JS
EPUB renderer.** Do not write a Chinese text renderer with tap hit-testing in
Flutter. Do not fork a reader app.

- **epub.js** — MIT, mature, well-trodden
- **foliate-js** — more modern; evaluate before committing

Either gives parsing, pagination, CFI position tracking, selection events and
themes for free, bundled into assets, offline.

```
Flutter shell     tiles, settings, API key, SQLite
   |
WebView           epub.js renders the book
   |  JS bridge
Dart              tap    -> CC-CEDICT popup (offline)
                  select -> ask Claude
                  mic    -> tone check
                  card   -> attempt log
```

The reader becomes an integration; everything that matters stays yours.

### The model call

No Dart SDK exists for Anthropic — one endpoint over plain HTTP via the `http`
package. Keep it behind **one function**, so model swaps, caching and fallbacks
never touch anything else.

`claude-sonnet-5` ~$0.006/exchange, roughly $4/month at heavy use.
`claude-opus-5` ~$0.015 (~$9) when nuance is the whole question.

**Use prompt caching from day one.** Within a session you ask many questions
about the same chapter; caching that prefix is the biggest cost lever here.

API key in the iOS Keychain, entered once in settings. It cannot ship in the
build.

### Structure

Domain logic in a top-level folder, UI under `ui/` — the convention `content/`,
`progress/` and `math/` already follow.

```
lib/
  chinese/
    book.dart           Book, Chapter, Position (an epub.js CFI)
    library.dart        import an epub, list books, remember position
    entry.dart          a dictionary entry: hanzi, pinyin, glosses
    dictionary.dart     CC-CEDICT lookup + longest-match segmentation
    reading.dart        a prepared reading: translation + implied-meaning notes
    reading_cache.dart  content hash -> reading, on disk
    tutor.dart          THE one function that calls the model
    card.dart           a card: word or pattern, with its sentence and source
    card_store.dart     append-only, same pattern as AttemptStore
    tone.dart           expected tones, heard contour, verdict
    tone_check.dart     pitch extraction and classification
  ui/apps/chinese_app.dart      the tile
  ui/screens/
    library_screen.dart         pick or import a book
    reader_screen.dart          the WebView, plus overlays
    review_screen.dart          cards due
  ui/widgets/
    word_popup.dart
    reading_sheet.dart
    tone_result.dart
assets/chinese/
  epubjs/             the renderer, bundled — no CDN, works offline
  cedict.db           the dictionary
```

Asset paths go in `config.dart`, which the README establishes as the only place
naming one.

### The bridge contract

The crux of the design. Everything crossing between JS and Dart, and nothing
else does.

**JS → Dart**

| Message | Carries |
| --- | --- |
| `ready` | the renderer has loaded |
| `tapped` | CFI, the character offset, the surrounding text |
| `selected` | CFI, the selected text, its paragraph |
| `moved` | CFI, progress through the chapter |

**Dart → JS**

`open(url)` · `goTo(cfi)` · `next()` · `prev()` · `setTheme(...)` ·
`highlight(cfi)`

The WebView owns rendering and position. It owns nothing else. Popups are
Flutter overlays drawn above it, not HTML injected into it — so they look
native, and the mic button and tone results live in Dart where the audio APIs
are.

### Where data lives

Fits the existing split without a new category:

- `content/` — unchanged, read-only, ships with the app
- `progress/` — the attempt log gains tone misses and grammar patterns
  alongside answers. The scheduler the README left room for.
- imported books and cards — device-written, SQLite, same side as attempts

## Build order

1. ~~WebView + epub.js — open a chapter, paginate, remember position~~ **done**
2. ~~Tap a word → CC-CEDICT popup, offline~~ **done** *(kills 90% of lookups)*
3. ~~Select a sentence → ask Claude~~ **done** *(the key feature; before voice
   complicates it)*
4. ~~Cards from taps and selections~~ **done**, into their own store
5. ~~Voice — TTS out, speech in~~ **done** (sherpa-onnx on device for speech
   in; `flutter_tts` out, with Azure for the companion's own voice when a key
   is set)
6. Tone judging — not started

Stages 1–3 are the app. Voice and tones sharpen it but aren't what make it
useful.

### What stage 3 turned into

Two ways to ask, because they are two different questions:

- **The sentence, prepared** — `reading.dart` asks the companion's `/read` for
  a translation plus notes on what is *implied rather than written*, and
  `reading_sheet.dart` shows those halves apart. Reached from the word sheet,
  because a word looked up in isolation is the failure mode this module exists
  to avoid.
- **The conversation** — `tutor.dart` and the companion strip, for everything
  a prepared sentence does not answer.

A reading is cached under the sentence itself (`reading_cache.dart`,
FNV-1a over the UTF-8 bytes — `String.hashCode` promises nothing across Dart
releases, and a cache keyed on a shifting value quietly stops hitting). Going
back over a paragraph is therefore free, which is what makes re-reading one
affordable at all.

### Tone judging, when it comes

Splits at *where the syllable boundaries are*:

| | Word or short phrase | Whole sentence at speed |
| --- | --- | --- |
| Syllable boundaries | energy dips — straightforward | forced alignment — hard |
| Telling shapes apart | distinctive in isolation | compressed, blurred |
| Sandhi | predictable, worth teaching | 3-3 chains, `不`/`一` — compounding |
| **Verdict** | **build this** | **stretch goal** |

Prototype standalone in Python on the Mac first — numpy and scipy are already
installed, macOS `afconvert` does m4a → wav. An evening tells you whether
contour classification works on your voice before any of it is committed.

**Do not judge tones by comparing transcripts.** Recognisers snap to plausible
words using their own language model, so a mediocre fourth tone still
transcribes correctly and you get told you were fine. When one *is* caught
(`就` heard as `九`) that's real — but silence is not proof. This is why tone
work must be pitch-based.

## Open questions

- **Which book?** Asked repeatedly, still unanswered, and it matters more than
  any tooling decision. A beginner in a real novel hits forty unknown words a
  page and no app rescues that. Graded readers exist for this gap.
- **Does it interrupt or wait?** Suggested: pronunciation corrected
  immediately, everything else held until you stop.
- **English or Chinese answers?** Suggested: English with Chinese examples at
  beginner level, as a dial that moves as you improve.

## Rejected, with reasons

| Idea | Why not |
| --- | --- |
| Word-by-word glossing | meaning is in the clause, not the words |
| MCP server as the co-reader | no microphone — it can hold a book, not be talked to |
| Prepare on Mac, read on iPad | moves questions to another night instead of removing them |
| Camera as the text source | DRM independence you don't need, at a cost on every page |
| Whisper on the phone | transcribes mixed speech in bursts, not while you talk; sherpa-onnx streams it |
| iOS's own recogniser | streams, but one language at a time — a question mixing English and Chinese comes back mangled |
| Bluetooth between devices | Wi-Fi + Bonjour, without fighting iOS background limits |
| Wi-Fi bridge to Claude Code | a weekend's work plus a permanent "is the Mac awake" failure, to save a few dollars |
| Kindle or Pleco integration | neither exposes a plugin API on any platform |
| Obsidian plugin | it's a notes app; reading a novel in it is bad, and it yields "capture now, study later" rather than asking while you read |
| Writing our own text renderer | tap hit-testing on Chinese text is the trap that sinks the project — embed epub.js |

## The licence question

Anki's core ships **inside the app binary**, under **AGPL-3**:
`ios/AnkiBridge/AnkiBridge.podspec` declares
`s.license = { :type => 'AGPL-3.0-or-later' }`, and the xcframework is a
static library linked into Runner.

On TestFlight this was deferred deliberately — the decision was to verify the
sync worked first. Build 17 shipped that way. A **public App Store release is
the point at which it stops being deferrable**, because AGPL entitles anyone
who receives the binary to the source of the whole combined work, and this
repository is private.

The options, none of which is chosen yet:

| | What it costs |
| --- | --- |
| Drop rslib from the App Store build | no AnkiWeb sync in the public app; cards still save locally; repo stays private; your own builds keep the sync |
| Open-source the app under AGPL-3 | keeps the sync; repo becomes public; does **not** fully settle it, since Apple's distribution terms and the GPL family are the unresolved conflict that pulled VLC |
| Stay on the TestFlight public link | up to 10,000 testers, no review, question stays parked |

Settle this **before** Submit, not after. Nothing in `docs/app-store.md` —
icon, screenshots, privacy answers — depends on which way it goes, so that
work is safe to do first.

This is a note about a licence, written by someone who is not a lawyer.
