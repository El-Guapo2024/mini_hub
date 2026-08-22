# Integration

Integrating a polynomial reverses the power rule: raise each power by one and divide by the new power, then evaluate at the two limits and subtract. For

$$
\int_a^b x^n \, dx = \left.\frac{x^{n+1}}{n+1}\right|_a^b = \frac{b^{n+1}}{n+1} - \frac{a^{n+1}}{n+1}
$$

**Example:** Evaluate $\displaystyle\int_0^2 3x^2 - x \, dx$.

$$
\int_0^2 3x^2 - x\, dx = \left.\left(x^3 - \frac{x^2}{2}\right)\right|_0^2 = \left(8 - 2\right) - \left(0 - 0\right) = \mathbf{6}
$$

The same rule applies to fractional and negative powers, such as $x^{3/4}$ or $x^{-2}$, and to sums of terms — integrate each term separately.

**The one exception is $n = -1$.** Raising the power by one would divide by zero, so $\frac{1}{x}$ integrates to a logarithm instead:

$$
\int_a^b \frac{1}{x}\, dx = \left.\ln x\right|_a^b = \ln b - \ln a
$$

These come up as integrals from 1 to $e$, which is why that limit is chosen: $\ln e = 1$ and $\ln 1 = 0$, so the whole thing collapses to the coefficient. For example

$$
\int_1^e \frac{2}{x}\, dx = 2\left(\ln e - \ln 1\right) = 2(1 - 0) = \mathbf{2}
$$

and likewise $\displaystyle\int_1^e \frac{-3}{x}\, dx = \mathbf{-3}$.

For trig functions you need $\int \sin x\, dx = -\cos x$ and $\int \cos x\, dx = \sin x$. For example, $\displaystyle\int_0^\pi \sin x \, dx = [-\cos x]_0^\pi = (-\cos\pi) - (-\cos 0) = 1 + 1 = 2$, while $\displaystyle\int_0^\pi \cos x\, dx = [\sin x]_0^\pi = \sin\pi - \sin 0 = 0$.

**Odd-function shortcut:** if $f(x)$ is odd — meaning $f(-x) = -f(x)$, as $\sin x$ and every odd power of $x$ are — and the limits run from $-a$ to $a$, the integral is zero. The area below the axis cancels the area above it exactly:

$$
\int_{-a}^{a} \text{odd function}\, dx = 0
$$

Check that the integrand really is odd before using it. $x^2$ is even, so $\int_{-3}^{3} x^2\, dx$ is $18$, not $0$ — it has to be computed. The shortcut is for integrands like $x^3$ or $\sin x$.
