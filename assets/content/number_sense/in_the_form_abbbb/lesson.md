# Repeating Decimal Form: .ab with one non-repeating digit

Fractions in the form $.abbbb\ldots$ are treated as an infinite series with the inclusion of one extra non-repeating term (the $.a$ term):

$$
\begin{aligned}
.abbb\ldots \\
&= \frac{a}{10} + \frac{b}{100} + \frac{b}{1000} + \cdots \\
&= \frac{a}{10} + \frac{\dfrac{b}{100}}{1 - \dfrac{1}{10}} \\
&= \frac{a}{10} + \frac{b}{90}
\end{aligned}
$$

Combining over a common denominator:

$$
\frac{a}{10} + \frac{b}{90} = \frac{9a + b}{90} = \frac{(10 \cdot a + b) - a}{90}
$$

The numerator is the two-digit number $ab$ minus the non-repeating digit $a$, all placed over 90. For example:

$$
.27777\ldots = \frac{27 - 2}{90} = \frac{25}{90} = \frac{5}{18}
$$

More generally, for a decimal with one non-repeating digit $a$ followed by a repeating block $b$: subtract the non-repeating part from the full number formed by all digits shown, and place it over 90 (or 900, 9000, etc., depending on how many repeating digits there are).

Always check the numerator and denominator for common factors of 2, 3, and 5 first — the test expects fractions in lowest terms, and this is usually the fastest way to spot a reduction.
