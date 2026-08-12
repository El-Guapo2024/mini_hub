# Multiplying Reverses

The following trick involves multiplying two, two-digit numbers whose digits are reverse of each other.

$$
ab \times ba = (10a + b) \cdot (10b + a) = 100(a \cdot b) + 10(a^2 + b^2) + a \cdot b
$$

Here is what we know from the above result:

1. The Ones digit of the answer is just the two digits multiplied together.

2. The Tens digit of the answer is the sum of the squares of the digits.

3. The Hundreds digit of the answer is the two digits multiplied together.

Let's look at an example:

$$
53 \times 35 = \begin{array}{ll}
\text{Ones:}     & 3 \times 5 & \mathit{1}\mathbf{5} \\
\text{Tens:}     & 3^2 + 5^2 + 1 & \mathit{3}\mathbf{5} \\
\text{Hundreds:} & 3 \times 5 + 3 & \mathbf{18} \\
\text{Answer:}   & & \mathbf{1855}
\end{array}
$$
