#!/usr/bin/env python3
"""Third-stage solver: symbolic evaluation for the long tail.

solve_prompts.py handles the families that fall to a regex. What is left is
actual mathematics — logarithms, trigonometry, definite integrals, radicals,
exponential equations, series, base and unit conversion. Those need a CAS, not
another pattern.

Two mechanisms cover most of it:

  * latex_to_sympy() translates a prompt into a sympy expression, so anything
    that is a closed form just evaluates, and
  * an equation with exactly one free symbol is solved for it.

Everything else is a domain rule with an explicit table.
"""
import re

import sympy as sp

GREEK = {'pi': sp.pi}


def _degrees(s):
    """'30^{\\circ}' inside a trig call is degrees, not radians."""
    return re.sub(r'([\d.]+)\s*\^?\{?\\circ\}?', r'(\1*pi/180)', s)


def latex_to_sympy(tex):
    """Translate a prompt's LaTeX into a sympy-parsable string, or None."""
    s = tex.strip()
    s = re.sub(r'^\(\*\)', '', s).strip()          # approximation marker
    s = s.rstrip('=').strip().rstrip(':').strip()
    s = s.replace('\\left', '').replace('\\right', '')
    s = re.sub(r'\\[,;!]|\\quad|\\qquad', ' ', s)
    s = re.sub(r'(?<=\d),(?=\d{3}\b)', '', s)
    s = re.sub(r'\\text\{([^{}]*)\}|\\mbox\{([^{}]*)\}', ' ', s)

    # Repeating decimals. The repeating block may follow a fixed prefix, so
    # '.08333...' is 1/12, not 1/3, and '.0909...' has a two-digit period.
    def repeat(m):
        digits = m.group(1).lstrip('.')
        best = None
        for k in range(len(digits)):
            for p in range(1, len(digits) - k + 1):
                block = digits[k:k + p]
                tail = digits[k:]
                if len(tail) < p + 1:
                    continue
                if all(tail[i] == block[i % p] for i in range(len(tail))):
                    best = (k, block)
                    break
            if best:
                break
        if not best:
            return m.group(0)
        k, block = best
        prefix = digits[:k]
        num = int(prefix + block) - int(prefix or '0')
        den = (10 ** len(block) - 1) * 10 ** k
        return f'(Rational({num},{den}))'
    s = re.sub(r'(\.\d{2,})\s*(?:\\ldots|\\dots|\.\.\.)', repeat, s)

    # Radicals. The optional index must be handled before the plain form.
    for _ in range(3):
        s = re.sub(r'\\sqrt\[(\d+)\]\{([^{}]+)\}', r'(\2)**Rational(1,\1)', s)
        s = re.sub(r'\\sqrt\{([^{}]+)\}', r'sqrt(\1)', s)
        s = re.sub(r'\\d?frac\{([^{}]+)\}\{([^{}]+)\}', r'((\1)/(\2))', s)

    # Definite integrals: \int_{a}^{b} f dx
    m = re.match(r'\s*\\int_\{?([^{}\s]+)\}?\^\{?([^{}\s]+)\}?\s*(.+?)\s*d\s*([a-z])\s*$', s)
    if m:
        lo, hi, body, var = m.groups()
        body = latex_to_sympy(body)
        if body is None:
            return None
        return f'integrate({body}, ({var}, {lo}, {hi}))'

    # Logarithms: \log_{b} x, \ln x. sympy's log takes (arg, base).
    s = re.sub(r'\\log_\{?([^{}\s]+)\}?\s*\(?([^\s+\-*/=,)]+)\)?', r'log(\2,\1)', s)
    s = re.sub(r'\\ln\s*\(?([^\s+\-*/=,)]+)\)?', r'log(\1)', s)
    s = re.sub(r'\\log\s*\(?([^\s+\-*/=,)]+)\)?', r'log(\1,10)', s)

    # Trigonometry, including inverse and the 'sin^2 x' shorthand.
    s = _degrees(s)
    s = re.sub(r'\\(sin|cos|tan|sec|csc|cot)\^\{?-1\}?', r'a\1', s)
    # The argument may already have been parenthesised by \frac, so allow one
    # level of nesting: 'cos^2 ((pi)/(6))'.
    s = re.sub(r'\\(sin|cos|tan|sec|csc|cot)\^\{?(\d+)\}?\s*'
               r'(\((?:[^()]|\([^()]*\))*\)|[^\s+\-*/=,)]+)',
               r'(\1(\3))**\2', s)
    s = re.sub(r'\\(sin|cos|tan|sec|csc|cot|asin|acos|atan)\s*', r'\1', s)
    s = re.sub(r'\\a(sin|cos|tan)', r'a\1', s)

    s = s.replace('\\times', '*').replace('\\cdot', '*').replace('\\div', '/')
    s = s.replace('\\pi', 'pi').replace('\\%', '%')
    s = re.sub(r'\^\{([^{}]+)\}', r'**(\1)', s)
    s = re.sub(r'\^(-?\d+)', r'**(\1)', s)
    s = re.sub(r'(\d*\.?\d+)\s*\\?%', r'((\1)/100)', s)
    s = s.replace('−', '-').replace('–', '-')
    # Mixed number: '4((1)/(8))' is 4 + 1/8, not a product.
    s = re.sub(r'(?<![\d.])(\d+)\s*\(\((.+?)\)\)', r'(\1+((\2)))', s)
    s = re.sub(r'\)\s*\(', ')*(', s)
    s = re.sub(r'(\d)\s*\(', r'\1*(', s)
    s = re.sub(r'(\d)\s*([a-zA-Z])', r'\1*\2', s)   # 3x -> 3*x
    s = re.sub(r'\s+', ' ', s).strip()

    if '\\' in s or '_' in s or '%' in s:
        return None
    return s or None


