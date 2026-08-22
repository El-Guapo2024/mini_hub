# Repeating Decimal Form: .a repeating

Any decimal in the form $.aaaaa\ldots$ can be rewritten as:

$$
.aaaa\ldots = \frac{a}{10} + \frac{a}{100} + \frac{a}{1000} + \cdots
$$

This is an infinite geometric series with first term $\frac{a}{10}$ and common ratio $\frac{1}{10}$. Summing it:

$$
\begin{aligned}
\frac{a}{10} + \frac{a}{100} + \frac{a}{1000} + \cdots \\
&= \frac{\dfrac{a}{10}}{1 - \dfrac{1}{10}} \\
&= \frac{a}{10} \times \frac{10}{9} \\
&= \frac{a}{9}
\end{aligned}
$$

This confirms what we already know from the fractions of $\frac{1}{9}$. For example:

$$
.44444\ldots = \frac{4}{9}
$$

Since the denominator here is always 9, the only reduction to check for is a common factor of 3 with the numerator $a$ — e.g. $.66666\ldots = \dfrac{6}{9}$ reduces to $\dfrac{2}{3}$.
