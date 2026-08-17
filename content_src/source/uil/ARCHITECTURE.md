# UIL Number Sense test archive

Original UIL (University Interscholastic League) Number Sense test PDFs, kept
as reference. **Nothing here is read by the app or by any script in `tools/`.**

```
elementary/<year>/     9 PDFs
middle_school/<year>/  9 PDFs
high_school/<year>/    19 PDFs
elementary_practice_book_part2.docx
```

## Why it is here and not used

The shipped question bank comes from the Bryant Heath manual, extracted into
`content_src/source/bryant_heath/` and turned into `assets/content/` by
`tools/build_questions.py`. See `content_src/README.md` for that flow.

These UIL tests are a second source that has not been extracted. They are kept
so the bank can be widened later, and so answers can be cross-checked against
material the manual did not write.

## History

This file previously described a `pipeline/` directory, a `build_db.py`, and a
runtime `questions.db` holding the questions. None of those ever existed in
this repository — it was written before the real pipeline was. The app stores
questions as JSON assets and uses SQLite only for the on-device attempt log.