LOCALS = {'sqrt': sp.sqrt, 'log': sp.log, 'pi': sp.pi, 'E': sp.E,
          'Rational': sp.Rational, 'integrate': sp.integrate,
          'sin': sp.sin, 'cos': sp.cos, 'tan': sp.tan,
          'sec': sp.sec, 'csc': sp.csc, 'cot': sp.cot,
          'asin': sp.asin, 'acos': sp.acos, 'atan': sp.atan}


def evaluate(expr_str):
    """Numeric value of a translated expression, or None."""
    try:
        e = sp.sympify(expr_str, locals=dict(LOCALS))
        if e.free_symbols:
            return None
        v = complex(e.evalf())
        if abs(v.imag) > 1e-9:
            return None
        return float(v.real)
    except Exception:
        return None


def solve_for_unknown(tex):
    """An equation with one free symbol, solved for it."""
    s = latex_to_sympy(tex)
    if s is None or s.count('=') != 1:
        return None, None
    lhs, rhs = s.split('=')
    if not lhs.strip() or not rhs.strip():
        return None, None
    try:
        L = sp.sympify(lhs, locals=dict(LOCALS))
        R = sp.sympify(rhs, locals=dict(LOCALS))
    except Exception:
        return None, None
    free = (L.free_symbols | R.free_symbols)
    if len(free) != 1:
        return None, None
    sym = next(iter(free))
    try:
        roots = sp.solve(sp.Eq(L, R), sym)
    except Exception:
        return None, None
    reals = []
    for r in roots:
        try:
            v = complex(sp.N(r))
            if abs(v.imag) < 1e-9:
                reals.append(float(v.real))
        except Exception:
            pass
    if len(reals) == 1:
        return reals[0], 'solve-eq'
    return None, None


