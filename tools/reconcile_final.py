#!/usr/bin/env python3
"""Reconcile the last unconfirmed questions across three independent sources.

For the 100 problems the manual never printed an answer to, there is no external
ground truth, so 'confirmed' has to mean something weaker but still real: two
independent derivations that agree. The three sources are

  1. the deterministic solver chain (bh_computed.json),
  2. an agent asked to solve each problem, and
  3. a second agent, prompted differently, required to execute every
     calculation in python rather than answer from arithmetic.

Two agreeing sources promote an answer to confirmed. Anything with a lone
source, or with sources that disagree, stays flagged — those are exactly the
questions a student should not be graded on.
"""
import json
from collections import Counter
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / 'content_src/source/bryant_heath'
FINAL = Path('/private/tmp/claude-501/-Users-juanantonioluera'
             '/4bfac6ce-fefc-4211-a4e1-195245fa3712/scratchpad/final')

TOL = 1e-5


def close(a, b):
    if a is None or b is None:
        return False
    return abs(a - b) <= max(1e-9, abs(b) * TOL, abs(a) * TOL)


def load(name):
    out = {}
    f = FINAL / name
    if f.exists():
        for k, v in json.loads(f.read_text()).items():
            val = v.get('value') if isinstance(v, dict) else v
            if val is not None:
                try:
                    out[k] = float(val)
                except (TypeError, ValueError):
                    pass
    return out


def main():
    computed = json.loads((SRC / 'bh_computed.json').read_text())
    answers = json.loads((SRC / 'bh_answers.json').read_text())

    a = {**load('A0.json'), **load('A1.json')}
    b = {**load('B0.json'), **load('B1.json')}
    items = json.loads((FINAL / 'rem0.json').read_text()) \
        + json.loads((FINAL / 'rem1.json').read_text())

    tally = Counter()
    resolved = {}
    unresolved = []

    for row in items:
        qid = row['id']
        sec, _, n = qid.partition('#')
        solver = computed.get(sec, {}).get(n)
        va, vb = a.get(qid), b.get(qid)

        # A printed answer, where one exists, outranks the derivations.
        rec = answers.get(sec, {}).get(n)
        book = rec.get('answer') if rec and 'answer' in rec else None

        votes = [v for v in (solver, va, vb) if v is not None]
        agreed = None
        for i, x in enumerate(votes):
            for y in votes[i + 1:]:
                if close(x, y):
                    agreed = x
                    break
            if agreed is not None:
                break

        if book is not None and agreed is not None and close(agreed, book):
            tally['confirmed vs book'] += 1
            resolved[qid] = book
        elif book is not None:
            tally['book kept, derivations differ'] += 1
            resolved[qid] = book
        elif agreed is not None:
            tally['confirmed by two derivations'] += 1
            resolved[qid] = agreed
        elif votes:
            tally['single source only'] += 1
            unresolved.append((qid, row['prompt'], solver, va, vb))
        else:
            tally['no answer at all'] += 1
            unresolved.append((qid, row['prompt'], solver, va, vb))

    for k, c in tally.most_common():
        print(f'  {c:5}  {k}')

    # Write the newly established answers back into the key.
    added = 0
    for qid, val in resolved.items():
        sec, _, n = qid.partition('#')
        rec = answers.setdefault(sec, {}).get(n)
        if rec and ('answer' in rec or rec.get('type') == 'approx'):
            continue
        answers[sec][n] = {'type': 'numeric', 'answer': val, 'derived': True,
                           'note': 'no printed key; two independent '
                                   'derivations agree'}
        added += 1
    (SRC / 'bh_answers.json').write_text(json.dumps(answers, indent=1, sort_keys=True))
    print(f'\nadded {added} derived answers to the key')

    print(f'\nstill unresolved: {len(unresolved)}')
    for qid, prompt, s, va, vb in unresolved[:25]:
        print(f'  {qid}: {prompt[:56]!r}\n      solver={s} A={va} B={vb}')
    Path('/tmp/unresolved_final.json').write_text(
        json.dumps([u[:2] for u in unresolved], indent=1))


if __name__ == '__main__':
    main()
