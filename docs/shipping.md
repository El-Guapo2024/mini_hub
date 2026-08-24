# Shipping

Every merge to `main` signs an iOS build and uploads it to App Store Connect,
where it appears in TestFlight. That build is the artifact that goes to the App
Store — there is no separate release build to make later.

| Workflow | Runs on | Does |
| --- | --- | --- |
| `pr.yml` | pull requests, and pushes to `main` | format, analyze, both test suites |
| `build.yml` | pushes to `main`, or by hand | APK and unsigned iOS archive, attached to the run |
| `testflight.yml` | pushes to `main`, or by hand | signs, uploads to TestFlight |

The gate runs a second time inside `testflight.yml`. That is deliberate: a
direct push to `main` never opens a pull request, and this is the job that puts
code on someone's iPad.

## Installing a build

TestFlight, on the device. Sign in as a tester in the **Internal** group, open
TestFlight, install **TheMiniHub**. Later merges update it in place.

`build.yml` also attaches downloadable files to each run — Actions → the run →
**Artifacts**, kept for 30 days:

| Artifact | What it is |
| --- | --- |
| `mini-hub-android-<n>` | `app-release.apk`. Installs on any Android phone; it warns about an unknown source, because it is signed with the Flutter debug key rather than a Play Store one. |
| `mini-hub-ios-archive-<n>` | `Runner.xcarchive`, zipped and unsigned. Not installable — TestFlight is how iOS builds get onto a device. Kept because it is what a signed build is made from. |

The unsigned iOS job earns its place next to the signed one: it is the same
release compile without the account, so it still catches an AOT or tree-shaking
failure that the debug build the tests run against would not.

## The account this is wired to

| | |
| --- | --- |
| Bundle identifier | `com.juanluera.minihub` |
| App Store name | TheMiniHub |
| App Store Connect app id | `6804838723` |
| Team id | `L2A443C7G8` |
| API key | `Mini_Hub_CI`, **App Manager** |
| Distribution certificate | expires **2027-08-24** |
| Provisioning profile | `CI App Store com.juanluera.minihub`, remade by CI as needed |

Credentials are backed up outside every git repository, in
`~/ws/secrets/apple/`, with the `.p12` password in the `README.txt` there. The
`.p8` in that folder is the one file Apple will not reissue — it should exist
somewhere that is not this machine as well.

## Repository secrets

Settings → Secrets and variables → Actions. Every binary file is base64,
because a secret is a string. All six are set:

| Secret | What it is | Where it came from |
| --- | --- | --- |
| `APPLE_TEAM_ID` | 10-character team id | Apple Developer → Membership |
| `IOS_DIST_CERTIFICATE_P12` | Apple Distribution certificate and private key | made through the API, see below |
| `IOS_DIST_CERTIFICATE_PASSWORD` | the password on that `.p12` | generated when it was built |
| `APP_STORE_CONNECT_KEY_ID` | API key id | App Store Connect → Users and Access → Integrations |
| `APP_STORE_CONNECT_ISSUER_ID` | issuer id, same page | as above |
| `APP_STORE_CONNECT_PRIVATE_KEY` | the `.p8` | downloaded once, at key creation |

There is no provisioning profile secret and no `IOS_BUNDLE_ID` variable. Both
were in an earlier version of this file and neither is used any more.

## How signing actually works, and why it looks like this

Four things were tried and failed on the way to a green run. The current shape
is the one that survived, and each part of it is avoiding a specific failure.

### The profile is made through the API, not by Xcode

`tools/ci/provisioning_profile.py` runs before signing. It finds the profile
named `CI App Store com.juanluera.minihub` or creates it, deletes and remakes
it if it is no longer `ACTIVE`, installs it, and prints its name for the export
plist.

The obvious alternative — `xcodebuild -allowProvisioningUpdates`, letting Xcode
fetch the profile itself — **cannot work with an API key**:

```
error: exportArchive: Cloud signing permission error
  You haven't been given access to cloud-managed distribution certificates.
error: exportArchive: No profiles for 'com.juanluera.minihub' were found
```

Automatic signing wants a cloud-managed distribution certificate, and an App
Store Connect API key is not permitted to use one. The second error is a
consequence of the first: Xcode could not create the profile it then could not
find. So the export plist says `signingStyle: manual`.

