# Sum and Product of Binomial Coefficients

From the binomial expansion we know that:

$$
(ax + by)^n = \sum_{k=0}^{n} \binom{n}{k} (ax)^{n-k}(by)^k
\begin{aligned}
 \\
&= \binom{n}{0} a^n \cdot x^n + \binom{n}{1} a^{n-1} b^1 \cdot x^{n-1} y^1 + \cdots + \binom{n}{n} b^n y^n
\end{aligned}
$$

From here we can see that the sum of the coefficients of the expansion is:

$$
\sum_{k=0}^{n} \binom{n}{k} a^{n-k} b^k
$$

We can retrieve these sums by setting $x = 1$ and $y = 1$, which gives:

$$
\text{Sum of the Coefficients} = (a + b)^n
$$

For example, the sum of the coefficients of $(x + y)^6$: let $x = 1$ and $y = 1$, so the sum $= (1+1)^6 = \mathbf{64}$.

An interesting side note: when asked to find the sum of the coefficients of $(x - y)^n$, it will always be 0, because letting $x=1$ and $y=1$ gives $(1-1)^n = \mathbf{0}$.

As for the **product** of the coefficients, there is no easy shortcut. The best method is to memorize the first entries of Pascal's triangle:

$$
\begin{array}{c}
1 \\
1 \quad 1 \\
1 \quad 2 \quad 1 \\
1 \quad 3 \quad 3 \quad 1 \\
1 \quad 4 \quad 6 \quad 4 \quad 1 \\
1 \quad 5 \quad 10 \quad 10 \quad 5 \quad 1 \\
1 \quad 6 \quad 15 \quad 20 \quad 15 \quad 6 \quad 1
\end{array}
$$
