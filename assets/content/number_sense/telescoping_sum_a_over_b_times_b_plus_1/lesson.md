# Telescoping Series (1/(b(b+1)) form)

The best way to illustrate this trick is by example:

$$
\begin{aligned}
\frac{1}{6} + \frac{1}{12} + \frac{1}{20} + \frac{1}{30} \\
&= \frac{1}{2 \cdot 3} + \frac{1}{3 \cdot 4} + \frac{1}{4 \cdot 5} + \frac{1}{5 \cdot 6} \\
&= \frac{1+1+1+1}{2 \cdot 6} \\
&= \frac{4}{12} \\
&= \mathbf{\frac{1}{3}}
\end{aligned}
$$

So the strategy when you see a series in the form of $\frac{a}{b \cdot (b+1)} + \frac{a}{(b+1) \cdot (b+2)} + \cdots$ is to add up all the numerators and then divide it by the smallest factor in the denominators multiplied by the largest factor in the denominators. Let's look at another series:

$$
\begin{aligned}
\frac{1}{42} + \frac{1}{56} + \frac{1}{72} + \frac{1}{90} + \frac{1}{110} \\
&= \frac{1}{6 \cdot 7} + \frac{1}{7 \cdot 8} + \frac{1}{8 \cdot 9} + \frac{1}{9 \cdot 10} + \frac{1}{10 \cdot 11} \\
&= \frac{1+1+1+1+1}{6 \cdot 11} \\
&= \frac{5}{66}
\end{aligned}
$$
