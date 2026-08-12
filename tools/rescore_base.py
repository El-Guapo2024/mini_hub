#!/usr/bin/env python3
"""Re-score the 'express the fraction in base N' sections.

Problem Set 4.5.4 asks for a fraction written in the same base as the question,
so the key prints '31/50' meaning 31_6/50_6 = 19/30. The answer extractor read
those digits as base 10 and produced 0.62, which then disagreed with every
correctly computed value. Reinterpreting the key's digits in the prompt's base
is what makes the comparison meaningful.
"""
import json
import re
from fractions import Fraction
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / 'content_src/source/bryant_heath'


def base_of(prompt):
    """The base the answer is requested in, or None."""
    m = re.search(r'base-(\d+)\s+fraction', prompt)
    if m:
        return int(m.group(1))
    return None


def digits_in_base(text, b):
    try:
        return int(str(text), b)
    except ValueError:
        return None


def main():
    answers = json.loads((SRC / 'bh_answers.json').read_text())
    prompts = json.loads((SRC / 'bh_prompts_vlm.json').read_text())
    solved = json.loads((SRC / 'bh_solved.json').read_text())

    fixed = agreed = still = 0
    for sec in ('4.5.4',):
        for n, rec in sorted(answers.get(sec, {}).items(), key=lambda kv: int(kv[0])):
            prompt = prompts.get(sec, {}).get(n, '')
            b = base_of(prompt)
            disp = rec.get('display', '')
            m = re.fullmatch(r'\\frac\{(\d+)\}\{(\d+)\}', str(disp))
            if not (b and m):
                continue
            num = digits_in_base(m.group(1), b)
            den = digits_in_base(m.group(2), b)
            if num is None or den is None or not den:
                continue
            true_value = float(Fraction(num, den))
            fixed += 1

            # Rewrite the key in place: keep the printed base-N form for
            # display, but store the value the app must grade against.
            rec['answer'] = true_value
            rec['display'] = f'\\frac{{{m.group(1)}}}{{{m.group(2)}}}_{{{b}}}'
            rec['base'] = b

            got = solved.get(sec, {}).get(n)
            if got is not None:
                if abs(got['value'] - true_value) < 1e-6:
                    got['status'] = 'confirmed'
                    agreed += 1
                else:
                    still += 1
                    print(f'  {sec} #{n}: {prompt[:48]!r}\n'
                          f'      agent={got["value"]}  key(base {b})={true_value}')

    (SRC / 'bh_answers.json').write_text(json.dumps(answers, indent=1, sort_keys=True))
    (SRC / 'bh_solved.json').write_text(json.dumps(solved, indent=1, sort_keys=True))
    print(f'reinterpreted {fixed} keys; now agreeing {agreed}, still disputed {still}')


if __name__ == '__main__':
    main()
