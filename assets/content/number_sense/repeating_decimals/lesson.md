# Repeating Decimals

The following sections are concerned with expressing repeating decimals as fractions. All of the problems of this nature have their root in the sum of infinite geometric series.

## In the form $0.\overline{a}$

Any decimal in the form $.aaaa\ldots$ can be rewritten as:

$$
.aaaa\ldots = \frac{a}{10} + \frac{a}{100} + \frac{a}{1000} + \cdots
$$

Using the sum of an infinite geometric sequence with common ratio $\frac{1}{10}$:

$$
\begin{aligned}
\frac{a}{10} + \frac{a}{100} + \frac{a}{1000} + \cdots \\
&= \frac{\dfrac{a}{10}}{1 - \dfrac{1}{10}} \\
&= \frac{a}{10} \times \frac{10}{9} \\
&= \frac{a}{9}
\end{aligned}
$$

So for example: $.44444\ldots = \dfrac{4}{9}$.

## In the form $0.\overline{ab}$

Fractions in the form $.ababab\ldots$ can be treated similarly:

$$
\begin{aligned}
.ababab\ldots \\
&= \frac{ab}{100} + \frac{ab}{10000} + \frac{ab}{1000000} + \cdots \\
&= \frac{\dfrac{ab}{100}}{1 - \dfrac{1}{100}} \\
&= \frac{ab}{100} \times \frac{100}{99} \\
&= \frac{ab}{99}
\end{aligned}
$$

where $ab$ represents the two-digit number (not $a \times b\text{)}$. For example:

$$
.242424\ldots = \frac{24}{99} = \frac{8}{33}
$$

You can extend the concept for any sort of continuously repeating decimal. For example, $.abcabcabc\ldots = \dfrac{abc}{999}$, and so on.
