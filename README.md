# mini_hub

A practice app for UIL academic events, built around the Bryant Heath number
sense manual. Lessons are markdown; questions are graded on the device and every
attempt is logged locally. Nothing is sent anywhere.

## Running it

```sh
flutter run                                # the shipped question bank
flutter run --dart-define=CONTENT=sample   # a small stand-in course
flutter test                               # about twenty seconds
flutter analyze
```

Two tests build every question and every lesson through the real widget tree.
They are most of the running time and are tagged `slow`, so `flutter test`
skips them:

```sh
flutter test --run-skipped --tags slow
```

What they uniquely catch is a widget that cannot be built. Whether the maths
parses — the failure a student actually sees, a "Parser Error" where the
question should be — is checked in under a second by `prompt_parses_test` and
`lesson_parses_test` over every prompt, revealed answer and lesson span, and
those stay in the default run.

Every setting lives in `lib/config.dart`. Nothing else in `lib` names an asset
path.

## Layout

```
lib/
  config.dart      every setting, and the only place naming an asset path
  content/         the shipped bank: models, and the repository that reads it
  progress/        the attempt log, and the scope that delivers it to widgets
  math/            LaTeX evaluation and complex-number parsing
  ui/              hub, apps, screens, widgets
```

The split that matters is `content/` against `progress/`: one is read-only and
ships with the app, the other is written on the device and never leaves it.

## How it fits together

**Content is read-only JSON and markdown under `assets/content/`.** One course
index names the courses, a course names its topics, a topic carries a lesson and
a `questions.json`. Nothing writes to it at runtime, so it diffs cleanly in git
and can be regenerated whole.

**Progress is SQLite under the app's documents directory.** `AttemptStore` is an
append-only log: one row per graded answer, never updated, never deleted. What
the app shows is derived from that log rather than stored beside it, so changing
what progress means is a recompute rather than a migration. Today it means one
thing — whether a question has ever been answered correctly.

Storage failures never block practice. If the log can't be opened, the app
still runs (with a banner saying progress isn't being saved); if individual
rows in an existing log can't be read (e.g. after a schema rename), those rows
are skipped rather than failing the whole open. A build with a bad
`CONTENT` flag is refused at startup with a screen naming the flag, instead of
throwing from deep inside a field initializer.

More is recorded than is read: the question type, what the student typed, how
long it took. That is deliberate, so a scheduler built later has a history to
work from instead of starting empty.

**A lesson is prose; practice is a separate screen.** A topic opens on two tabs.
The lesson is plain markdown with LaTeX and nothing of our own in it, so the
render path is what the packages already do. Questions are read from
`questions.json` and built directly into widgets, with no parser between the
data and the screen. They used to be embedded in lessons through a markdown
syntax we maintained ourselves; splitting them deleted that syntax, its
builder, and the whole class of bug where a tag pointed at a question that
wasn't there.

**Answers grade themselves.** `Answer` is a sealed hierarchy and each shape
carries its own rule — a band for estimation problems, real and imaginary parts
for complex ones, lowest terms for fractions where the manual demands them. The
input widget never asks what kind of question it is showing.

## Regenerating the question bank

```sh
python3 tools/build_questions.py                 # every topic
python3 tools/build_questions.py <topic-slug>    # just one
```

It reads the verified source data in `content_src/`, then writes each topic's
`questions.json` and its `questionIds`. Re-running rewrites both wholesale, so
it is safe to run twice.

## Tests worth knowing about

The asset tests are the ones that catch what a device would otherwise catch
first: a content directory missing from `pubspec.yaml` ships no files at all, a
question that fails to parse breaks the practice tab, and a course absent from
the index is invisible however finished it is.

## Licence

**AGPL-3.0-or-later** — see `LICENSE`.

The whole app is under AGPL because Anki's `rslib` is statically linked into
the iOS binary to provide AnkiWeb sync, and AGPL has no linking exception: the
combined work it produces is covered, so the source is published. Anyone who
receives a build is entitled to this source, which is why the repository is
public.

`docs/chinese-module.md` records the reasoning, including the two alternatives
that were considered and why neither avoids the obligation.
