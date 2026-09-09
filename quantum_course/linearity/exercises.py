"""
Linearity of the Equations of Motion -- exercises.

Fill in each function where it says TODO, then run:

    python3 exercises.py

The checker tells you which exercises pass. It never prints the answer:
a wrong result gets you a nudge, not a solution.

Only sympy is needed.
"""

import sympy as sp

t, x, tau, alpha, beta, a, b, c, omega = sp.symbols(
    "t x tau alpha beta a b c omega", real=True
)
u = sp.Function("u")
u1 = sp.Function("u1")
u2 = sp.Function("u2")


# ---------------------------------------------------------------- exercise 1
def exercise_1():
    """Zwiebach 1.1.

    L1 and L2 are linear operators.  (L1+L2)u = L1u + L2u, and (L1L2)u = L1(L2u).

    Return a dict saying whether each constructed operator is linear:

        {"sum": ..., "product": ...}

    with True or False for each.  Work it out on paper first -- both follow
    in two lines from the definition.
    """
    # TODO
    return {"sum": None, "product": None}


# ---------------------------------------------------------------- exercise 2
def exercise_2():
    """Classify each equation as linear (True) or not (False), with u the unknown.

        (a)  du/dt = -3u
        (b)  du/dt = u**2
        (c)  d2u/dt2 + omega**2 u = 0
        (d)  du/dt + u = 5
        (e)  u du/dx = 0

    Return {"a": ..., "b": ..., "c": ..., "d": ..., "e": ...}.

    Watch (d).  Ask yourself whether the *solutions* satisfy the two
    conditions -- multiples are solutions, sums are solutions -- rather than
    whether the equation merely looks tidy.
    """
    # TODO
    return {"a": None, "b": None, "c": None, "d": None, "e": None}


# ---------------------------------------------------------------- exercise 3
def exercise_3(L):
    """Decide whether the operator L is linear.

    L is a Python function taking one sympy expression and returning one.
    Return True if L is linear, False otherwise.

    The test is the definition:

        L(alpha*f + beta*g) - alpha*L(f) - beta*L(g)  ==  0

    for arbitrary f and g.  Prefer undefined sympy functions -- sp.Function("f")(t)
    -- over concrete ones like t**2, so that what you prove holds for every f
    rather than for one lucky choice.  sp.simplify is the tool for deciding
    whether an expression is zero.
    """
    # TODO
    return None


# ---------------------------------------------------------------- exercise 4
def exercise_4():
    """The equation is du/dt + u/tau = 0.

    Return {"scaled": ..., "t_times": ...} where

        "scaled"   is True if alpha*exp(-t/tau) solves it for any constant alpha
        "t_times"  is True if t*exp(-t/tau) solves it

    You can do this by hand, or substitute and let sympy tell you.
    """
    # TODO
    return {"scaled": None, "t_times": None}


# ---------------------------------------------------------------- exercise 5
def exercise_5():
    """Newton's second law m x'' = -V'(x) is nonlinear for a general V.

    For which potentials V(x) is it linear?  Return the highest power of x
    that may appear in V.

    Then answer in the string below: which physical systems are these?
    """
    highest_power = None  # TODO: an integer
    systems = ""  # TODO: one sentence, not graded
    return {"highest_power": highest_power, "systems": systems}


# ---------------------------------------------------------------- exercise 6
def exercise_6():
    """The heat equation and the Schrodinger equation are both linear, yet heat
    flow is irreversible and Schrodinger evolution is reversible.

    So linearity is not what separates them.  What does?

    Written answer only -- the checker will not grade this one, it just makes
    sure you wrote something.
    """
    return ""  # TODO


# ================================================================== checker
# Below here is the grader.  You do not need to read it, but nothing is
# hidden from you either.


def _check_1(r):
    if not isinstance(r, dict) or set(r) != {"sum", "product"}:
        return False, "return a dict with keys 'sum' and 'product'"
    if any(v is None for v in r.values()):
        return False, "not attempted"
    # Verified independently: build two concrete linear operators and test
    # both constructions symbolically, rather than trusting the claim.
    f, g = sp.Function("f"), sp.Function("g")
    L1 = lambda e: sp.diff(e, t)
    L2 = lambda e: e / tau
    add = lambda e: L1(e) + L2(e)
    mul = lambda e: L1(L2(e))
    truth = {}
    for name, L in (("sum", add), ("product", mul)):
        lhs = L(alpha * f(t) + beta * g(t))
        rhs = alpha * L(f(t)) + beta * L(g(t))
        truth[name] = sp.simplify(lhs - rhs) == 0
    if r == truth:
        return True, ""
    wrong = [k for k in truth if r[k] != truth[k]]
    return False, (
        f"check {', '.join(wrong)} again -- apply the definition of linearity "
        f"to the constructed operator, one property at a time"
    )


