#!/usr/bin/env python3
"""Extract the Bryant Heath answer key from the PDF, column- and fraction-aware.

The Solutions chapter lays answers out in a 4-column grid of 'N. answer' cells.
Two shapes defeat a naive top-to-bottom text dump:

  * a stacked fraction (numerator and denominator on separate baselines) gets
    welded onto whatever the next column printed on the following line, and
  * an approximation range '(*) 1265 - 1400' is a band, not a single value.

So this reads positioned words and assigns each to a cell by (column, row).

Emits content_src/source/bryant_heath/bh_answers.json:
    {"1.2.3": {"1": {"type": "numeric", "answer": 6000}, ...}, ...}
"""
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

import fitz

SRC = Path(__file__).resolve().parent.parent / 'content_src/source/bryant_heath'
PDF = SRC / 'bryant_heath_tricks_manual.pdf'
OUT = SRC / 'bh_answers.json'

HEADING = re.compile(r'Problem Set ([\d.]+?):')
MARKER = re.compile(r'^(\d+)\.$')
# Column x-origins of the marker tokens, clustered from the observed layout.
COL_TOLERANCE = 40
# Rows of the answer grid are ~30pt apart; baselines inside one cell ~7pt.
STACK_GAP = 14
BASELINE_GAP = 3


def solutions_pages(doc):
    """Page indices of the Solutions chapter — everything from its title page on."""
    for i in range(doc.page_count):
        if doc[i].get_text().lstrip().startswith('5\nSolutions'):
            return range(i, doc.page_count)
    sys.exit('could not find the Solutions chapter')


def page_tokens(page):
    """Positioned tokens, taken from spans rather than get_text('words').

    The word layer does its own line grouping and will merge a mixed number's
    whole part with the numerator sitting on the baseline above it ('42' + '6'
    -> '426'), which silently changes the answer. Spans keep the baselines
    apart, so tokens are built from them instead.
    """
    out = []
    for block in page.get_text('dict')['blocks']:
        for line in block.get('lines', []):
            for span in line['spans']:
                x0, y0, x1, y1 = span['bbox']
                text = span['text']
                if not text.strip():
                    continue
                # Spread sub-tokens across the span's width so column
                # assignment still works for multi-word spans.
                width = (x1 - x0) / max(len(text), 1)
                pos = 0
                for part in text.split(' '):
                    if part:
                        out.append((x0 + pos * width, y0, x1, y1, part))
                    pos += len(part) + 1
    return out


def columns(markers):
    """Cluster marker x-positions into column origins."""
    xs = sorted(m[0] for m in markers)
    cols = []
    for x in xs:
        if not cols or x - cols[-1] > COL_TOLERANCE:
            cols.append(x)
    return cols


