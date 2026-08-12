# Multiplying Two Numbers Ending in 5

This is a helpful trick for multiplying two numbers ending in 5. Let's look at its derivation: let $n_1 = a5 = 10a+5$ and $n_2 = b5 = 10b+5$, then:

$$
\begin{aligned}
n_1 \times n_2 \\
&= (10a+5)\cdot(10b+5) \\
&= 100(ab) + 50(a+b) + 25 \\
&= 100\!\left(ab + \frac{a+b}{2}\right) + 25
\end{aligned}
$$

So what does this mean:

1. If $a+b$ is even then the last two digits are 25.
2. If $a+b$ is odd then the last two digits are 75.
3. The remainder of the answer is just $a \cdot b + \lfloor\frac{a+b}{2}\rfloor$, where $\lfloor x \rfloor$ is the greatest integer less than or equal to $x$.

Let's look at an example in each case:

$$
45 \times 85 = \begin{array}{lll}
\text{Ones/Tens:} & \text{Since } 4+8 \text{ is even} & \mathbf{25} \\
\text{Rest of Answer:} & 4\times 8 + \dfrac{4+8}{2} = 32 + 6 & \mathbf{38} \\
\text{Answer:} & & \mathbf{3825}
\end{array}
$$

$$
35 \times 85 = \begin{array}{lll}
\text{Ones/Tens:} & \text{Since } 3+8 \text{ is odd} & \mathbf{75} \\
\text{Rest of Answer:} & 3\times 8 + \lfloor\dfrac{3+8}{2}\rfloor = 24 + 5 & \mathbf{29} \\
\text{Answer:} & & \mathbf{2975}
\end{array}
$$
