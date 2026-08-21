# Integration

Integrating a polynomial reverses the power rule: raise each power by one and divide by the new power, then evaluate at the two limits and subtract. For

$$
\int_a^b x^n \, dx = \left.\frac{x^{n+1}}{n+1}\right|_a^b = \frac{b^{n+1}}{n+1} - \frac{a^{n+1}}{n+1}
$$

**Example:** Evaluate $\displaystyle\int_0^2 3x^2 - x \, dx$.

$$
\int_0^2 3x^2 - x\, dx = \left.\left(x^3 - \frac{x^2}{2}\right)\right|_0^2 = \left(8 - 2\right) - \left(0 - 0\right) = \mathbf{6}
$$

The same rule applies to fractional and negative powers (like $x^{3/4}$ or $x^{-2}\text{)}$ and to sums of terms — integrate each term separately.

For trig functions you need $\int \sin x\, dx = -\cos x$ and $\int \cos x\, dx = \sin x$. For example, $\displaystyle\int_0^\pi \sin x \, dx = [-\cos x]_0^\pi = (-\cos\pi) - (-\cos 0) = 1 + 1 = 2$, while $\displaystyle\int_0^\pi \cos x\, dx = [\sin x]_0^\pi = \sin\pi - \sin 0 = 0$.

**Odd-function shortcut:** if $f(x)$ is odd (meaning $f(-x) = -f(x)$, like $\sin x$ or any odd power of $x\text{)}$ and the limits are $-a$ to $a$, the integral is automatically zero — the area above and below the axis cancels exactly:

$$
\int_{-a}^{a} \text{odd function}\, dx = 0
$$

This shortcut applies directly to problems like $\int_{-3}^{3} x^2\,dx$ — wait, $x^2$ is *even*, not odd, so that one must be computed directly ($=18\text{)}\text{;}$ reserve the shortcut for genuinely odd integrands such as $\int_{-1}^{1}$ of an odd-power term.
