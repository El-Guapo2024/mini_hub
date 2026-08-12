#!/usr/bin/env python3
"""Extract Bryant Heath problem-set prompts from the PDF as LaTeX.

Problem sets are a two-column grid of 'N. <expression> =' items. Reconstructing
the expression needs three things a flat text dump throws away:

  * font size + baseline, to tell an exponent from a factor (58 vs 58^2),
  * the drawn rules, which are the fraction bars, and
  * column geometry, so the right-hand column doesn't interleave.

Emits content_src/source/bryant_heath/bh_prompts.json:
    {"1.2.9": {"1": "58^{2} =", ...}, ...}
"""
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

import fitz

SRC = Path(__file__).resolve().parent.parent / 'content_src/source/bryant_heath'
PDF = SRC / 'bryant_heath_tricks_manual.pdf'
OUT = SRC / 'bh_prompts.json'

MARKER = re.compile(r'^(\d+)\.$')
COL_GAP = 120        # columns sit ~240pt apart; anything closer is one column
ROW_GAP = 6          # baselines within a row of the same size
SUP_DROP = 2.0       # a raised token clears the baseline by at least this much

SYMBOLS = {
    '×': r'\times', '÷': r'\div', '−': '-', '–': '-', '·': r'\cdot',
    '≈': r'\approx', '≤': r'\le', '≥': r'\ge', '≠': r'\ne', '±': r'\pm',
    '√': r'\sqrt', 'π': r'\pi', '°': r'^{\circ}', '∞': r'\infty',
    '⇒': r'\Rightarrow', '→': r'\to', '∑': r'\sum', '∈': r'\in',
}


def tokens(page):
    """Positioned tokens carrying font size, built from spans."""
    out = []
    for block in page.get_text('dict')['blocks']:
        for line in block.get('lines', []):
            for span in line['spans']:
                x0, y0, x1, y1 = span['bbox']
                text = span['text']
                if not text.strip():
                    continue
                width = (x1 - x0) / max(len(text), 1)
                pos = 0
                for part in text.split(' '):
                    if part:
                        out.append({'x': x0 + pos * width, 'y': y0, 'y1': y1,
                                    'size': span['size'], 'text': part})
                    pos += len(part) + 1
    return out


def rules(page):
    """Horizontal drawn lines — the fraction bars."""
    bars = []
    for d in page.get_drawings():
        r = d['rect']
        if r.width > 2 and r.height < 1.5:
            bars.append((r.x0, r.x1, r.y0))
    return bars


def latex(tok):
    t = tok['text']
    for k, v in SYMBOLS.items():
        t = t.replace(k, v)
    return t


def render(items, bars, base_size):
    """Turn one item's tokens into a LaTeX string."""
    if not items:
        return ''
    items = sorted(items, key=lambda t: t['x'])
    baseline = max(t['y'] for t in items if abs(t['size'] - base_size) < 0.6) \
        if any(abs(t['size'] - base_size) < 0.6 for t in items) else \
        max(t['y'] for t in items)

    # Fraction bars owning this item: tokens above the bar are the numerator,
    # below it the denominator.
    used = set()
    parts = []
    for x0, x1, y in bars:
        # A numerator/denominator hugs its bar; anything further off belongs to
        # a neighbouring term (the whole part of a mixed number, typically).
        num = [t for t in items if x0 - 2 <= t['x'] <= x1 + 2 and y - 13 < t['y'] < y - 1]
        den = [t for t in items if x0 - 2 <= t['x'] <= x1 + 2 and y < t['y'] < y + 13]
        if num and den:
            for t in num + den:
                used.add(id(t))
            n = ''.join(latex(t) for t in sorted(num, key=lambda t: t['x']))
            d = ''.join(latex(t) for t in sorted(den, key=lambda t: t['x']))
            parts.append((x0, rf'\frac{{{n}}}{{{d}}}'))

    for t in items:
        if id(t) in used:
            continue
        s = latex(t)
        if t['size'] < base_size - 0.5 and t['y'] < baseline - SUP_DROP:
            s = f'^{{{s}}}'
        elif t['size'] < base_size - 0.5 and t['y'] > baseline + SUP_DROP:
            s = f'_{{{s}}}'
        parts.append((t['x'], s))

    parts.sort()
    out = ''
    for _, s in parts:
        if out and not s.startswith(('^', '_')) and not out.endswith(' '):
            out += ' '
        out += s
    out = re.sub(r'\s+', ' ', out).strip()
    # Spans split a decimal point into its own token.
    return re.sub(r'(\d) \. (\d)', r'\1.\2', out)


