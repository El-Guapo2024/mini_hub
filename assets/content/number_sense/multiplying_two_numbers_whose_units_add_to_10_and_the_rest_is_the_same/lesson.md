# Multiplying Two Numbers Whose Units Digits Add to 10 and Leading Digits Are the Same

This is a generalized version of the Squares Ending in 5 trick. Take $n_1 = ab$ and $n_2 = ac$ with $b + c = 10$. Then:

$$
ab \times ac = (10a + b)(10a + c) = 10a(10a + b + c) + bc
$$

Since $b + c = 10$:

$$
10a(10a + 10) + bc = 100a(a+1) + bc
$$

So:
- The **last two digits** are simply $b \times c$ (the units digits multiplied together).
- The **remaining digits** are $a \times (a+1)$ (the leading digit multiplied by one more than itself).

Note: the Squares Ending in 5 trick is a special case where $b = c = 5$, so $bc = 25$ is always the last two digits.

**Examples:**

$$
68 \times 62 = \begin{cases} \text{Tens/Ones:} & 8 \times 2 = \mathbf{16} \\
\text{Remaining:} & 6 \times (6+1) = \mathbf{42} \end{cases} \quad \Rightarrow \quad \mathbf{4216}
$$

$$
173 \times 177 = \begin{cases} \text{Tens/Ones:} & 3 \times 7 = \mathbf{21} \\
\text{Remaining:} & 17 \times (17+1) = \mathbf{306} \end{cases} \quad \Rightarrow \quad \mathbf{30621}
$$

You can also combine this with the Multiplying Two Numbers Equidistant from a Third Number trick: $68 \times 62 = 65^2 - 3^2 = 4225 - 9 = 4216$. Both methods agree; this version avoids the subtraction step.
