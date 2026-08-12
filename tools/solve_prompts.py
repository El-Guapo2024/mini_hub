#!/usr/bin/env python3
"""Second-stage verifier: solve the prompt shapes a bare expression evaluator skips.

verify_prompts.py only handles items that are already a closed expression. Most
of what it rejected is still mechanically solvable:

  * fill-in-the-blank conversions   1/40 = ___ %        -> evaluate the LHS
  * solve-for-the-blank equations   33.75 = 1.5 x ___   -> divide
  * function evaluation             f(x) = 9x^2-12x+4, f(19) =
  * 'A% of B'                       11% of 22 =
  * geometry one-liners             area/perimeter of a square, area of a rectangle

Anything still unsolved is reported by shape so the residue can be judged rather
than assumed correct.
"""
import json
import math
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from verify_prompts import to_python, value  # noqa: E402

SRC = Path(__file__).resolve().parent.parent / 'content_src/source/bryant_heath'

BLANK = re.compile(r'_{2,}|\\_{2,}|\\rule\{[^}]*\}\{[^}]*\}')


def num(s):
    """Parse a captured number, dropping a sentence-final period."""
    return float(s.rstrip('.'))


def strip_tail(s):
    """Drop the trailing unit/format hint: '= ___ % (dec.)' and friends."""
    s = BLANK.sub(' BLANK ', s)
    s = re.sub(r'\\text\{([^{}]*)\}', r' \1 ', s)
    s = re.sub(r'\\(?:mbox|mathrm)\{([^{}]*)\}', r' \1 ', s)
    return re.sub(r'\s+', ' ', s).strip()


def as_percent_target(a):
    """The key's numeric value, in the units the prompt asks for."""
    return a['answer']


ROMAN = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}


def from_roman(t):
    total = 0
    for i, ch in enumerate(t):
        v = ROMAN[ch]
        total += -v if i + 1 < len(t) and ROMAN[t[i + 1]] > v else v
    return total


def in_base(digits, b):
    """'123' in base b, with an optional fractional part."""
    whole, _, frac = digits.partition('.')
    v = 0
    for ch in whole:
        v = v * b + int(ch, 36)
    for i, ch in enumerate(frac, 1):
        v += int(ch, 36) / b ** i
    return v


def domain_rules(s):
    """Families that are uniform enough to solve exactly."""
    # Remainders: 'N div D has a remainder of' / 'has what remainder'.
    m = re.search(r'([\d,]+)\s*(?:\\div|/)\s*([\d,]+).*remainder', s, re.I)
    if m:
        n, d = (int(g.replace(',', '')) for g in m.groups())
        if d:
            return n % d, 'remainder'

    # LCM / GCD over an arbitrary list, whose members may themselves be
    # expressions ('2^3 x 3^2'), and which may sit inside further arithmetic
    # ('GCF(24,44) - LCM(24,44)'). Each call is reduced to its value and
    # substituted, then whatever remains is evaluated.
    if re.search(r'\b(LCM|GCD|GCF)\b', s, re.I):
        call = re.compile(r'\b(?:the\s+)?(LCM|GCD|GCF)\b\s*'
                          r'(?:\(([^()]*)\)|of\s+([^=:]+?)\s*(?=is\b|=|$))', re.I)

        def reduce_call(m):
            kind = m.group(1).upper()
            body = m.group(2) if m.group(2) is not None else m.group(3)
            terms = [t for t in re.split(r',|\band\b', body) if t.strip()]
            vals = []
            for t in terms:
                e = to_python(t.strip())
                v = value(e) if e is not None else None
                if v is None or v != int(v):
                    return None
                vals.append(int(v))
            if not vals:
                return None
            return str(math.lcm(*vals) if kind == 'LCM' else math.gcd(*vals))

        out, pos, failed = '', 0, False
        for m in call.finditer(s):
            r = reduce_call(m)
            if r is None:
                failed = True
                break
            out += s[pos:m.start()] + r
            pos = m.end()
        if not failed and pos:
            rest = s[pos:]
            # 'product of the GCF and LCM' words the multiplication out.
            tail = re.sub(r'\b(is|are|equals?)\b|[:=?]', ' ', rest)
            expr = to_python((out + tail).strip())
            if re.search(r'\bproduct\b', s, re.I) and len(re.findall(r'\d+', out)) == 2:
                a_, b_ = (int(x) for x in re.findall(r'\d+', out))
                return a_ * b_, 'lcm-gcd'
            if expr is not None:
                v = value(expr)
                if v is not None:
                    return v, 'lcm-gcd'

    # Roman numerals, including sums of them.
    if (re.search(r'\b[IVXLCDM]{2,}\b', s) and not re.search(r'[a-z]{3}', s)
            and not re.search(r'\b(LCM|GCD|GCF)\b', s, re.I)):
        parts = re.findall(r'\b[IVXLCDM]+\b', s)
        if parts and all(set(p) <= set(ROMAN) for p in parts):
            ops = re.findall(r'[+\-]', s)
            total = from_roman(parts[0])
            for op, p in zip(ops, parts[1:]):
                total += from_roman(p) if op == '+' else -from_roman(p)
            return total, 'roman'

    # 'N is ___ % of M' and '32 is 2 1/2 % of ___'.
    m = re.match(r'\s*([\d.]+)\s+is\s+BLANK\s*\\?%\s*of\s*([\d.]+)', s, re.I)
    if m:
        return num(m.group(1)) / num(m.group(2)) * 100, 'is-what-percent'
    m = re.match(r'\s*([\d.]+)\s+is\s+(.+?)\s*\\?%\s*of\b\s*(BLANK|:)?\s*$', s, re.I)
    if m:
        pe = to_python(m.group(2))
        pv = value(pe) if pe is not None else None
        if pv:
            return num(m.group(1)) / (pv / 100), 'percent-of-what'
    return None, None


