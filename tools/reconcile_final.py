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

    python3 tools/reconcile_final.py [derivations-dir]

The derivations directory holds the agent votes this reads: A0/A1.json (source
2), B0/B1.json (source 3), and rem0/rem1.json (the questions asked). It
defaults to `content_src/source/bryant_heath/derivations`, in the tree and
under git, so the step can be re-run.

The run that produced the 99 answers now marked `derived` in bh_answers.json
read those votes from a scratch directory that no longer exists, so that
particular run cannot be reproduced. What it established is recorded in
derived_answers.json beside the key, which `--record` rewrites — so which
answers rest on this weaker standard stays answerable without re-running it.
"""
import json
import sys
from collections import Counter
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / 'content_src/source/bryant_heath'
DEFAULT_DERIVATIONS = SRC / 'derivations'

TOL = 1e-5


def close(a, b):
    if a is None or b is None:
        return False
    return abs(a - b) <= max(1e-9, abs(b) * TOL, abs(a) * TOL)


def load(final, name):
    """One source's votes. A missing file is fatal rather than an empty vote.

    Read as absent, a source cannot disagree with anything, so every remaining
    answer would be promoted on the strength of a single derivation while the
    output still said two agreed. Silence is the one thing this must not do.
    """
    f = final / name
    if not f.exists():
        raise SystemExit(
            f'missing derivation source: {f}\n'
            'Reconciling without it would promote answers on one vote while '
            'reporting two. Pass the directory holding A0/A1, B0/B1 and '
            'rem0/rem1 as the first argument.'
        )
    out = {}
    for k, v in json.loads(f.read_text()).items():
        val = v.get('value') if isinstance(v, dict) else v
        if val is not None:
            try:
                out[k] = float(val)
            except (TypeError, ValueError):
                pass
    return out


def record_derived(answers):
    """Writes down which answers rest on agreeing derivations, not the book.

    Kept beside the key rather than only in it, so the weaker standard is
    visible without walking every record, and so it survives a regeneration.
    """
    derived = {
        f'{section}#{number}': record['answer']
        for section, questions in sorted(answers.items())
        for number, record in sorted(questions.items())
        if isinstance(record, dict) and record.get('derived')
    }
    path = SRC / 'derived_answers.json'
    path.write_text(json.dumps(derived, indent=1, sort_keys=True) + '\n')
    print(f'recorded {len(derived)} derived answers in {path.name}')
    return derived


def main():
    argv = [a for a in sys.argv[1:] if a != '--record']
    answers = json.loads((SRC / 'bh_answers.json').read_text())

    # Recording what a past run established needs no inputs, which is the point:
    # the run behind the current key cannot be reproduced.
    if '--record' in sys.argv:
        record_derived(answers)
        if not argv:
            return

    final = Path(argv[0]) if argv else DEFAULT_DERIVATIONS
    if not final.is_dir():
        raise SystemExit(
            f'no derivations directory: {final}\n'
            'The run behind the answers currently marked derived read from a '
            'scratch directory that no longer exists, so it cannot be repeated. '
            'Use --record to write down what it established, or pass a '
            'directory of fresh votes to reconcile.'
        )

    computed = json.loads((SRC / 'bh_computed.json').read_text())

    a = {**load(final, 'A0.json'), **load(final, 'A1.json')}
    b = {**load(final, 'B0.json'), **load(final, 'B1.json')}
    items = json.loads((final / 'rem0.json').read_text()) \
        + json.loads((final / 'rem1.json').read_text())

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
    # Only when there is something to add. Rewriting it regardless meant a run
    # that established nothing still touched the key, which is the file every
    # answer in the app is built from — it should show in a diff when it has
    # changed, and not otherwise.
    if added:
        (SRC / 'bh_answers.json').write_text(
            json.dumps(answers, indent=1, sort_keys=True) + '\n'
        )
    print(f'\nadded {added} derived answers to the key')
    record_derived(answers)

    print(f'\nstill unresolved: {len(unresolved)}')
    for qid, prompt, s, va, vb in unresolved[:25]:
        print(f'  {qid}: {prompt[:56]!r}\n      solver={s} A={va} B={vb}')
    # Beside the sources it came from, not in /tmp, where the next run of this
    # script is what deletes it.
    (final / 'unresolved.json').write_text(
        json.dumps([u[:2] for u in unresolved], indent=1) + '\n')


if __name__ == '__main__':
    main()
