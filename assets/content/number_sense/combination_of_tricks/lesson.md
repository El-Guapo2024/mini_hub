# Combination of Tricks

These problems combine several multiplication tricks you've already learned into a single three-factor product, usually as an approximation on the third or fourth column of the test. The main strategy is to pair up factors that are close to each other or close to a round number, using difference-of-squares or near-a-hundred style adjustments, then multiply the result by what's left.

**Example:** $12 \times 14 \times 16$

Pair the two factors that straddle a common center: $12$ and $16$ are both $2$ away from $14$, so

$$
12 \times 16 = (14-2)(14+2) = 14^2 - 4 = 196 - 4 = 192
$$

Then $192 \times 14 = 2688$, which sits inside the accepted estimate range (2553 to 2823).

**Example:** $24 \times 34 \times 44$

Here $24$ and $44$ both sit $10$ away from $34$, so

$$
24 \times 44 = 34^2 - 10^2 = 1156 - 100 = 1056
$$

Then $1056 \times 34 = 35904$.

When no clean pairing exists, look instead for a factor near a power of ten (e.g. $146 \times 154 = 150^2 - 4^2\text{)}$ or break one number into a sum/difference of round pieces and distribute. Since these are almost always estimate questions, you don't need the exact value — just get close enough to land inside the tolerance band, so round intermediate results aggressively rather than tracking every digit.

## Ratios of Powers: Cancel the Common Factor First

A different-looking family of combination problems mixes powers with division instead of three plain factors, something like $75^2 \div 25^2 \times 50^4$. Trying to expand $50^4$ or $75^2$ digit by digit is slow and error-prone. The fast approach is algebraic, not arithmetic: notice that the bases are all multiples of the same small number, factor that common piece out of each base, and let matching powers of it cancel before you multiply anything out.

The steps:

1. **Spot the common factor.** Look at the bases involved (not the whole numbers you'd get after raising to a power) and find the largest number that divides all of them evenly. In $75^2 \div 25^2 \times 50^4$, the bases are $75$, $25$, $50$ — all multiples of $25$, since $75 = 3 \times 25$ and $50 = 2 \times 25$.
2. **Factor it out of each base.** Rewrite every base as (common factor) $\times$ (small leftover), then raise that whole product to the power shown: $75^2 = (3 \times 25)^2 = 3^2 \times 25^2$, and $50^4 = (2 \times 25)^4 = 2^4 \times 25^4$.
3. **Cancel matching powers of the common factor algebraically.** Add the exponents of the common factor across multiplications and subtract across divisions, just like you would with any exponent rule, and simplify before multiplying anything out.
4. **Finish with the small leftover arithmetic.** Whatever remains is usually a couple of tiny numbers raised to small powers — easy to compute directly, and only then multiplied by whatever power of the common factor survived the cancellation (if any).

**Worked example 1:** $75^{2} \div 25^{2} \times 50^{4}$

The common factor is $25$: $75 = 3 \times 25$ and $50 = 2 \times 25$.

$$
\frac{75^2}{25^2} = \frac{(3 \times 25)^2}{25^2} = \frac{3^2 \times 25^2}{25^2} = 3^2 = 9
$$

The $25^2$ cancels completely, leaving just $3^2 = 9$ to carry forward:

$$
9 \times 50^4 = 9 \times 6{,}250{,}000 = 56{,}250{,}000
$$

That lands inside the accepted range (53,437,500 to 59,062,500).

**Worked example 2:** $18^{3} \times 15^{3} \div 9^{3}$

Here the common factor is $9$: $18 = 2 \times 9$, and $15$ doesn't share it, but $9$ itself is the divisor, so pair $18^3$ against $9^3$ instead:

$$
\frac{18^3}{9^3} = \left(\frac{18}{9}\right)^3 = 2^3 = 8
$$

$$
8 \times 15^3 = 8 \times 3375 = 27{,}000
$$

That falls inside the accepted range (25,650 to 28,350).

**Worked example 3:** $24^{2} \times 18^{3} \div 6^{4}$

This one is trickier because the common factor's powers don't fully cancel — you have to track the net exponent. The common factor is $6$: $24 = 4 \times 6$ and $18 = 3 \times 6$.

$$
24^2 \times 18^3 \div 6^4 = (4 \times 6)^2 \times (3 \times 6)^3 \div 6^4 = 4^2 \times 3^3 \times 6^{2+3-4}
$$

The exponents on $6$ combine to $2 + 3 - 4 = 1$, so one factor of $6$ survives:

$$
4^2 \times 3^3 \times 6^1 = 16 \times 27 \times 6
$$

Now just multiply the small leftovers: $16 \times 27 = 432$, and $432 \times 6 = 2592$, which is exactly the answer for this question (no estimating needed here).

The key habit to build is treating the exponent of the common factor as its own running total — add one for every multiplication involving it, subtract one for every division — and only expanding the surviving small numbers at the very end. That keeps you working with single-digit or two-digit arithmetic the whole way through, even when the original bases and exponents look intimidating.