def solve(tex):
    """-> (value, how) or (None, None)."""
    s = strip_tail(tex)

    v, tag = domain_rules(s)
    if v is not None:
        return v, tag

    # 'f(x) = <poly>, f(19) =' — substitute and evaluate.
    m = re.match(r'\s*f\(x\)\s*=\s*(.+?),?\s*f\((-?[\d.]+)\)\s*=?\s*$', s)
    if m:
        body, x = m.group(1), m.group(2)
        expr = to_python(body.replace('x', f'({x})'))
        if expr is not None:
            v = value(expr)
            if v is not None:
                return v, 'function'

    # 'A % of B' (also 'A of B' where A carries the percent sign).
    m = re.match(r'\s*(.+?)\s*\\?%\s*\bof\b\s*([\d.]+)\s*(.*)$', s)
    if m:
        le, re_ = to_python(re.sub(r'\\?%', '', m.group(1))), to_python(m.group(2))
        if le is not None and re_ is not None:
            lv, rv = value(le), value(re_)
            if lv is not None and rv is not None:
                # A trailing term stays outside the 'of': '45% of 45 - 45'.
                tail = m.group(3).strip().rstrip('=').strip()
                if not tail:
                    return lv / 100 * rv, 'percent-of'
                te = to_python(f'0 {tail}')
                tv = value(te) if te is not None else None
                if tv is not None:
                    return lv / 100 * rv + tv, 'percent-of'

    # Squares: 'A square has an area of N ... perimeter is' and the converse.
    m = re.search(r'square .*? area of ([\d.]+)', s, re.I)
    if m and re.search(r'perimeter', s, re.I):
        return 4 * math.sqrt(num(m.group(1))), 'square-area->perim'
    m = re.search(r'square .*? perimeter of ([\d.]+)', s, re.I)
    if m and re.search(r'area', s, re.I):
        return (num(m.group(1)) / 4) ** 2, 'square-perim->area'
    m = re.search(r'rectangle .*? length of ([\d.]+) .*? width of ([\d.]+)', s, re.I)
    if m:
        l, w = num(m.group(1)), num(m.group(2))
        if re.search(r'\barea\b', s, re.I):
            return l * w, 'rect-area'
        if re.search(r'perimeter', s, re.I):
            return 2 * (l + w), 'rect-perim'

    # Equations. Split on the top-level '=' and solve whichever side is blank.
    if s.count('=') == 1:
        lhs, rhs = (p.strip() for p in s.split('='))
        rhs_blank = not rhs or 'BLANK' in rhs
        lhs_blank = not lhs or 'BLANK' in lhs
        # The blank may carry a format hint: '= ___ % (dec.)' is still bare.
        def bare(t):
            t = re.sub(r'\\(dec\\.?\\)|\\\\?%|\\(fraction\\)|BLANK|[:.]', ' ', t)
            return not t.strip()
        if rhs_blank and not lhs_blank and bare(rhs):
            expr = to_python(lhs)
            if expr is not None:
                v = value(expr)
                if v is not None:
                    return v, 'evaluate-lhs'
        # '33.75 = 1.5 x ___' -> the blank is a factor on the right.
        if rhs_blank or lhs_blank:
            known, other = (lhs, rhs) if rhs_blank else (rhs, lhs)
            m = re.match(r'^(.*?)\s*(\\times|\*|\\cdot)\s*(BLANK)?\s*$', other)
            if m and m.group(1).strip():
                ke, fe = to_python(known), to_python(m.group(1))
                if ke is not None and fe is not None:
                    kv, fv = value(ke), value(fe)
                    if kv is not None and fv not in (None, 0):
                        return kv / fv, 'solve-factor'
    return None, None