UNITS = {
    # length
    'mile': 63360, 'miles': 63360, 'yard': 36, 'yards': 36, 'feet': 12,
    'foot': 12, 'inch': 1, 'inches': 1, 'rod': 198, 'rods': 198,
    # volume (fluid ounces)
    'gallon': 128, 'gallons': 128, 'quart': 32, 'quarts': 32,
    'pint': 16, 'pints': 16, 'cup': 8, 'cups': 8, 'ounce': 1, 'ounces': 1,
    # time (seconds)
    'day': 86400, 'days': 86400, 'hour': 3600, 'hours': 3600,
    'minute': 60, 'minutes': 60, 'second': 1, 'seconds': 1,
}
FAMILY = [
    {'mile', 'miles', 'yard', 'yards', 'feet', 'foot', 'inch', 'inches', 'rod', 'rods'},
    {'gallon', 'gallons', 'quart', 'quarts', 'pint', 'pints', 'cup', 'cups',
     'ounce', 'ounces'},
    {'day', 'days', 'hour', 'hours', 'minute', 'minutes', 'second', 'seconds'},
]


def same_family(a, b):
    return any(a in f and b in f for f in FAMILY)


def unit_convert(s):
    """'2.5 pints = ___ cups', '75% of 1 gallon = ___ oz', '3/4 of 3 yards = ___ in'."""
    if '=' not in s and ' is ' not in s:
        return None, None
    parts = re.split(r'=|\bis\b', s, maxsplit=1)
    left, right = parts[0], parts[-1]
    target = None
    for w in re.findall(r'[a-z]+', right.lower()):
        if w in UNITS:
            target = w
    if target is None:
        return None, None

    total, found = 0.0, False
    # Terms are joined by 'and'; each may carry a scalar prefix ('75% of',
    # '3/4 of'), and the quantity itself may be implied ('a mile').
    # A single term may itself list several quantities: '2 days 7 hours
    # 12 minutes'. Sum every explicit pair rather than taking the last.
    pairs = [(float(q), u) for q, u in
             re.findall(r'(\d*\.?\d+)\s*(?:\b(?:square|cubic|sq\.?|cu\.?)\b\s*)?([a-z]+)',
                        left.lower())
             if u in UNITS and same_family(u, target)]
    if len(pairs) > 1 and not re.search(r'\\frac|\\?%', left):
        pw = 2 if re.search(r'square', left, re.I) else \
            3 if re.search(r'cubic', left, re.I) else 1
        tp = 2 if re.search(r'square', right, re.I) else \
            3 if re.search(r'cubic', right, re.I) else 1
        total = sum(q * UNITS[u] ** pw for q, u in pairs)
        return total / UNITS[target] ** tp, 'unit-convert'

    for term in re.split(r'\band\b', left):
        # 'square'/'cubic' sit between the quantity and the unit, so they must
        # be skipped or the number is lost and the quantity defaults to 1.
        m = re.search(r'(?:(\d*\.?\d+)\s*)?(?:\b(?:a|an|one)\b\s*)?'
                      r'(?:\b(?:square|cubic|sq\.?|cu\.?)\b\s*)?'
                      r'([a-z]+)\s*\.?\s*$', term.strip().lower())
        if not m:
            m = re.search(r'(?:(\d*\.?\d+)\s*)?([a-z]+)', term.strip().lower())
        if not m or m.group(2) not in UNITS or not same_family(m.group(2), target):
            continue
        qty = float(m.group(1)) if m.group(1) else 1.0
        # The quantity itself may be a fraction or a mixed number, written
        # directly against the unit: '1/8 miles', '1 1/3 cubic yards'.
        qm = re.search(r'(?:(\d+)\s*)?\\d?frac\{(\d+)\}\{(\d+)\}\s*(?!.*\bof\b)',
                       term[:m.start() + len(m.group(0))])
        if qm and not m.group(1):
            qty = (int(qm.group(1)) if qm.group(1) else 0) \
                + int(qm.group(2)) / int(qm.group(3))
        # 'square yards' and 'cubic feet' raise the conversion factor.
        pw = 2 if re.search(r'square', term, re.I) else \
            3 if re.search(r'cubic', term, re.I) else 1

        # A scalar prefix multiplies the quantity: '75% of 1 gallon'.
        prefix = term[:m.start()] if m.start() else term
        # A mixed-number percent ('12 1/2% of a mile') must be read whole.
        mp = re.search(r'(\d+)?\s*\\d?frac\{(\d+)\}\{(\d+)\}\s*\\?%\s*of\b', prefix)
        pm = re.search(r'(\d*\.?\d+)\s*\\?%\s*of\b', prefix)
        fm = re.search(r'\\d?frac\{(\d+)\}\{(\d+)\}\s*of\b', prefix)
        if mp:
            whole = int(mp.group(1)) if mp.group(1) else 0
            qty *= (whole + int(mp.group(2)) / int(mp.group(3))) / 100
        elif pm:
            qty *= float(pm.group(1)) / 100
        elif fm:
            qty *= int(fm.group(1)) / int(fm.group(2))
        total += qty * UNITS[m.group(2)] ** pw
        found = True
    if not found:
        return None, None
    tp = 2 if re.search(r'square', right, re.I) else \
        3 if re.search(r'cubic', right, re.I) else 1
    return total / UNITS[target] ** tp, 'unit-convert'


