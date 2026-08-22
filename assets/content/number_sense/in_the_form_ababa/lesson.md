# Repeating Decimal Form: .ab repeating

Fractions in the form $.ababab\ldots$ can be treated similarly using an infinite geometric series:

$$
\begin{aligned}
.ababab\ldots \\
&= \frac{ab}{100} + \frac{ab}{10000} + \frac{ab}{1000000} + \cdots \\
&= \frac{\dfrac{ab}{100}}{1 - \dfrac{1}{100}} \\
&= \frac{ab}{100} \times \frac{100}{99} \\
&= \frac{ab}{99}
\end{aligned}
$$

Here $ab$ represents the two-digit number formed by digits $a$ and $b$ (not $a \times b\text{)}$. For example:

$$
.242424\ldots = \frac{24}{99} = \frac{8}{33}
$$

Since the denominator here is always $99 = 9 \times 11$, the only reduction to check for is a common factor of 3 or 9 between the numerator $ab$ and 99 — e.g. $.484848\ldots = \dfrac{48}{99}$ reduces to $\dfrac{16}{33}$.

You can extend this concept to any continuously repeating pattern. For example:

$$
.abcabcabc\ldots = \frac{abc}{999}
$$

where $abc$ represents the three-digit number, and so on.
