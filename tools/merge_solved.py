#!/usr/bin/env python3
"""Score the reasoning pass against the book's answer key.

The batch solvers never saw the key, so agreement between an independently
derived answer and the printed one is real evidence that both the transcription
and the key are right. Disagreement is not automatically a solver error — the
manual has known defects — so mismatches are reported, never silently merged.

Writes bh_solved.json:
    {"<section>": {"<n>": {"value": .., "status": "confirmed"|"unverified"}}}
"""
import json
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from verify_all import agrees  # noqa: E402

SRC = Path(__file__).resolve().parent.parent / 'content_src/source/bryant_heath'
SOLVE = Path('/private/tmp/claude-501/-Users-juanantonioluera'
             '/4bfac6ce-fefc-4211-a4e1-195245fa3712/scratchpad/solve')


def main():
    answers = json.loads((SRC / 'bh_answers.json').read_text())
    prompts = json.loads((SRC / 'bh_prompts_vlm.json').read_text())

    solved = {}
    for f in sorted(SOLVE.glob('out*.json')):
        try:
            solved.update(json.loads(f.read_text()))
        except Exception as e:
            print(f'  ! could not read {f.name}: {e}')

    out, tally, mismatches = {}, Counter(), []
    for qid, rec in solved.items():
        sec, _, n = qid.partition('#')
        v = rec.get('value') if isinstance(rec, dict) else rec
        if v is None:
            tally['declined'] += 1
            continue
        try:
            v = float(v)
        except (TypeError, ValueError):
            tally['declined'] += 1
            continue

        a = answers.get(sec, {}).get(n)
        if not a or 'answer' not in a and a.get('type') != 'approx':
            status = 'unverified'          # nothing to check against
            tally['no key'] += 1
        elif agrees(v, a):
            status = 'confirmed'
            tally['confirmed'] += 1
        else:
            status = 'disputed'
            tally['disputed'] += 1
            mismatches.append((sec, n, prompts.get(sec, {}).get(n, ''), v,
                               a.get('answer')))
        out.setdefault(sec, {})[n] = {'value': v, 'status': status}

    (SRC / 'bh_solved.json').write_text(json.dumps(out, indent=1, sort_keys=True))

    print(f'batches read: {len(list(SOLVE.glob("out*.json")))}, answers: {len(solved)}')
    for k, c in tally.most_common():
        print(f'  {c:5}  {k}')

    by_sec = Counter(m[0] for m in mismatches)
    print('\ndisputed by section:')
    for sec, c in by_sec.most_common(12):
        print(f'  {sec:10} {c}')
    print('\nfirst disputed rows:')
    for m in mismatches[:25]:
        print(f'  {m[0]} #{m[1]}: {m[2][:56]!r} -> {m[3]}  key={m[4]}')
    Path('/tmp/disputed.json').write_text(json.dumps(mismatches, indent=1))


if __name__ == '__main__':
    main()