def radians_to_degrees(s):
    """'\\frac{5\\pi}{8} = ___ degrees' — the answer is the degree measure."""
    if not re.search(r'\\circ|degree|\u00b0', s):
        return None, None
    lhs = re.split(r'=', s)[0]
    if '\\pi' not in lhs:
        return None, None
    e = latex_to_sympy(lhs)
    if e is None:
        return None, None
    v = evaluate(e)
    if v is None:
        return None, None
    import math as _m
    return v * 180 / _m.pi, 'rad-to-deg'


COMB = re.compile(r'(?:\{\})?_\{?(\d+)\}?\s*([CP])\s*_?\{?(\d+)\}?')


def combinations(s):
    """'{}_{5}C_{3}', and whole expressions over them: '{}_4P_2 / {}_4C_2'."""
    import math as _m
    if not COMB.search(s):
        return None, None
    kinds = []

    def one(m):
        n, kind, r = int(m.group(1)), m.group(2), int(m.group(3))
        if r > n:
            raise ValueError
        kinds.append(kind)
        return str(_m.comb(n, r) if kind == 'C' else _m.perm(n, r))

    try:
        reduced = COMB.sub(one, s)
    except ValueError:
        return None, None
    e = latex_to_sympy(reduced)
    v = evaluate(e) if e else None
    if v is None:
        return None, None
    tag = 'nCr' if set(kinds) == {'C'} else 'nPr' if set(kinds) == {'P'} else 'nCr/nPr'
    return v, tag


def rate_convert(s):
    """'15 miles per hour = ___ feet per second' — both halves are compound."""
    m = re.search(r'([\d.]+)\s*([a-z]+)\s*per\s*([a-z]+).*?=.*?([a-z]+)\s*per\s*([a-z]+)',
                  s.lower())
    if not m:
        return None, None
    qty, un, ud, tn, td = m.groups()
    if not all(w in UNITS for w in (un, ud, tn, td)):
        return None, None
    if not (same_family(un, tn) and same_family(ud, td)):
        return None, None
    return float(qty) * (UNITS[un] / UNITS[tn]) / (UNITS[ud] / UNITS[td]), 'rate-convert'


def base_convert(s):
    """'123_4 = ___ _5' and '.32_5 to a base-10 fraction'."""
    m = re.search(r'([\dA-Fa-f.]+)_\{?(\d+)\}?', s)
    if not m:
        return None, None
    digits, frm = m.group(1), int(m.group(2))
    try:
        whole, _, frac = digits.partition('.')
        v = 0.0
        for ch in whole:
            v = v * frm + int(ch, 36)
        for i, ch in enumerate(frac, 1):
            v += int(ch, 36) / frm ** i
    except ValueError:
        return None, None
    rest = s[m.end():]
    m2 = re.search(r'_\{?(\d+)\}?|base[- ](\d+)', rest)
    to = int(m2.group(1) or m2.group(2)) if m2 else 10
    if to == 10:
        return v, 'base-convert'
    return None, None            # digit-string targets aren't numeric answers


