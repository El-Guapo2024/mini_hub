# content_src

Source material for the question bank. **Nothing here ships in the app** — it
is not listed in `pubspec.yaml` assets. It is the input the generator reads to
produce the bundled topic folders under `assets/content/`.

## Flow

```
content_src/source/bryant_heath/       tools/build_questions.py
  bh_prompts_vlm.json    ─┐                      │
  bh_answers.json        ─┴──────────────────────┴──→  assets/content/number_sense/<topic>/
                                                          ├── topic.yml      (questionIds filled in)
                                                          └── questions.json (written whole)
```

`lesson.md` is **not** generated. Lessons are hand-written markdown and the
generator only strips a stale `## Practice` section if an older run left one.

Run it with:

    python3 tools/build_questions.py                 # every topic
    python3 tools/build_questions.py <topic-slug>    # just one

It is re-runnable: every output is rewritten wholesale, so running twice leaves
the tree byte-identical.

## How a topic finds its questions

Each `assets/content/number_sense/<topic>/topic.yml` carries a `bh_section`
naming its section of the manual (`1.2.1`, `2.1.4`, …). That is the only link
between a topic and its questions; the generator reads it, pulls that section's
prompts and answers, and writes them out. Seven topics have no matching section
and stay lesson-only.

## What the generator emits

```json
{"id": "bh.1.2.1.q1", "prompt": "54 \\times 11 =",
 "topic": "multiplying_by_11_trick", "answer": {"answer": 594, "type": "numeric"}}
```

- `prompt` is LaTeX rendered with `Math.tex`, so it is **not** wrapped in `$`.
- The **answer** carries the type, not the question. `numeric`, `estimate`,
  `complex`, `fraction`, `base` — each grades differently, and attempts are
  logged under that name, so renaming one splits a topic's history in two.
- `derived`, `corrected` and `note` are dropped. Provenance stays here and in
  git history; a student has no use for "the book prints 39 but is wrong".

## Authoring rules for lessons

- Lessons are **plain markdown**. There is no custom syntax: a question is
  never embedded in prose, it lives on the Practice tab. An earlier
  `[[question:id]]` syntax and its parser were deleted.
- Display math needs its `$$` **alone on its line**. `$$x = 1$$` spanning
  several lines never parses and renders as literal source — `lesson_latex_test`
  fails the build over it.
- No markdown tables. `MarkdownBody` lays them out at the available width with
  no horizontal scroll, so on a phone the columns crush together. Wide tabular
  content belongs in a display-math array, which scrolls sideways.
- No LaTeX in a topic title. The app bar renders it as plain text.

## The extraction pipeline

The other scripts in `tools/` — `extract_bh_*`, `solve_*`, `verify_*`,
`reconcile_final`, `apply_adjudications`, and the rest — are the one-time
pipeline that read the manual and produced the committed `bh_*.json` files.
They are not run as part of a normal build. Only `build_questions.py` is.