def _check_2(r):
    keys = {"a", "b", "c", "d", "e"}
    if not isinstance(r, dict) or set(r) != keys:
        return False, "return a dict with keys a through e"
    if any(v is None for v in r.values()):
        return False, "not attempted"
    truth = {"a": True, "b": False, "c": True, "d": False, "e": False}
    wrong = sorted(k for k in keys if r[k] != truth[k])
    if not wrong:
        return True, ""
    hint = f"reconsider ({', '.join(wrong)})"
    if "d" in wrong:
        hint += " -- for (d), is the sum of two solutions still a solution?"
    return False, hint


def _check_3(fn):
    f, g = sp.Function("f"), sp.Function("g")
    cases = [
        (lambda e: sp.diff(e, t) + e / tau, True, "d/dt + 1/tau"),
        (lambda e: sp.diff(e, t, 2) + omega**2 * e, True, "d2/dt2 + omega^2"),
        (lambda e: e**2, False, "squaring"),
        (lambda e: sp.diff(e, t) + 5, False, "an added constant"),
        (lambda e: e * sp.diff(e, t), False, "u du/dt"),
        (lambda e: sp.Integer(0) * e, True, "the zero operator"),
    ]
    misses = []
    for L, expected, label in cases:
        try:
            got = fn(L)
        except Exception as exc:
            return False, f"raised {type(exc).__name__} on {label}"
        if got is None:
            return False, "not attempted"
        if bool(got) != expected:
            misses.append(label)
    if not misses:
        return True, ""
    return False, (
        f"misclassified: {', '.join(misses)}. Check what your test does when "
        f"the operator adds a constant, and when it multiplies u by itself"
    )


def _check_4(r):
    if not isinstance(r, dict) or set(r) != {"scaled", "t_times"}:
        return False, "return a dict with keys 'scaled' and 't_times'"
    if any(v is None for v in r.values()):
        return False, "not attempted"
    L = lambda e: sp.diff(e, t) + e / tau
    truth = {
        "scaled": sp.simplify(L(alpha * sp.exp(-t / tau))) == 0,
        "t_times": sp.simplify(L(t * sp.exp(-t / tau))) == 0,
    }
    if r == truth:
        return True, ""
    wrong = [k for k in truth if r[k] != truth[k]]
    return False, f"substitute {', '.join(wrong)} back into the equation and simplify"


def _check_5(r):
    if not isinstance(r, dict) or "highest_power" not in r:
        return False, "return a dict with key 'highest_power'"
    n = r["highest_power"]
    if n is None:
        return False, "not attempted"
    if not isinstance(n, int):
        return False, "'highest_power' should be an integer"
    # Linear <=> V'(x) is a linear function of x <=> V is at most quadratic.
    if n == 2:
        note = "" if r.get("systems", "").strip() else " (write a sentence for 'systems')"
        return True, note.strip()
    return False, "the equation is linear exactly when V'(x) is linear in x"


def _check_6(r):
    if not isinstance(r, str) or not r.strip():
        return False, "not attempted"
    return True, "not graded -- compare with the lesson once you have written it"


def main():
    checks = [
        ("1  operators built from linear operators", _check_1, exercise_1),
        ("2  classify five equations", _check_2, exercise_2),
        ("3  a linearity test", _check_3, exercise_3),
        ("4  scaling a solution", _check_4, exercise_4),
        ("5  which potentials stay linear", _check_5, exercise_5),
        ("6  linear but irreversible", _check_6, exercise_6),
    ]
    passed = 0
    print()
    for label, check, fn in checks:
        try:
            ok, note = check(fn if check is _check_3 else fn())
        except Exception as exc:
            ok, note = False, f"raised {type(exc).__name__}: {exc}"
        mark = "pass" if ok else "    "
        print(f"  [{mark}]  {label}")
        if note:
            print(f"           {note}")
        passed += ok
    print(f"\n  {passed}/{len(checks)}\n")


if __name__ == "__main__":
    main()
