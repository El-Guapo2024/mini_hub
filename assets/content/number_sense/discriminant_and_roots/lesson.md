# Discriminant Distinct Roots

A very popular question is, when given a quadratic equation, determining the value of an undefined coefficient so that the roots are distinct/equal/complex. Take the following question:

Find the value for $k$ such that the quadratic $3x^2 - x - 2k = 0$ has equal roots.

We know from the quadratic equation that the roots of a general polynomial $ax^2 + bx + c = 0$ can be determined from:

$$
r_{1,2} = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
$$

So we know from this that:

- **Distinct Roots:** $b^2 - 4ac > 0$
- **Equal Roots:** $b^2 - 4ac = 0$
- **Complex Conjugate Roots:** $b^2 - 4ac < 0$

So in our case we need to find the value of $k$ such that the discriminant ($b^2 - 4ac\text{)}$ is equal to zero.

$$
\begin{aligned}
b^2 - 4ac \\
&= 1^2 - 4 \cdot 3 \cdot (-2k) \\
&= 0 \Rightarrow k \\
&= \frac{-1}{4 \cdot 3 \cdot 2} \\
&= \mathbf{\frac{-1}{24}}
\end{aligned}
$$
