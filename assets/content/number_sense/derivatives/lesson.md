# Derivatives

For a polynomial, the derivative comes from the power rule term by term: multiply each term's coefficient by its exponent, then lower the exponent by one. Constants disappear.

$$
f(x) = a_n x^n + \cdots + a_1 x + a_0 \quad \Longrightarrow \quad f'(x) = n\,a_n x^{n-1} + \cdots + a_1
$$

**Example:** Let $f(x) = x^3 - 3x^2 + x - 3$. Find $f'(2)$.

$$
f'(x) = 3x^2 - 6x + 1 \quad \Longrightarrow \quad f'(2) = 3(4) - 6(2) + 1 = 12 - 12 + 1 = \mathbf{1}
$$

**Second derivatives** just apply the power rule again to $f'(x)$. Let $f(x) = 5x^3 + 3x^2 - 7$. Find $f''(1)$.

$$
f'(x) = 15x^2 + 6x \quad \Longrightarrow \quad f''(x) = 30x + 6 \quad \Longrightarrow \quad f''(1) = 30 + 6 = \mathbf{36}
$$

Watch signs carefully when the input is negative, and remember odd powers keep the sign of $x$ while even powers don't.

A few problems use non-polynomial derivatives, most often to set up an $\frac{0}{0}$ indeterminate limit question elsewhere. Keep these handy:

$$
\frac{d}{dx}\sin x = \cos x \qquad \frac{d}{dx}\cos x = -\sin x \qquad \frac{d}{dx}e^x = e^x \qquad \frac{d}{dx}\ln x = \frac{1}{x}
$$

For this topic's questions, though, it's almost entirely single- and double-derivatives of polynomials evaluated at a specific number — get comfortable doing the power-rule arithmetic quickly and plugging in immediately, since that's the whole task.
