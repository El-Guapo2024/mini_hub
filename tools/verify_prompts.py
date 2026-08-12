#!/usr/bin/env python3
"""Check transcribed prompts by evaluating them against the extracted answers.

A prompt is only trusted if computing it reproduces the answer key. This turns
vision transcription into something measurable: a digit misread almost always
breaks the arithmetic.
"""
import json
import re
import sys
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / 'content_src/source/bryant_heath'


def to_python(tex):
    s = tex
    s = re.sub(r'^\(\*\)', '', s).strip()
    s = s.rstrip('=').strip()
    if '=' in s:                      # equations, not evaluable expressions
        return None
    for _ in range(4):                # nested fractions
        s = re.sub(r'\\d?frac\{([^{}]+)\}\{([^{}]+)\}', r'((\1)/(\2))', s)
    s = s.replace('\\times', '*').replace('\\cdot', '*').replace('\\div', '/')
    s = re.sub(r'\\sqrt\{([^{}]+)\}', r'((\1)**0.5)', s)
    s = s.replace('\\left', '').replace('\\right', '')
    s = s.replace('\\pi', 'pi').replace('\\%', '%')
    s = re.sub(r'\^\{([^{}]+)\}', r'**(\1)', s)
    s = re.sub(r'\^(\d+)', r'**\1', s)
    # The whole number carries the percent, not just its last digit: '62.5%'
    # must become (62.5/100), never 62.(5/100).
    s = re.sub(r'(\d*\.?\d+)\s*\\?%', r'(\1/100)', s)
    s = s.replace('−', '-').replace('–', '-').replace(',', '')
    # '4\frac{1}{8}' is a mixed number, not a product — and it must be
    # parenthesised or the surrounding multiplication outranks the addition.
    s = re.sub(r'(\d+)\s*\(\((.+?)\)\)', r'(\1+((\2)))', s)
    # Implicit multiplication: '(18+16)(9+16)' and '2(3+4)'.
    s = re.sub(r'\)\s*\(', ')*(', s)
    s = re.sub(r'(\d)\s*\(', r'\1*(', s)
    if re.search(r'[a-zA-Z\\]', s.replace('pi', '')):
        return None
    return s


def value(expr):
    import math
    try:
        v = eval(expr, {'__builtins__': {}}, {'pi': math.pi})
        return v if isinstance(v, (int, float)) else None
    except Exception:
        return None


def main(paths):
    answers = json.loads((SRC / 'bh_answers.json').read_text())
    ok = bad = skipped = nokey = 0
    mismatches = []
    for p in paths:
        data = json.loads(Path(p).read_text())
        for sec, items in data.items():
            if sec.startswith('CONTINUATION'):
                continue
            for n, tex in items.items():
                a = answers.get(sec, {}).get(n)
                if not a:
                    nokey += 1
                    continue
                expr = to_python(tex)
                if expr is None:
                    skipped += 1
                    continue
                v = value(expr)
                if v is None:
                    skipped += 1
                    continue
                if a['type'] == 'approx':
                    good = a['low'] * 0.98 <= v <= a['high'] * 1.02
                else:
                    target = a['answer']
                    if a.get('unit') == '%':
                        good = abs(v - target) < 0.02 or abs(v * 100 - target) < 0.02
                    else:
                        good = abs(v - target) <= max(1e-6, abs(target) * 1e-9)
                if good:
                    ok += 1
                else:
                    bad += 1
                    if len(mismatches) < 15:
                        mismatches.append((sec, n, tex, round(v, 4),
                                           a.get('answer', (a.get('low'), a.get('high')))))
    total = ok + bad
    rate = (ok / total * 100) if total else 0
    print(f'verifiable {total}: match {ok} ({rate:.1f}%), mismatch {bad}')
    print(f'not evaluable (words/equations) {skipped}, no answer key {nokey}')
    for m in mismatches:
        print(f'  {m[0]} #{m[1]}: {m[2]!r} -> {m[3]}  key={m[4]}')


if __name__ == '__main__':
    main(sys.argv[1:])