def parse_page(page, carry=None):
    footer = page.rect.height - 60
    ts = [t for t in tokens(page) if t['y'] < footer]
    if not ts:
        return [], carry

    heads = []
    for i, t in enumerate(ts):
        if t['text'] == 'Set' and i + 1 < len(ts):
            sec = ts[i + 1]['text'].rstrip(':').rstrip('.')
            if re.fullmatch(r'[\d.]+', sec):
                heads.append((t['y'], sec))
    heads.sort()

    # Body prose starts at the left margin; list items are indented. Drop any
    # line that begins left of the indent, so lesson text around a problem set
    # never bleeds into an item's cell.
    lines = defaultdict(list)
    for t in ts:
        key = next((k for k in lines if abs(k - t['y']) < ROW_GAP), t['y'])
        lines[key].append(t)
    prose_rows = [k for k, row in lines.items() if min(x['x'] for x in row) < 80]
    prose = {id(t) for k in prose_rows for t in lines[k]}
    ts = [t for t in ts if id(t) not in prose]
    if not ts:
        return [], carry

    base_size = max((t['size'] for t in ts), default=10)
    bars = rules(page)

    # A problem set runs from its heading until body prose resumes. Without
    # that bound, a lesson's own numbered steps read as problem items.
    start = heads[0][0] if heads else -1
    stop = min([y for y in prose_rows if y > start + 12], default=10 ** 6)

    marks = [t for t in ts if MARKER.match(t['text']) and start < t['y'] < stop]
    if not marks:
        return [], (heads[-1][1] if heads else carry)

    # Cluster marker x into columns.
    cols = []
    for x in sorted(t['x'] for t in marks):
        if not cols or x - cols[-1] > COL_GAP:
            cols.append(x)

    per_col = defaultdict(list)
    for m in marks:
        c = max([c for c in cols if m['x'] >= c - 2], default=cols[0])
        per_col[c].append(m)

    head_ys = [y for y, _ in heads]
    out = []
    for ci, (c, ms) in enumerate(sorted(per_col.items())):
        right = min([o for o in cols if o > c + 1], default=10 ** 6)
        ms.sort(key=lambda m: m['y'])
        for j, m in enumerate(ms):
            top = m['y'] - 14
            bottom = ms[j + 1]['y'] - 14 if j + 1 < len(ms) else 10 ** 6
            bottom = min([bottom] + [y - 2 for y in head_ys if y > m['y'] + 2])
            cell = [t for t in ts
                    if c - 2 < t['x'] < right - 2 and top <= t['y'] < bottom
                    and not (MARKER.match(t['text']) and abs(t['y'] - m['y']) < ROW_GAP
                             and abs(t['x'] - m['x']) < 2)]
            sec = [s for y, s in heads if y <= m['y'] + 2]
            owner = sec[-1] if sec else carry
            if owner is None:
                continue
            out.append((owner, int(MARKER.match(m['text']).group(1)),
                        render(cell, bars, base_size)))
    return out, (heads[-1][1] if heads else carry)


def problem_pages(doc):
    """Everything before the Solutions chapter."""
    for i in range(doc.page_count):
        if doc[i].get_text().lstrip().startswith('5\nSolutions'):
            return range(i)
    sys.exit('could not find the Solutions chapter')


def main():
    doc = fitz.open(PDF)
    prompts = defaultdict(dict)
    carry = None
    for i in problem_pages(doc):
        entries, carry = parse_page(doc[i], carry)
        for sec, num, text in entries:
            if text:
                prompts[sec][str(num)] = text

    OUT.write_text(json.dumps(prompts, indent=1, sort_keys=True))
    total = sum(len(v) for v in prompts.values())
    print(f'{len(prompts)} sections, {total} prompts -> {OUT.name}')


if __name__ == '__main__':
    main()
