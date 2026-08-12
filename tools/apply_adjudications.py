#!/usr/bin/env python3
"""Apply the source-verified corrections to the answer key and prompts.

Every change here was adjudicated against the printed page, not inferred. Each
carries a `note` recording why it differs from what the book prints, so a later
reader can tell a repair from an extraction.

The big one is Problem Set 2.1.1, whose printed key contains three spurious
entries (at printed positions 10, 15 and 21). They displace the remaining
answers in a staircase: +1 after the first, +2 after the second, +3 after the
third. Removing them and realigning makes all 40 problems verify.
"""
import json
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / 'content_src/source/bryant_heath'

# The book prints a wrong answer; the computed value was verified from source.
KEY_WRONG = {
    ('4.4.5', '2'): (1.0, 'point-to-line distance; key prints 1.4'),
    ('4.4.5', '5'): (0.4, 'point-to-line distance; key prints 0.2'),
    ('4.4.5', '8'): (2.0, 'point-to-line distance; key prints 0.4'),
    ('2.2.14', '3'): (-0.5, 'axis of symmetry of 2-x-x^2; key prints 1.25'),
    ('2.2.15', '4'): (17.0, 'discriminant; key prints sqrt(17) instead'),
    ('4.2.3', '3'): (5.3, 'asks to truncate; key rounds to 5.4'),
    ('3.6.1', '7'): (-3.0, 'limit is -3; key prints 0'),
    ('4.3.1', '2'): (143.0, 'Fibonacci sum; key prints 133'),
    ('4.3.2', '14'): (264.0, 'Fibonacci-like sum; key prints 162'),
    ('2.2.2', '6'): (608.0, 'Fibonacci sum; key prints 610'),
    ('4.5.2', '8'): (2151.0, 'asks for four digits; key prints five (21515)'),
    ('3.3.4', '4'): (151 / 495, 'key prints denominator 494, a typo for 495'),
    # The book defines a proper divisor as excluding the number itself two
    # pages earlier, so its own 39 contradicts its definition.
    ('2.2.3', '28'): (21.0, 'proper divisors of 18 exclude 18; key prints 39'),
}

# Our computation was wrong; the book is right.
COMPUTED_WRONG = {
    ('2.2.3', '32'): 7.0,
    ('2.2.3', '34'): 7.0,
    ('3.1.12', '1'): 17.0,
}

# Estimation ranges the answer extractor failed to read as a band.
RANGES = {
    ('1.2.5', '73'): (50805, 56154),
    ('1.2.5', '75'): (12324, 13622),
    ('1.2.5', '78'): (21855, 24157),
}

# The transcription misread the repeating block.
PROMPT_FIX = {
    ('3.3.4', '10'): (r'.2\overline{14} =', 106 / 495),
}

SPURIOUS_2_1_1 = {10, 15, 21}


def repair_2_1_1(answers):
    """Drop the three inserted entries and shift the rest back into place."""
    sec = answers['2.1.1']
    kept = [sec[str(i)] for i in sorted(int(n) for n in sec)
            if i not in SPURIOUS_2_1_1]
    repaired = {}
    for pos, rec in enumerate(kept, start=1):
        rec = dict(rec)
        rec['note'] = ('realigned: the printed key inserts spurious entries at '
                       'positions 10, 15 and 21, displacing the rest')
        repaired[str(pos)] = rec
    answers['2.1.1'] = repaired
    return len(repaired)


def main():
    answers = json.loads((SRC / 'bh_answers.json').read_text())
    prompts = json.loads((SRC / 'bh_prompts_vlm.json').read_text())

    n = repair_2_1_1(answers)
    print(f'2.1.1 repaired: {n} answers realigned')

    for (sec, num), (val, why) in KEY_WRONG.items():
        answers.setdefault(sec, {})[num] = {
            'type': 'numeric', 'answer': val, 'corrected': True, 'note': why}
    for (sec, num), val in COMPUTED_WRONG.items():
        answers.setdefault(sec, {})[num] = {'type': 'numeric', 'answer': val}
    for (sec, num), (lo, hi) in RANGES.items():
        answers.setdefault(sec, {})[num] = {'type': 'approx', 'low': lo, 'high': hi}
    for (sec, num), (text, val) in PROMPT_FIX.items():
        prompts[sec][num] = text
        answers.setdefault(sec, {})[num] = {
            'type': 'numeric', 'answer': val, 'corrected': True,
            'note': 'prompt re-read from source; repeating block is 14, not 41'}

    (SRC / 'bh_answers.json').write_text(json.dumps(answers, indent=1, sort_keys=True))
    (SRC / 'bh_prompts_vlm.json').write_text(json.dumps(prompts, indent=1, sort_keys=True))
    print(f'applied {len(KEY_WRONG)} key corrections, '
          f'{len(COMPUTED_WRONG)} computation corrections, '
          f'{len(RANGES)} ranges, {len(PROMPT_FIX)} prompt fixes')


if __name__ == '__main__':
    main()