def cell_text(words):
    """Join a cell's words, flattening stacked fractions.

    Baselines within a cell carry meaning: a fraction puts numerator and
    denominator on their own baselines, and a mixed number adds the whole part
    on the middle one, to the left of the bar. So rows are clustered tightly —
    real baselines here sit only ~7pt apart.
    """
    if not words:
        return ''

    # A trailing unit sits on the middle baseline beside the whole part, which
    # would spoil the numeric row test. Lift it off and re-attach at the end.
    # A trailing unit rides on the whole part's baseline ('7%'), which would
    # spoil the numeric row test. Split it off and re-attach at the end.
    suffix = ''
    stripped = []
    for w in words:
        t = w[4]
        if len(t) > 1 and t[-1] in '%°':
            suffix = ' ' + t[-1]
            t = t[:-1]
        elif t in ('%', '°'):
            suffix = ' ' + t
            continue
        stripped.append((w[0], w[1], w[2], w[3], t))
    words = stripped

    # '2 √ 3' is a coefficient and a radicand straddling the radical sign,
    # not a stacked fraction.
    radical = next((w for w in words if '√' in w[4]), None)
    if radical:
        left = ''.join(w[4] for w in words if w[0] < radical[0])
        right = ''.join(w[4] for w in words if w[0] > radical[0] and w is not radical)
        return f'{left}sqrt({right}){suffix}'

    rows = defaultdict(list)
    for w in words:
        key = next((k for k in rows if abs(k - w[1]) < BASELINE_GAP), w[1])
        rows[key].append(w)
    ordered = [sorted(rows[k], key=lambda w: w[0]) for k in sorted(rows)]
    # The PDF uses a unicode minus; normalize before testing rows.
    def join(row):
        # Spans split a decimal point and a sign into their own tokens, so
        # whitespace around them is an artifact of extraction, not the layout.
        t = ' '.join(w[4] for w in row).replace('\u2212', '-').replace('\u2013', '-')
        t = re.sub(r'\s*\.\s*', '.', t)
        return re.sub(r'(^|\() *- +', r'\1-', t).strip()

    parts = [join(row) for row in ordered]
    numeric = [re.fullmatch(r'-?[\d.]+', p) for p in parts]

    if len(parts) == 2 and all(numeric):
        return f'{parts[0]}/{parts[1]}{suffix}'
    if len(parts) == 3 and parts[1] == '-':
        # A negative fraction puts the sign alone on the middle baseline,
        # where a mixed number would put its whole part.
        return f'-{parts[0]}/{parts[2]}{suffix}'
    if len(parts) == 3 and all(numeric):
        # numerator / whole / denominator, top to bottom
        return f'{parts[1]} {parts[0]}/{parts[2]}{suffix}'
    return ' '.join(parts) + suffix


def parse_page(page, carry=None):
    """-> ([(section, number, raw answer text)], last section seen).

    A problem set can begin near the foot of one page and continue onto the
    next, where its rows sit above that page's first heading. `carry` supplies
    the section those orphan rows belong to.
    """
    # Drop the running footer: its page number sits directly under the last
    # row and would otherwise read as a stacked fraction's denominator.
    footer = page.rect.height - 60
    words = [w for w in page_tokens(page) if w[1] < footer]
    if not words:
        return [], carry

    # Section headings, with the y they start applying at. Found by locating
    # the word 'Set' and reading the section number that follows it.
    heads = []
    for i, w in enumerate(words):
        if w[4] == 'Set' and i + 1 < len(words):
            sec = words[i + 1][4].rstrip(':').rstrip('.')
            if re.fullmatch(r'[\d.]+', sec):
                heads.append((w[1], sec))
    heads.sort()

    markers = [(w[0], w[1], MARKER.match(w[4]).group(1))
               for w in words if MARKER.match(w[4])]
    if not markers:
        return [], (heads[-1][1] if heads else carry)
    cols = columns(markers)

    # Bucket every non-marker word into its column.
    def col_of(x):
        best = None
        for c in cols:
            if x >= c - 2:
                best = c
        return best

    per_col = defaultdict(list)
    for m in markers:
        per_col[col_of(m[0])].append(m)

    # A cell also stops at the next section heading, which is otherwise the
    # nearest text below the final row of a column and gets absorbed into it.
    head_ys = [y for y, _ in heads]

    out = []
    for c, ms in per_col.items():
        ms.sort(key=lambda m: m[1])
        upper = c + COL_TOLERANCE * 3
        for j, (mx, my, num) in enumerate(ms):
            bottom = ms[j + 1][1] - STACK_GAP if j + 1 < len(ms) else 10 ** 6
            bottom = min([bottom] + [y - 2 for y in head_ys if y > my + 2])
            cell = [w for w in words
                    if mx < w[0] < upper and my - STACK_GAP <= w[1] < bottom
                    and not MARKER.match(w[4])]
            sec = [s for y, s in heads if y <= my + 2]
            owner = sec[-1] if sec else carry
            if owner is None:
                continue
            out.append((owner, int(num), cell_text(cell)))
    return out, (heads[-1][1] if heads else carry)


