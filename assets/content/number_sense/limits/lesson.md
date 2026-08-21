# Limits

Most limits are just direct substitution: plug the target value into the expression.

$$
\lim_{x\to 3} 3x^2 - 4 = 3(3)^2 - 4 = \mathbf{23}
$$

**Indeterminate forms:** if plugging in gives $\frac{0}{0}$, factor the numerator and denominator and cancel the common factor before passing the limit:

$$
\lim_{x\to 2} \frac{(x-2)(x+3)}{(x+5)(x-2)} = \lim_{x\to 2}\frac{x+3}{x+5} = \frac{5}{7}
$$

A common pattern is a difference of cubes or squares hiding a shared root, e.g. $\lim_{x\to 3}\dfrac{x^3-27}{x-3}$: factor $x^3-27=(x-3)(x^2+3x+9)$, cancel $(x-3)$, and substitute $x=3$ into $x^2+3x+9 = 9+9+9=\mathbf{27}$.

**Limits at infinity:** for a ratio of polynomials, only the highest-degree terms matter — divide every term by the highest power of $x$ in the denominator, or just compare leading coefficients when the degrees match:

$$
\lim_{x\to\infty}\frac{3x+8}{7x-4} = \mathbf{\frac{3}{7}}
$$

If the numerator's degree is smaller (or you have something like $\frac{3x-1}{x}\text{)}$, split the fraction: $\frac{3x-1}{x} = 3 - \frac{1}{x} \to 3$ as $x\to\infty$.

For a $\frac{0}{0}$ limit where factoring is inconvenient, L'Hôpital's rule works too: take the derivative of the top and bottom separately and pass the limit again, e.g. $\lim_{x\to 0}\dfrac{\sin x}{x} = \lim_{x\to 0}\dfrac{\cos x}{1} = 1$.
