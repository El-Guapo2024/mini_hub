# The Google Play listing

`docs/shipping.md` covers how an Android build is signed and uploaded. This is
the other half: the text and the answers Play Console asks for before the app
can reach anyone outside the internal testing track. It is the Android
counterpart of `docs/app-store.md`, and written the same way. Everything here
describes the shipped app as it is, and the data safety answers in particular
are a declaration, not marketing.

`tools/ci/play_listing.py` puts the text and the icon into Play over the API
(the **Google Play listing** workflow). Everything else below is entered in
Play Console by hand, because the API has no way to set it.

## What actually leaves the phone

This is the same as on iOS: the Android build runs the same Dart, and the same
three connections are the only ones it makes.

| Destination | Happens when | What is sent |
| --- | --- | --- |
| `api.anthropic.com` | only once a Claude API key is saved in Connectors | the sentence or selection being asked about, the text around it, and the question typed or spoken |
| `<region>.tts.speech.microsoft.com` | only once an Azure Speech key is available | the companion's answer text, to be spoken |
| AnkiWeb | only once an AnkiWeb account is connected | the login (once), then the cards saved while reading and the collection they live in |

With no connectors configured, the app makes no network requests at all.
Speech recognition is sherpa-onnx running on the phone; audio never leaves it.
Keys and the AnkiWeb sync key are held by `flutter_secure_storage`, encrypted
with a key in the Android Keystore, and left out of Android's backups (see
`android/app/src/main/res/xml/`), because the Keystore key does not travel to
another phone and the saved keys could not be decrypted there.

The Azure key built in by CI (`AZURE_KEY`) is a free-tier key compiled into
the bundle, so the companion's voice works with nothing to set up. Treat it
as public, as `ChineseConfig.azureKey` says.

## Data safety

Google counts any data the app sends off the phone as **collected**, whoever
receives it, so the three connections above are declared. This is the
conservative reading and the honest one. The app has no server of its own,
but "no data collected" would be false the moment someone saves a key.

**Does your app collect or share any of the required user data types?** Yes.

| Data type | Collected | Shared | Optional | Why |
| --- | --- | --- | --- | --- |
| App activity → Other user-generated content | yes | no | yes | passages and questions sent to Anthropic; cards synced to AnkiWeb |
| Personal info → Email address | yes | no | yes | the AnkiWeb login, which is an email address |

- **Shared: no.** Google exempts data transferred to a third party "based on a
  specific user-initiated action, where the user reasonably expects the data
  to be shared". Each transfer here goes to a service the reader connected with
  their own credentials, and nothing goes to the developer.
- **Processed ephemerally:** no. Anthropic and AnkiWeb keep data under their
  own policies, and this app cannot promise otherwise.
- **Purpose:** App functionality, for both.
- **Encrypted in transit:** yes. Every connection is HTTPS.
- **Deletion:** there is no account with this app and the developer holds no
  data, so there is nothing to request. Removing a connector deletes its keys
  from the phone, and uninstalling removes everything else. Data held by
  Anthropic or AnkiWeb is deleted through those accounts.
- **Audio (microphone):** not collected. The permission exists for on-device
  recognition only.
- **Not collected:** location, contacts, photos, files (books are read from
  local storage and never uploaded), device IDs, diagnostics, and financial,
  health or web-browsing data. There are no analytics, crash reporting or
  advertising SDKs in `pubspec.yaml`.

## Privacy policy

Play requires a URL, entered under **App content → Privacy policy**. Use the
same Gist as the App Store:
https://gist.github.com/El-Guapo2024/4cc6c5daef50907725e8fe430ab94987

**It needs one edit before it is true of Android.** It says keys are "held in
the iOS Keychain". Replace that sentence with:

> Your API keys and your AnkiWeb sync key are held in your phone's secure
> storage (the iOS Keychain, or the Android Keystore) and are never sent
> anywhere except to the service they belong to.

Edit the kept copy in `~/Documents/TheMiniHub App Store/privacy-policy.md`
and `gh gist edit`, as `docs/app-store.md` describes.

## Content rating