def shape(tex):
    """A coarse bucket for the unsolved residue, so it can be triaged."""
    s = strip_tail(tex).lower()
    for key in ('which is', 'how many', 'if ', 'find', 'what', 'the sum',
                'triangle', 'circle', 'square', 'rectangle', 'remainder',
                'gcd', 'lcm', 'set ', 'roman', 'base'):
        if key in s:
            return key.strip()
    return 'other'


def main(paths):
    answers = json.loads((SRC / 'bh_answers.json').read_text())
    prev_ok = solved_ok = solved_bad = residue = nokey = 0
    how = Counter()
    bad = []
    shapes = defaultdict(list)

    for p in paths:
        data = json.loads(Path(p).read_text())
        for sec, items in sorted(data.items()):
            if sec.startswith('CONTINUATION'):
                continue
            for n, tex in sorted(items.items(), key=lambda kv: int(kv[0])):
                a = answers.get(sec, {}).get(n)
                if not a:
                    nokey += 1
                    continue
                expr = to_python(tex)
                if expr is not None and value(expr) is not None:
                    prev_ok += 1
                    continue

                v, tag = solve(tex)
                if v is None:
                    residue += 1
                    shapes[shape(tex)].append(f'{sec}#{n}: {tex[:70]}')
                    continue

                how[tag] += 1
                if a['type'] == 'approx':
                    good = a['low'] * 0.98 <= v <= a['high'] * 1.02
                else:
                    t = as_percent_target(a)
                    good = (abs(v - t) <= max(1e-6, abs(t) * 1e-6)
                            or abs(v * 100 - t) <= max(1e-6, abs(t) * 1e-6)
                            or abs(v - t * 100) <= max(1e-6, abs(t) * 1e-6))
                if good:
                    solved_ok += 1
                else:
                    solved_bad += 1
                    if len(bad) < 20:
                        bad.append((sec, n, tex, round(v, 4), a.get('answer')))

    print(f'already covered by verify_prompts : {prev_ok}')
    print(f'newly solved                      : {solved_ok + solved_bad}'
          f'  (match {solved_ok}, mismatch {solved_bad})')
    print(f'still unsolved                    : {residue}')
    print(f'no answer key                     : {nokey}')
    print('\nby method:')
    for k, c in how.most_common():
        print(f'  {c:5}  {k}')
    print('\nmismatches:')
    for m in bad:
        print(f'  {m[0]} #{m[1]}: {m[2]!r} -> {m[3]}  key={m[4]}')
    print('\nunsolved residue by shape:')
    for k, v in sorted(shapes.items(), key=lambda kv: -len(kv[1])):
        print(f'  {len(v):5}  {k}')
        for s in v[:3]:
            print(f'           {s}')


if __name__ == '__main__':
    main(sys.argv[1:])