def classify(raw):
    """Map an answer string onto the app's question types."""
    s = raw.strip().replace(',', '').replace('−', '-').replace('–', '-')
    if not s:
        return None
    approx = s.startswith('(*)')
    if approx:
        s = s[3:].strip()
    # Any answer shape can carry a unit, not just a bare number.
    unit_suffix = None
    um = re.fullmatch(r'(.*?)\s*(%|°)', s)
    if um:
        s, unit_suffix = um.group(1).strip(), um.group(2)

    def tag(r):
        if r and unit_suffix:
            r['unit'] = unit_suffix
        return r
    m = re.fullmatch(r'(-?[\d.]+)\s*[-\s]\s*(-?[\d.]+)', s)
    if approx and m:
        return tag({'type': 'approx', 'low': float(m.group(1)), 'high': float(m.group(2))})
    unit = re.fullmatch(r'\$?(-?[\d.]+)\s*(%|[A-Za-z°]+\.?)?', s)
    if unit:
        v = float(unit.group(1))
        r = {'type': 'numeric', 'answer': int(v) if v == int(v) else v}
        if unit.group(2):
            r['unit'] = unit.group(2)
        return tag(r)
    # Fractions and mixed numbers keep a numeric value for grading and an
    # exact LaTeX form for display, so the app's num answer field still works.
    f = re.fullmatch(r'(-?\d+)/(\d+)', s)
    if f:
        n, dd = int(f.group(1)), int(f.group(2))
        sign = '-' if n < 0 else ''
        return tag({'type': 'numeric', 'answer': n / dd,
                    'display': f'{sign}\\frac{{{abs(n)}}}{{{dd}}}'})
    mx = re.fullmatch(r'(-?\d+)\s+(-?\d+)/(\d+)', s)
    if mx:
        wnum, n, dd = (int(g) for g in mx.groups())
        n = abs(n)
        sign = -1 if wnum < 0 else 1
        return tag({'type': 'numeric', 'answer': wnum + sign * n / dd,
                    'display': f'{wnum}\\frac{{{n}}}{{{dd}}}'})
    import math
    pi = re.fullmatch(r'(-?[\d.]*)\s*π\s*(%|°)?', s)
    if pi:
        k = float(pi.group(1)) if pi.group(1) not in ('', '-') else (-1.0 if pi.group(1) == '-' else 1.0)
        coeff = int(k) if k == int(k) else k
        return tag({'type': 'numeric', 'answer': k * math.pi, 'display': f'{coeff}\\pi'})
    sq = re.fullmatch(r'(-?[\d.]*)sqrt\((\d+)\)\s*(%|°)?', s)
    if sq:
        k = float(sq.group(1)) if sq.group(1) not in ('', '-') else (-1.0 if sq.group(1) == '-' else 1.0)
        rad = int(sq.group(2))
        coeff = int(k) if k == int(k) else k
        return tag({'type': 'numeric', 'answer': k * math.sqrt(rad),
                    'display': f'{coeff}\\sqrt{{{rad}}}'})
    return {'type': 'unparsed', 'raw': s}


def main():
    doc = fitz.open(PDF)
    answers = defaultdict(dict)
    carry = None
    for i in solutions_pages(doc):
        entries, carry = parse_page(doc[i], carry)
        for sec, num, raw in entries:
            c = classify(raw)
            if c:
                answers[sec][str(num)] = c

    OUT.write_text(json.dumps(answers, indent=1, sort_keys=True))
    total = sum(len(v) for v in answers.values())
    kinds = defaultdict(int)
    for v in answers.values():
        for a in v.values():
            kinds[a['type']] += 1
    print(f'{len(answers)} sections, {total} answers -> {OUT.name}')
    for k, n in sorted(kinds.items(), key=lambda x: -x[1]):
        print(f'  {n:5}  {k}')


if __name__ == '__main__':
    main()