This is the IARC questionnaire, in Play Console under **App content → Content
rating**. The category is **Reference, News, or Educational**. Every content
question is **No**: there is no violence, no sexuality, no profanity, no
controlled substances, no gambling, no user-to-user interaction or content
sharing, no location sharing, no digital purchases, and no unrestricted
internet access. The WebView renders local book files only.

The same wrinkle as on iOS applies. The reader opens whatever EPUB the user
supplies, and the app cannot vouch for a book someone loads themselves, which
is the position of any ebook reader.

## Target audience and content

- **Target age:** 18 and over. The companion runs on the reader's own
  Anthropic API key, and Anthropic's terms require its customers to be adults.
  Choosing any band under 13 would put the app under the Families policy,
  which a bring-your-own-key AI companion does not fit.
- **Ads:** no.
- **App access:** everything can be reviewed without an account. Tell the
  reviewer: *"The reader, dictionary and read-aloud work without an account.
  The reading companion and in-context translation need the user's own Claude
  API key (Chinese → Connectors), and card sync needs an AnkiWeb account; both
  are optional."* If review asks to see the companion, give it a key with a low
  spend limit, and revoke it afterwards.
- **News app, government app, financial features, health:** no.

## Generative AI (before production)

Play's AI-Generated Content policy asks apps whose AI output is a real part of
the app to let users **report or flag offensive output from inside the app**.
The companion's answers and the in-context translations are generated by
Claude. The app has no server to send a report to, so this is a decision to
make before the production track, not a box to tick:

- a "Report" action on a companion answer that opens an email to the contact
  address with the answer attached (the smallest change, though it leaves the
  app), or
- a small reporting endpoint, if the app ever gets a server.

Internal and closed testing do not wait on this.

## Listing text

Applied by `tools/ci/play_listing.py`, and copied there verbatim. Change both
together.

**Title** (30 max): `TheMiniHub`. This is the App Store name.

**Short description** (80 max, 75 used):

> Read Chinese books word by word, with a dictionary and a reading companion.

**Full description:**

> An interlinear reader for Chinese.
>
> Open a Chinese EPUB and read it the way you actually read: tap any word for
> its pinyin and meaning, straight from the CC-CEDICT dictionary, offline and
> without leaving the page. Drag across a phrase to look up the whole run.
> Save the words worth keeping as flashcards as you go, with the sentence you
> met them in.
>
> Have the page read aloud, following along word by word, at a pace you set.
>
> Bring your own Claude API key and a reading companion sits beside you.
> Select a few words and it says what they mean in this sentence, not just
> what they can mean. Ask why a sentence is built the way it is, what a
> particle is doing, what the writer implied but did not say - by typing, or
> by holding the mic and asking out loud. Connect an AnkiWeb account and the
> cards you save appear in Anki on all your devices.
>
> The reader and the dictionary work offline and need no account. The
> companion and Anki sync are optional and use your own keys. Speech
> recognition runs on the phone; audio never leaves it.

**Contact email:** `antoniotwin_luera@hotmail.com`, the privacy policy's
contact. If someone else holds the Play developer account, change it in both
places.

**Category:** Education. **Tags:** language learning, reference.

## Graphics

| Asset | Size | Where it comes from |
| --- | --- | --- |
| App icon | 512 × 512 PNG | `android/play/icon-512.png`, made by `tools/android_icons.py` from the iOS master; uploaded by the listing workflow |
| Feature graphic | 1024 × 500 | **required, still to make.** Play shows it above the listing. 读 and its bar on the ink, as in the icon, is enough |
| Phone screenshots | 2 to 8, 16:9 or 9:16, 1080 px or more on the short side | **still to make.** `integration_test/screenshots_test.dart` captures the iOS ones, and on an Android emulator it would capture these too |
| 7″ and 10″ tablet screenshots | optional | the iPad set, re-captured on a tablet emulator, if the app should be offered as tablet-ready |

## Still outstanding

- The feature graphic and phone screenshots (above).
- The privacy policy's one-sentence edit (above).
- The generative AI reporting decision, before production.
- Everything above that is entered in Play Console: data safety, content
  rating, target audience, app access and the privacy policy URL.
