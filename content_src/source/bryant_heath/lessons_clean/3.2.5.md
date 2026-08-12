# Changing Bases: Sum of Powers

When asked the sum of a series of powers of two ($1 + 2 + 4 + 8 + \cdots + 2^n\text{)}$, it is best to represent the number in binary, then read off the result. For example, consider the sum $1 + 2 + 4 + 8 + 16 + 32 + 64$:

$$
\begin{aligned}
1 + 2 + 4 + 8 + 16 + 32 + 64 \\
&= 1 \cdot 2^0 + 1 \cdot 2^1 + 1 \cdot 2^2 + 1 \cdot 2^3 + 1 \cdot 2^4 + 1 \cdot 2^5 + 1 \cdot 2^6 \\
&= 1111111_2
\end{aligned}
$$

$$
1111111_2 = 10000000_2 - 1_2 \Rightarrow 2^7 - 1 = 128 - 1 = \mathbf{127}
$$

Although this method is easiest with binary, you can apply it to other powers as well, as long as you are careful. For example:

$$
\begin{aligned}
2 + 2 \cdot 3 + 2 \cdot 9 + 2 \cdot 27 + 2 \cdot 81 + 2 \cdot 243 \\
&= 2 \cdot 3^0 + 2 \cdot 3^1 + 2 \cdot 3^2 + 2 \cdot 3^3 + 2 \cdot 3^4 + 2 \cdot 3^5 \\
&= 222222_3
\end{aligned}
$$

$$
222222_3 = 1000000_3 - 1 = 3^6 - 1 = \mathbf{728}
$$
