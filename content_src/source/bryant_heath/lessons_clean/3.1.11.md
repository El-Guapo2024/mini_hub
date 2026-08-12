# Function Inverses

Usually on the last column you are guaranteed to have to compute the inverse of a function at a particular value. The easiest way to do this is to not *explicitly* solve for the inverse and plug in the point, but rather to compute the inverse at that point as you go.

For example, given $f(x) = \frac{3}{2}x - 2$ and you want to calculate $f^{-1}(x)$ at the point $x = 3$: instead of doing the standard procedure for finding inverses (switch the $x$ and $y$ variables and solve for $y\text{)}$, just switch the $x$ and $y$ variables, then plug in the value for $x$, then compute $y$:

$$
\begin{aligned}
x \\
&= \frac{3}{2}y - 2 \Rightarrow 3 \\
&= \frac{3}{2}y - 2 \Rightarrow y \\
&= (3 + 2) \cdot \frac{2}{3} \\
&= \frac{\mathbf{10}}{\mathbf{3}}
\end{aligned}
$$

This saves time because you aren't solving for the inverse function for *all* points, but rather the inverse at that particular point.

Another important case to remember is when the function is in the form:

$$
f(x) = \frac{ax + b}{cx + d} \Rightarrow f^{-1}(x) = \frac{-dx + b}{cx - a}
$$

The key is to line up the $x\text{'s}$ on the numerator and denominator so it is in the required form. For example, find $f^{-1}(2)$ where $f(x) = \dfrac{2x+3}{4+5x}$:

$$
\begin{aligned}
f(x) \\
&= \frac{2x+3}{5x+4} \Rightarrow f^{-1}(x) \\
&= \frac{-4x+3}{5x-2} \Rightarrow f^{-1}(2) \\
&= \frac{-4 \cdot 2 + 3}{5 \cdot 2 - 2} \\
&= \frac{-5}{8}
\end{aligned}
$$
