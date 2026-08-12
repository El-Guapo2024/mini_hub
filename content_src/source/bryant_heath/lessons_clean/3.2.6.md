# Changing Bases: Miscellaneous Topics

There are a handful of topics involving changing bases that rely on understanding other tricks previously discussed in this book.

**Repeating base-$n$ decimals as fractions:** This uses the formula for the sum of an infinite geometric series. For example, convert $.333\cdots_7$ into a base-10 fraction:

$$
\begin{aligned}
.333\cdots_7 \\
&= \frac{3}{7} + \frac{3}{49} + \frac{3}{343} + \cdots \\
&= \frac{\dfrac{3}{7}}{1 - \dfrac{1}{7}} \\
&= \frac{3}{7} \times \frac{7}{6} \\
&= \frac{1}{2}
\end{aligned}
$$

**Remainder when dividing a base-$n$ number by $n-1$:** This relies on the fact that $n^k \equiv 1 \pmod{n-1}$ for any integer $k$. So any base-$n$ integer can be evaluated mod $n-1$ by simply summing its digits. For example, find the remainder when $123456_7 \div 6$:

$$
\begin{aligned}
123456_7 \\
&= 1 \cdot 7^5 + 2 \cdot 7^4 + 3 \cdot 7^3 + 4 \cdot 7^2 + 5 \cdot 7^1 + 6 \cdot 7^0 \equiv (1+2+3+4+5+6) \\
&= \frac{6 \cdot 7}{2} \\
&= 21 \equiv \mathbf{3} \pmod{6}
\end{aligned}
$$

So when you have a base-$n$ number and divide it by $n - 1$, all you need to do is sum the digits and find the remainder when dividing by $n - 1$.
