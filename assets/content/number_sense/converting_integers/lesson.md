# Converting Integers Between Bases

A base-10 number is just a sum of powers of 10 weighted by digits 0-9. A base-$n$ number works the same way, but the powers are powers of $n$, and the digits range from $0$ to $n-1$:

$$
n\text{-base number} = a_m n^m + a_{m-1}n^{m-1} + \cdots + a_1 n^1 + a_0 n^0
$$

**Base-$n$ to base-10:** just expand and add. For example, convert $123_4$ to base 10:

$$
123_4 = 1\cdot4^2 + 2\cdot4^1 + 3\cdot4^0 = 16 + 8 + 3 = \mathbf{27}
$$

Sums of powers like $2^4 + 2^3 + 2^0$ are already telling you the base-2 digits directly — read off which powers appear (with coefficients) to get the digits, then add for the base-10 value.

**Base-10 to base-$n$:** find the largest power of $n$ that fits, record how many times it divides in, take the remainder, and repeat with the next lower power. Convert $51$ to base 6:

$$
51 = 1\cdot 6^2 + 2\cdot 6^1 + 3\cdot 6^0 \;\Rightarrow\; 51_{10} = \mathbf{123_6}
$$

Since $6^2=36$ goes into $51$ once (remainder $15\text{)}$, $6^1=6$ goes into $15$ twice (remainder $3\text{)}$, and $6^0$ goes into $3$ three times. Watch for zero digits, e.g. $18_{10} = 102_4$ since $4^1=4$ doesn't divide the remainder $2$ at all.

**Solving for the base itself:** if $44_b = 40$ (base 10), write $4b + 4 = 40$, so $b = 9$. Treat the unknown base as a variable and solve the resulting linear equation, checking that digits used are valid for that base.
