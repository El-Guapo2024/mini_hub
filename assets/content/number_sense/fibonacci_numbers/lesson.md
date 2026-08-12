# Sum of the First n Fibonacci Numbers

It would be best to have the Fibonacci numbers memorized up to $F_{15}$ because they crop up every now and then on the number sense test. In case you are unaware, the Fibonacci sequence follows the recursive relationship $F_n = F_{n-1} + F_{n-2}$. The following is a helpful table:

$$
\begin{array}{llll}
F_1 = 1   & F_2 = 1   & F_3 = 2   & F_4 = 3   \\
F_5 = 5   & F_6 = 8   & F_7 = 13  & F_8 = 21  \\
F_9 = 34  & F_{10} = 55 & F_{11} = 89 & F_{12} = 144 \\
F_{13} = 233 & F_{14} = 377 & F_{15} = 610 &
\end{array}
$$

The most helpful formula to memorize concerning Fibonacci Numbers is that the sum of the first $n$ Fibonacci Numbers is equal to $F_{n+2} - 1$.

A common problem asked on the latter parts of the number sense test is:

> Find the sum of the first eight terms of the Fibonacci sequence $2, 5, 7, 12, 19, \ldots$

Now there are two methods of approach for doing this.

**Method 1:**

The sum of the first $n\text{-terms}$ of a general Fibonacci sequence $a, b, a+b, a+2b, 2a+3b, \ldots$ is

$$
\sum = a \cdot (F_{n+2} - 1) + d \cdot (F_{n+1} - 1), \quad \text{where } d = (b - a)
$$

So for our example:

$$
\begin{aligned}
\sum \\
&= 2 \cdot (F_{10} - 1) + (5 - 2) \cdot (F_9 - 1) \\
&= 2 \cdot 54 + 3 \cdot 33 \\
&= 108 + 99 \\
&= \mathbf{207}
\end{aligned}
$$

**Method 2:**

The other method of doing this sum requires memorization of knowing a formula for each particular sum. The following is a list of the sums of a general Fibonacci sequence $a, b, a+b, a+2b, 2a+3b, \ldots$ for 1–12 terms (the number of terms which have been on the exam):

$$
\begin{array}{llll}
n & \textbf{Fibonacci Number} & \textbf{Sum of First } F_n \textbf{ Numbers} & \textbf{Formula} \\
\hline
1  & a        & a            & a = F_1 \\
2  & b        & a+b          & a+b = F_3 \\
3  & a+b      & 2a+2b        & 2(a+b) = 2 \cdot F_3 \\
4  & a+2b     & 3a+4b        & 4(a+b) - a = 4 \cdot F_3 - a \\
5  & 2a+3b    & 5a+7b        & 7(a+b) - 2a = 7 \cdot F_3 - 2a \\
6  & 3a+5b    & 8a+12b       & 4(2a+3b) = 4 \cdot F_5 \\
7  & 5a+8b    & 13a+20b      & 4(3a+5b) + a = 4 \cdot F_6 + a \\
8  & 8a+13b   & 21a+33b      & 7(3a+5b) - 2b = 7 \cdot F_6 - 2b \\
9  & 13a+21b  & 34a+54b      & 7(5a+8b) - (a+2b) = 7 \cdot F_7 - F_4 \\
10 & 21a+34b  & 55a+88b      & 11(5a+8b) = 11 \cdot F_7 \\
11 & 34a+55b  & 89a+143b     & 11(8a+13b) + a = 11 \cdot F_8 + a \\
12 & 55a+89b  & 144a+232b    & 18(8a+13b) - b = 18 \cdot F_8 - b
\end{array}
$$

So in our case, we are summing the first 8 terms, which is just $7 \cdot F_6 - 2b$, where $F_6$ represents the sixth term in the sequence of $2, 5, 7, 12, 19, \ldots$ (which is 31), so $7 \cdot 31 - 2 \cdot 5 = 217 - 10 = \mathbf{207}$.

So in solving it this way you have to calculate what the $6^{th}$ term in the sequence is as well as knowing the formula. Usually it will be required to calculate a middle term in the sequence, and then apply the formula.

These type of questions are usually computationally intense, so it is recommended to skip them and come back to work on them after the completion of all other problems.
