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
