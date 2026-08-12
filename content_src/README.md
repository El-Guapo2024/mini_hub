# content_src

Raw source material for mini_hub lessons. **Nothing here ships in the app** —
it is not listed in `pubspec.yaml` assets. These are the human-written docs that
get turned into the bundled topic folders under `assets/content/`.

## Flow

```
content_src/<course>/<topic>.md   →   assets/content/<course>/<topic>/
                                        ├── topic.yml
                                        ├── lesson.md
                                        └── questions.json
```

One source doc per topic. It holds more than the lesson needs — full
explanations, worked examples, and a large question bank — so the generated
`lesson.md` can be tightened without losing the original material.

## Source doc structure

Each doc uses these `##` sections, in order:

| Section | Becomes | Notes |
| --- | --- | --- |
| `## Meta` | `topic.yml` | `id`, `title`, `logo` as a yaml block |
| `## Lesson` | `lesson.md` body | Markdown + `$...$` LaTeX. Place `[[question:<id>]]` where a question should appear inline |
| `## Questions` | `questions.json` | One `###` block per question |

### Question blocks

```
### q1
type: numerical
prompt: 7 + 5 = ?
answer: 12
```

- `id` is the `###` heading and must match the `[[question:qN]]` refs in `## Lesson`.
- `prompt` is a LaTeX expression — the app renders it with `Math.tex`, so it is
  **not** wrapped in `$`. Backslashes are written literally here (`\frac{3}{4}`)
  and get JSON-escaped by the generator.
- `answer` is a plain number. Answers are compared numerically at `1e-9`
  tolerance after the learner's TeX input is evaluated, so `1.25` and
  `\frac{5}{4}` both count as correct — always write the decimal.
- `type` is `numerical`. It is the only type `question_view.dart` renders today;
  anything else falls through to "unsupported question type".

## Authoring rules

- Every `[[question:id]]` in `## Lesson` must have a matching `### id` block. An
  unmatched ref renders as a red `missing question: <id>` in the app.
- Answers must be finite reals. `evaluateTex` returns null for anything else,
  which the app scores as wrong no matter what the learner types.
- Mixed numbers (`2\frac{1}{2}`) are supported in learner input — `tex_answer.dart`
  expands them before evaluating — so they are fair game in prompts.
- Keep prompts to a single expression ending in `= ?`. There is one input field
  and no partial credit.
