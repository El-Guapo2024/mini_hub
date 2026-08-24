# Shipping

Every merge to `main` bundles the app and attaches it to the workflow run.
Nothing is signed for a store and nothing is uploaded to Apple yet — that waits
on an Apple Developer account. The release point comes later; the artifact is
here now.

| Workflow | Runs on | Does |
| --- | --- | --- |
| `pr.yml` | pull requests, and pushes to `main` | format, analyze, both test suites |
| `build.yml` | pushes to `main`, or by hand | APK and iOS archive, attached to the run |
| `testflight.yml` | **by hand only** | signs and uploads to App Store Connect |

## Getting a build

Actions → the run for your merge → **Artifacts**, at the bottom.

| Artifact | What it is |
| --- | --- |
| `mini-hub-android-<n>` | `app-release.apk`. Install it on any Android phone — the phone will warn about an unknown source, because it is signed with the Flutter debug key rather than a Play Store one. |
| `mini-hub-ios-archive-<n>` | `Runner.xcarchive`, zipped. Not installable: an iOS build has to be signed by a real account before a phone will run it. It is kept because signing it is the only step between here and TestFlight. |

The iOS job earns its place even so — a release build is compiled ahead of time
and tree-shaken, and it can fail where the debug build the tests run against
does not.

Artifacts are kept for 30 days.

## Turning on TestFlight, later

`testflight.yml` is written and works, but its `push` trigger is removed so it
cannot fail on every merge — a workflow that is always red is one everybody
learns to ignore. Run it from the Actions tab once the list below is done, and
when it goes green, add back:

```yaml
on:
  push:
    branches: [main]
  workflow_dispatch:
```

Nothing below can be done from this repository — all of it needs an Apple
Developer account.

### 1. Enrol in the Apple Developer Program

<https://developer.apple.com/programs/enroll/> — $99 a year. Sign in with the
Apple ID you already have; enrolment adds a membership to that account rather
than making a new one. Choose **Individual**: an Organization enrolment needs a
D-U-N-S number and takes weeks. Approval is usually a day or two.

### 2. Register the bundle identifier

The app is `com.juanluera.minihub`, set in
`ios/Runner.xcodeproj/project.pbxproj` and `android/app/build.gradle.kts`. It is
permanent from the first build App Store Connect sees.

- Developer portal → Identifiers → App IDs → App, **explicit**, that string. No
  capabilities: the app uses none.
- App Store Connect → Apps → `+`, pick that bundle id.

### 3. Repository secrets

Under Settings → Secrets and variables → Actions → Secrets. Every binary file
is base64, because a secret is a string:

| Secret | What it is | How to get it |
| --- | --- | --- |
| `APPLE_TEAM_ID` | 10-character team id | Apple Developer → Membership |
| `IOS_DIST_CERTIFICATE_P12` | Apple Distribution certificate and private key | Keychain Access → export as .p12 → `base64 -i cert.p12 \| pbcopy` |
| `IOS_DIST_CERTIFICATE_PASSWORD` | the password set on that export | you choose it |
| `APP_STORE_CONNECT_KEY_ID` | API key id | App Store Connect → Users and Access → Integrations → App Store Connect API |
| `APP_STORE_CONNECT_ISSUER_ID` | issuer id, on the same page | as above |
| `APP_STORE_CONNECT_PRIVATE_KEY` | the `.p8` the key page downloads | `base64 -i AuthKey_XXX.p8 \| pbcopy` — Apple lets you download it once |

Give the API key the **App Manager** role. Developer cannot upload builds.

There is no provisioning profile to export. Xcode fetches one per build using
the API key, and creates it if it does not exist. A committed profile expires a
year after it is made, always quietly.

The certificate is not left to the API key in the same way, deliberately: Apple
allows three distribution certificates, and a fresh runner has no private key to
reuse, so automatic signing would mint a new one every build and lock the
account out on the fourth.

## Version numbers

The build number is the workflow run number, in every workflow. App Store
Connect refuses a build number it has seen before, and `pubspec.yaml` ships `+1`
forever, so CI overrides it with something that only ever goes up. It is worth
doing now rather than at the end: it means two artifacts from two merges are
told apart by the app itself, not only by the file they came in.

The marketing version — the `1.0.0` in `pubspec.yaml` — is left alone, because
deciding that a release is 1.1 rather than 1.0.1 is not a thing CI should guess.
Change it in `pubspec.yaml` when you mean to.

## Before the App Store, as opposed to TestFlight

TestFlight will take a build that the App Store would reject. Still outstanding:

- **Privacy policy URL and the privacy questionnaire.** The app stores what a
  student answered, locally in SQLite. It collects nothing and sends nothing —
  say so, rather than leaving it blank.
- **Export compliance.** No custom cryptography, so this is the short answer,
  but `ITSAppUsesNonExemptEncryption` in `Info.plist` set to `false` stops
  being asked every upload.
- **Screenshots** at the required sizes, and a description.
- **Age rating**, and an account-deletion answer — there are no accounts.

## Running it by hand

`testflight.yml` has `workflow_dispatch`, so a build can be re-cut without an
empty commit — for an expired certificate, or an App Store Connect outage that
ate an upload.
