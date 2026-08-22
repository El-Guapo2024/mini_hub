# Extending Foiling

You can extend the method of FOILing to quickly multiply two three-digit numbers in the form $cba \times dba$. The general objective is you treat the digits of $ba$ as one number, so after foiling you would get:

$$
cba \times dba = \begin{array}{ll}
\text{Ones/Tens:} & (ba)^2 \\
\text{Hundreds/Thousands:} & (c+d) \times (ba) \\
\text{Rest of Answer:} & c \times d
\end{array}
$$

Let's look at a problem to practice this extension:

$$
412 \times 612 = \begin{array}{lll}
\text{Ones/Tens:} & (12)^2 & \mathbf{1}44 \\
\text{Hundreds/Thousands:} & (4+6)\times(12) + 1 & \mathbf{1}21 \\
\text{Rest of Answer:} & 4\times 6 + 1 & 25 \\
\text{Answer:} & & \mathbf{252144}
\end{array}
$$

By treating the last two digits as a single entity, you reduce the three-digit multiplication to a two-digit problem. The last two digits usually match in these problems, but the method does not require it. For example:

$$
211 \times 808 = \begin{array}{lll}
\text{Ones/Tens:} & 08 \times 11 & \mathbf{88} \\
\text{Hundreds/Thousands:} & 08\times 2 + 11\times 8 & \mathbf{1}04 \\
\text{Rest of Answer:} & 2\times 8 + 1 & 17 \\
\text{Answer:} & & \mathbf{170488}
\end{array}
$$

The method works the best when the last two digits don't exceed 20 (after that the multiplication becomes cumbersome). Another good area where this approach is great for is squaring three-digit numbers:

$$
606^2 = 606 \times 606 = \begin{array}{lll}
\text{Ones/Tens:} & 06\times 06 & \mathbf{36} \\
\text{Hundreds/Thousands:} & 06\times 6 + 6\times 06 = 2\times 6\times 6 & \mathbf{72} \\
\text{Rest of Answer:} & 6\times 6 & 36 \\
\text{Answer:} & & \mathbf{367236}
\end{array}
$$

In order to use this procedure for squaring, it would be beneficial to have squares of two-digit numbers memorized. Take for example this problem:

$$
431^2 = 431\times 431 = \begin{array}{lll}
\text{Ones/Tens:} & 31\times 31 & \mathbf{9}61 \\
\text{Hundreds/Thousands:} & 31\times 4 + 4\times 31 + 9 = 2\times 4\times 31 + 9 & 257 \\
\text{Rest of Answer:} & 4\times 4 + 2 & 18 \\
\text{Answer:} & & \mathbf{185761}
\end{array}
$$

If you didn't have $31^2$ memorized, you would have to calculate it in order to do the first step in the process (very time consuming). However, if you have it memorized you would not have to do the extra steps, thus saving time.
