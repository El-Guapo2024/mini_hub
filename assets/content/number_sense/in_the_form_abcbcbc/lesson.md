# Repeating Decimal Form: .abcbcbc

Fractions in the form $.a\overline{bc}$ (one non-repeating digit $a$, then a repeating two-digit block $bc\text{)}$ combine the ideas from the one-non-repeating-digit case and the pure-repeating-block case:

$$
\begin{aligned}
.abcbc\ldots \\
&= \frac{a}{10} + \frac{bc}{10 \cdot 99} \\
&= \frac{99a + bc}{990} \\
&= \frac{(100a + bc) - a}{990}
\end{aligned}
$$

Here $abc$ represents the three-digit number formed by the digits $a, b, c$ (not $a \times b \times c\text{)}$, so the rule is:

$$
.a\overline{bc} = \frac{abc - a}{990}
$$

subtract the leading non-repeating digit from the full three-digit number, and place the result over 990.

**Example:** $.437373737\ldots = \dfrac{437 - 4}{990} = \dfrac{433}{990}$. Since 433 isn't divisible by 2, 3, or 5, this fraction is already in lowest terms.

**Example with reduction:** $.2474747\ldots = \dfrac{247-2}{990} = \dfrac{245}{990}$. Since both are divisible by 5, this reduces to $\dfrac{49}{198}$.

Always check the numerator and denominator for common factors of 2, 3, and 5 first — the test expects fractions in lowest terms, and this is usually the fastest way to spot a reduction.