def series(s):
    """Arithmetic and geometric sums written out with an ellipsis."""
    if not re.search(r'\\cdots|\\ldots|\.\.\.', s):
        return None, None
    body = re.sub(r'\\cdots|\\ldots|\.\.\.', '~', s).rstrip('=').strip()
    parts = [p.strip() for p in body.split('+')]
    if len(parts) < 3:
        return None, None
    head, tail = [], None
    for p in parts:
        if p == '~':
            continue
        e = latex_to_sympy(p)
        v = evaluate(e) if e else None
        if v is None:
            return None, None
        head.append(v)
    if '~' not in parts:
        return None, None
    ends_open = parts[-1] == '~'
    if not ends_open:
        tail = head.pop()
    if len(head) < 2:
        return None, None

    d = head[1] - head[0]
    arithmetic = all(abs(head[i + 1] - head[i] - d) < 1e-9 for i in range(len(head) - 1))
    r = head[1] / head[0] if head[0] else None
    geometric = r is not None and all(
        abs(head[i + 1] - head[i] * r) < 1e-9 for i in range(len(head) - 1))

    if arithmetic and tail is not None and d:
        n = round((tail - head[0]) / d) + 1
        if n > 0 and abs(head[0] + (n - 1) * d - tail) < 1e-9:
            return n * (head[0] + tail) / 2, 'arith-series'
    if geometric:
        if ends_open and abs(r) < 1:
            return head[0] / (1 - r), 'geom-series-inf'
        if tail is not None and r not in (0, 1):
            n = round(sp.log(tail / head[0], r)) + 1
            if abs(head[0] * r ** (n - 1) - tail) < 1e-6:
                return head[0] * (r ** n - 1) / (r - 1), 'geom-series'
    return None, None


def divisors(s):
    """'N has how many positive [prime] integral divisors'."""
    m = re.match(r'\s*(\d+)\s+has how many positive (prime )?integral divisors', s, re.I)
    if not m:
        return None, None
    n, prime_only = int(m.group(1)), bool(m.group(2))
    f = sp.factorint(n)
    if prime_only:
        return float(len(f)), 'divisor-count'
    total = 1
    for e in f.values():
        total *= e + 1
    return float(total), 'divisor-count'


def solve(tex):
    """-> (value, how) or (None, None)."""
    s = re.sub(r'\\text\{([^{}]*)\}', r' \1 ', tex)
    s = re.sub(r'_{2,}|\\rule\{[^}]*\}\{[^}]*\}', ' BLANK ', s)
    s = re.sub(r'\s+', ' ', s).strip()

    # 'Which is larger, 5/8 or .622?' asks for a choice, not a value; answering
    # it with one of the two operands only looks right half the time.
    if re.search(r'\bwhich is (larger|smaller|greater|less)\b', s, re.I):
        return None, None
    # A base-subscripted numeral inside a further question ('the remainder
    # when 123456_7 is divided by 6', 'find b when 4b_6 = 29') is not a plain
    # base conversion, and answering it as one is wrong.
    base_guarded = re.search(r'remainder|find\s+[a-z]\b|divisible', s, re.I)

    rules = [divisors, combinations, radians_to_degrees, series,
             rate_convert, unit_convert]
    if not base_guarded:
        rules.append(base_convert)
    for rule in rules:
        try:
            v, tag = rule(s)
        except Exception:
            v, tag = None, None
        if v is not None:
            return v, tag

    # A closed form, once the blank and its unit hint are removed.
    stripped = re.sub(r'BLANK|\(dec\.?\)|\(fraction\)', '', s).strip().rstrip('=').strip()
    if '=' not in stripped:
        e = latex_to_sympy(stripped)
        if e:
            v = evaluate(e)
            if v is not None:
                return v, 'symbolic'

    v, tag = solve_for_unknown(re.sub(r'BLANK', '', tex))
    if v is not None:
        return v, tag
    return None, None
