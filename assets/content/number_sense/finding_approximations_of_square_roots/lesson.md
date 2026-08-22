# Finding Approximations of Square Roots

Most square-root (or cube-root) questions on the test don't want an exact value, just a close estimate. The trick is to "pull out" perfect powers of 100 (for square roots) or 1000 (for cube roots) so you're left approximating the root of a small, manageable number.

**Example:** approximate $\sqrt{1234567}$. Round to $1230000 = 123 \times 100 \times 100$, so:

$$
\sqrt{1230000} = \sqrt{123} \times \sqrt{100 \times 100} = 10 \times 10 \times \sqrt{123} \approx 100 \times 11 = 1100
$$

(The true value is about $1111$, well within the margin typically allowed for estimates.)

**Cube roots** work the same way, pulling out powers of 1000. For $\sqrt[3]{1795953}$, round to $1795000 = 1795 \times 1000$:

$$
\sqrt[3]{1795000} = 10 \times \sqrt[3]{1795} \approx 10 \times 12.1 = 121
$$

using $12^3 = 1728$ as a nearby anchor.

**Exact cube roots** (when the number is a perfect cube) use a different, precise method:
1. Count digits in groups of three from the right to know how many digits the answer has.
2. The units digit of the answer comes from the units digit of the cube (e.g., only $4^3=64$ ends in 4, only $9^3=729$ ends in 9, etc.).
3. Drop the last three digits and find the largest integer whose cube is less than what remains — that gives the leading digit(s).

Example: $\sqrt[3]{830584}$. Two three-digit groups (830 | 584) means a two-digit answer. The units digit of $830584$ is 4, and $4^3=64$, so the answer ends in 4. Dropping 584 leaves 830; since $9^3=729 < 830 < 1000=10^3$, the leading digit is 9. The answer is $94$ (check: $94^3 = 830584\text{)}$.

**Multiplying two separately-estimated roots:** when a problem has several roots multiplied together, estimate each root on its own using the nearest perfect square/cube, then multiply the whole-number estimates — the errors don't compound enough to leave the generous $(*)$ range.

For example, $\sqrt{8844} \times \sqrt{6633}$: since $94^2=8836$ is close to $8844$, use $\sqrt{8844}\approx 94\text{;}$ since $81^2=6561$ and $82^2=6724$, use $\sqrt{6633}\approx 81$ (closer to the lower square). Then $94 \times 81 = 7614$, which is inside the allowed range of $7276$ to $8043$, since the exact value is about $7659\text{.}$

**Fourth roots** are just a square root of a square root: $\sqrt[4]{n} = \sqrt{\sqrt{n}}$. Estimate the inner square root first (using the nearest perfect square), then estimate the square root of that result.

For example, in $\sqrt[4]{14643} \times \sqrt[3]{1329} \times \sqrt{120}$: for the fourth root, note $121^2=14641$ is essentially $14643$, so $\sqrt{14643}\approx 121\text{,}$ and then $\sqrt{121}=11$ exactly, so $\sqrt[4]{14643}\approx 11$. For the cube root, $11^3=1331$ is close to $1329$, so $\sqrt[3]{1329}\approx 11$. For the last factor, $11^2=121$ is close to $120$, so $\sqrt{120}\approx 11$. Multiplying the three estimates: $11\times 11\times 11 = 1331$, comfortably inside the allowed range of $1258$ to $1392$, since the exact value is about $1325\text{.}$
