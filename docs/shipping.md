# Shipping to TestFlight

Every merge to `main` builds a signed iOS release and uploads it to App Store
Connect, where it appears in TestFlight. That build is the artifact that goes
to the App Store — there is no separate release build to make later.

Two workflows:

| Workflow | Runs on | Does |
| --- | --- | --- |
| `pr.yml` | pull requests, and pushes to `main` | format, analyze, both test suites |
| `testflight.yml` | pushes to `main`, or by hand | archives, signs, uploads |

The gate runs a second time inside `testflight.yml`. That is deliberate: a
direct push to `main` never opens a pull request, and this is the job that puts
code on someone's phone.

## What has to be set before the first build can work

Nothing below can be done from this repository — all of it needs an Apple
Developer account. Until it is in place `testflight.yml` fails, and says which
piece is missing.

### 1. A bundle identifier you own

The app is still `com.example.miniHub`. App Store Connect will not accept
anything under `com.example`, so this has to change to a reverse-domain id you
control — `com.juanluera.minihub`, say.

It is set in `ios/Runner.xcodeproj/project.pbxproj` (two places for the app,
three more for `RunnerTests`), and has to be registered as an App ID in the
Apple Developer portal and given an app record in App Store Connect.

`testflight.yml` checks this before it archives, so it fails in a minute
rather than after twenty.

### 2. Repository variable

| Variable | Value |
| --- | --- |
| `IOS_BUNDLE_ID` | the same identifier, so the export plist can name its profile |

Set under Settings → Secrets and variables → Actions → Variables.

### 3. Repository secrets

Under Settings → Secrets and variables → Actions → Secrets. Every binary file
is base64, because a secret is a string:

| Secret | What it is | How to get it |
| --- | --- | --- |
| `APPLE_TEAM_ID` | 10-character team id | Apple Developer → Membership |
| `IOS_DIST_CERTIFICATE_P12` | Apple Distribution certificate and private key | Keychain Access → export as .p12 → `base64 -i cert.p12 \| pbcopy` |
| `IOS_DIST_CERTIFICATE_PASSWORD` | the password set on that export | you choose it |
| `IOS_PROVISIONING_PROFILE` | App Store provisioning profile | Developer portal → Profiles → Distribution → App Store → `base64 -i profile.mobileprovision \| pbcopy` |
| `IOS_PROVISIONING_PROFILE_NAME` | the profile's name, exactly | shown next to it in the portal |
| `APP_STORE_CONNECT_KEY_ID` | API key id | App Store Connect → Users and Access → Integrations → App Store Connect API |
| `APP_STORE_CONNECT_ISSUER_ID` | issuer id, on the same page | as above |
| `APP_STORE_CONNECT_PRIVATE_KEY` | the `.p8` the key page downloads | `base64 -i AuthKey_XXX.p8 \| pbcopy` — Apple lets you download it once |

Give the API key the **App Manager** role. Developer cannot upload builds.

## Version numbers

The build number is the workflow run number. App Store Connect refuses a build
number it has seen before, and `pubspec.yaml` ships `+1` forever, so CI
overrides it with something that only ever goes up.

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
