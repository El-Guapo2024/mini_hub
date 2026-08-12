#!/usr/bin/env python3
"""Run every solver stage over the transcribed prompts and score against the key.

Stages, in order of how much machinery they need:
  1. verify_prompts.to_python  — closed arithmetic expressions
  2. solve_prompts.solve       — regex-shaped families (remainders, LCM, roman)
  3. solve_sympy.solve         — symbolic: logs, trig, integrals, series, units

A prompt counts as confirmed only when an independent computation reproduces the
book's answer. Mismatches are printed per section so a cluster (a misprinted key)
is distinguishable from a scattered few (a bad rule or a bad transcription).
"""
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from verify_prompts import to_python, value          # noqa: E402
import solve_prompts                                  # noqa: E402
import solve_sympy                                    # noqa: E402

SRC = Path(__file__).resolve().parent.parent / 'content_src/source/bryant_heath'


def compute(tex):
    """-> (value, stage) from the first solver that produces one."""
    e = to_python(tex)
    if e is not None:
        v = value(e)
        if v is not None:
            return v, 'arithmetic'
    try:
        v, tag = solve_prompts.solve(tex)
    except Exception:
        v, tag = None, None
    if v is not None:
        return v, tag
    try:
        v, tag = solve_sympy.solve(tex)
    except Exception:
        v, tag = None, None
    if v is not None:
        return v, tag
    return None, None


def agrees(v, a):
    if a['type'] == 'approx':
        return a['low'] * 0.98 <= v <= a['high'] * 1.02
    if 'answer' not in a:        # the two answers the key extractor left raw
        return None
    t = a['answer']
    tol = max(1e-6, abs(t) * 1e-6)
    # A percent answer may be keyed as either 7 or .07; a rounded key ('nearest
    # whole number') is allowed one unit of slack only when it is an integer.
    if abs(v - t) <= tol or abs(v * 100 - t) <= tol or abs(v - t * 100) <= tol:
        return True
    return t == int(t) and abs(round(v) - t) <= tol


def main(paths):
    answers = json.loads((SRC / 'bh_answers.json').read_text())
    ok = bad = unsolved = nokey = 0
    stages = Counter()
    per_section_bad = defaultdict(list)
    unsolved_rows = []
    computed = defaultdict(dict)

    for p in paths:
        data = json.loads(Path(p).read_text())
        for sec, items in sorted(data.items()):
            if sec.startswith('CONTINUATION'):
                continue
            for n, tex in sorted(items.items(), key=lambda kv: int(kv[0])):
                v, stage = compute(tex)
                a = answers.get(sec, {}).get(n)
                if v is not None:
                    computed[sec][n] = v
                if not a:
                    nokey += 1
                    continue
                if v is None:
                    unsolved += 1
                    if len(unsolved_rows) < 4000:
                        unsolved_rows.append(f'{sec}#{n}: {tex}')
                    continue
                stages[stage] += 1
                verdict = agrees(v, a)
                if verdict is None:
                    unsolved += 1
                    stages[stage] -= 1
                    continue
                if verdict:
                    ok += 1
                else:
                    bad += 1
                    per_section_bad[sec].append((n, tex, round(v, 4), a.get('answer')))

    total = ok + bad
    print(f'confirmed  {ok}')
    print(f'mismatch   {bad}')
    print(f'unsolved   {unsolved}')
    print(f'no key     {nokey}')
    if total:
        print(f'agreement  {ok / total * 100:.1f}%  of {total} computed')
    print('\nby stage:')
    for k, c in stages.most_common():
        print(f'  {c:5}  {k}')
    print('\nmismatch clusters (section: count):')
    for sec, rows in sorted(per_section_bad.items(), key=lambda kv: -len(kv[1])):
        print(f'  {sec:10} {len(rows):3}')

    (SRC / 'bh_computed.json').write_text(json.dumps(computed, indent=1, sort_keys=True))
    Path('/tmp/unsolved.txt').write_text('\n'.join(unsolved_rows))
    dbg = Path(__file__).resolve().parent.parent / 'bh_mismatches.json'
    dbg.write_text(json.dumps({k: v for k, v in per_section_bad.items()}, indent=1))
    print(f'\nwrote bh_computed.json ({sum(len(v) for v in computed.values())} values)')


if __name__ == '__main__':
    main(sys.argv[1:])