Manual does not mean anyone does anything by hand. The profile is still made
programmatically and nothing is committed — which was the point of trying
automatic signing in the first place, and is why a profile expiring quietly a
year from now is not a thing that can happen here.

### The certificate is ours, and stays ours

Apple allows three distribution certificates per account. A fresh runner has no
private key to reuse, so anything that creates certificates per build would
mint a new one every time and lock the account out on the fourth. It is
imported from `IOS_DIST_CERTIFICATE_P12` into a keychain created for the job
and thrown away with the runner.

It was generated with `openssl` and submitted as a CSR to the API — no Keychain
Access export. What matters for reproducing it is that the `.p12` uses
`PBE-SHA1-3DES`, not OpenSSL 3's default: macOS `security import` rejects the
modern encryption, and does it only on CI.

### Archive and export are separate steps

`flutter build ipa` has no passthrough to xcodebuild. Anything after `--` is
read as a Dart entrypoint:

```
Target file "-allowProvisioningUpdates" not found.
```

So Flutter archives with `--no-codesign`, and `xcodebuild -exportArchive` signs.
The half that needs to be told about certificates is the half that can be.

### The Xcode version is chosen, not inherited

```
This app was built with the iOS 17.5 SDK. All iOS and iPadOS apps must be
built with the iOS 26 SDK or later.
```

`macos-14` carries Xcode 15.4. The workflows run on `macos-26` and select the
newest Xcode on the image explicitly, because a runner can carry several and
the default is not always the newest. The version is printed in the log, so the
next time Apple raises the floor there is evidence of what was used.

`--validate-app` runs before `--upload-app` for the same reason: this rejection
costs a minute, the same rejection after upload costs a build number and a
round trip.

### Uploading is not releasing

`tools/ci/release_to_testers.py` runs last. A build that finishes processing
sits in App Store Connect visible to nobody until it is attached to a beta
group — an internal group does not pick up new builds on its own. Build 5
proved this by uploading successfully and reaching no one.

It waits for Apple to move the build to `VALID`, which is why that step takes
minutes when the ones around it take seconds, and it is safe to re-run: a build
already with the group is left alone.

The group name is `Internal` and the app id is written into the workflow. Both
are account facts rather than secrets — publishing them costs nothing, and
having them in the file means the step says what it does.

## Version numbers

The build number is the workflow run number, in every workflow. App Store
Connect refuses a build number it has seen before, and `pubspec.yaml` ships `+1`
forever, so CI overrides it with something that only ever goes up.

The marketing version — the `1.0.0` in `pubspec.yaml` — is left alone, because
deciding that a release is 1.1 rather than 1.0.1 is not a thing CI should guess.
Change it in `pubspec.yaml` when you mean to.

## Dates that will break this

Nothing here fails loudly in advance, so they are written down.

| When | What | What to do |
| --- | --- | --- |
| **2027-08-24** | distribution certificate expires | make a new one, rebuild the `.p12`, update the two certificate secrets |
| yearly | Developer Program membership | lapsing invalidates the certificate and pulls TestFlight builds |
| ~90 days after each upload | that TestFlight build expires | irrelevant while merges keep shipping; matters if the project goes quiet |
| whenever Apple says | minimum SDK | `macos-26` and newest-Xcode handles it until the runner label itself ages out |

The provisioning profile is not on this list. It is remade whenever it stops
being `ACTIVE`, which is the one expiry that takes care of itself.

## Before the App Store, as opposed to TestFlight

TestFlight will take a build that the App Store would reject. Still outstanding:

- **An app icon.** It is the Flutter placeholder — a plain white square on the
  home screen. This does not block TestFlight and does block the App Store.
- **Privacy policy URL and the privacy questionnaire.** The app stores what a
  student answered, locally in SQLite. It collects nothing and sends nothing —
  say so, rather than leaving it blank.
- **Screenshots** at the required sizes, and a description.
- **Age rating**, and an account-deletion answer — there are no accounts.

Export compliance is already handled: `ITSAppUsesNonExemptEncryption` is
`false` in `Info.plist`. Until that question is answered a build sits in App
Store Connect unavailable to testers, and answering it in the plist answers it
for every upload rather than once each time.

## Running it by hand

`testflight.yml` has `workflow_dispatch`, so a build can be re-cut without an
empty commit — for an expired certificate, or an App Store Connect outage that
ate an upload.
