# The App Store listing

`docs/shipping.md` covers how a build is signed and uploaded. This is the
other half: the text and answers App Store Connect asks for before version
1.0 can leave `PREPARE_FOR_SUBMISSION`.

Everything here is written to be true of the shipped app rather than
flattering to it. The privacy answers in particular are a declaration, not
marketing.

## What actually leaves the phone

Checked against the code on 2026-09-20, because the privacy questionnaire is
only worth anything if it is accurate. The short version: **the app has no
server of its own, and every outbound connection is something the reader
switched on themselves.**

| Destination | Happens when | What is sent |
| --- | --- | --- |
| `api.anthropic.com` (`lib/chinese/claude.dart`) | only once a Claude API key is saved in Connectors | the passage open on screen, and the question asked about it |
| `<region>.tts.speech.microsoft.com` (`lib/chinese/azure_tts.dart`) | only once an Azure Speech key is saved | the companion's answer text, to be spoken |
| AnkiWeb (`native/anki_bridge`, per-account endpoint) | only once an AnkiWeb account is connected | the cards saved while reading, and the collection they live in |

With no connectors configured, the app makes no network requests at all: the
reader, the CC-CEDICT dictionary, the card store and reading aloud are all
on-device.

Not sent anywhere, at any time:

- **Audio.** Speech recognition is sherpa-onnx running on the phone
  (`lib/chinese/transcriber.dart`). Recordings never leave it.
- **Books.** EPUBs are read from local storage and rendered in a WebView that
  loads nothing remote.
- **Reading progress, cards and attempt history.** Local SQLite.
- **Keys and the AnkiWeb sync key.** iOS Keychain, via
  `flutter_secure_storage`. The AnkiWeb *password* is never stored — only the
  sync key the server hands back at login.

There are no analytics, crash reporting, advertising or attribution SDKs in
`pubspec.yaml`. Nothing profiles the reader and nothing is sold.

## App Privacy answers

**Data collection: none by the developer.** There is no backend, no account
and no telemetry, so there is nothing to collect. The three services above
receive data under the reader's *own* credentials, and each is opt-in.
Disclose them in the policy — as above — rather than claiming the app is
airtight.

## Account deletion

**The app creates no account,** so there is nothing to delete and no deletion
flow to provide. Connectors hold credentials for *other people's* services;
removing one (swipe on the Connectors screen) deletes the key from the phone,
and the underlying Anthropic or AnkiWeb account is managed where it was made.

## Age rating

Nothing in the questionnaire applies: no violence, no mature or suggestive
themes, no profanity, no gambling, no contests, no user-generated content
shared between users, no unrestricted web access — the WebView renders local
book files only and is pointed at `about:blank` when a book closes.

The one honest wrinkle: the reader opens **whatever EPUB the user supplies**,
and the app cannot vouch for the contents of a book someone loads themselves.
That is the same position as any ebook reader.

## Privacy policy

**Published:**
https://gist.github.com/El-Guapo2024/4cc6c5daef50907725e8fe430ab94987

A public Gist, because this repository is private and Apple only requires
that the link resolve for anyone. The file it was made from is kept at
`~/Documents/TheMiniHub App Store/privacy-policy.md`; edit that and
`gh gist edit` to change it, so the two do not drift.

The text, as published:

> **TheMiniHub — Privacy Policy**
>
> TheMiniHub does not collect, store or transmit any personal information to
> its developer. There is no account, no analytics and no server operated by
> this app.
>
> Everything the app records — the books you open, where you are in them, the
> flashcards you save and your practice history — is stored only on your own
> device.
>
> The app can connect to three outside services, each of which you must set up
> yourself with your own credentials, and none of which is used unless you do:
>
> - **Anthropic (Claude)** — if you add a Claude API key, the passage on screen
>   and the question you ask are sent to Anthropic to answer it.
> - **Microsoft Azure Speech** — if you add an Azure key, the companion's answer
>   text is sent to Microsoft to be spoken aloud.
> - **AnkiWeb** — if you connect an Anki account, the flashcards you save are
>   synced to AnkiWeb.
>
> Your use of those services is governed by their own privacy policies. Your
> API keys and your AnkiWeb sync key are held in the iOS Keychain on your
> device and are never sent anywhere except to the service they belong to.
> Your AnkiWeb password is never stored.
>
> Speech recognition runs entirely on your device. Audio is never uploaded.
>
> Removing a connector on the Connectors screen deletes its credentials from
> your device. Deleting the app removes everything else.
>
> Questions: antoniotwin_luera@hotmail.com


## Description

> An interlinear reader for Chinese.
>
> Open a Chinese EPUB and read it the way you actually read: tap any word for
> its pinyin and meaning, straight from the CC-CEDICT dictionary, offline and
> without leaving the page. Save the words worth keeping as flashcards as you
> go.
>
> Have the page read aloud, following along word by word, at a pace you set.
>
> Bring your own Claude API key and a reading companion sits beside you —
> ask why a sentence is built the way it is, what a particle is doing, what
> the writer implied but did not say. Connect an AnkiWeb account and the
> cards you save appear in Anki on all your devices.
>
> The reader and the dictionary work offline and need no account. The
> companion and Anki sync are optional and use your own keys.

Subtitle (30 characters max): `Read Chinese books, word by word` — 32, so
trim to `Read Chinese, word by word` (26).

Keywords: `chinese,mandarin,reader,epub,hsk,pinyin,dictionary,cedict,anki,
flashcards,learn chinese,study`

## Still outstanding

- ~~Screenshots~~ **done** (2026-09-20), in
  `~/Documents/TheMiniHub App Store/screenshots/`. Five each at 1320x2868
  (iPhone 6.9") and 2064x2752 (iPad 13") -- in 2026 only the largest of each
  family is uploaded and Apple scales the rest, so those two cover every
  device. Captured by `integration_test/screenshots_test.dart`; only one
  simulator may be booted while it runs.
- ~~A contact address~~ **done**: `antoniotwin_luera@hotmail.com`, the
  address the Apple Developer account holder already reads.
- ~~A public home for the privacy policy~~ **done** — the Gist above.
- **The licence question.** Anki's core ships inside the binary under
  AGPL-3 (`ios/AnkiBridge/AnkiBridge.podspec` declares it). That is settled
  one way or another before Submit, not after — see the note in
  `docs/chinese-module.md`.
