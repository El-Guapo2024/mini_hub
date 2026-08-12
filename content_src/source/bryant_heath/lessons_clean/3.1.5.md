# Units Digit Cycle Finding

This is a common problem on the number sense test which seems considerably difficult, however there is a shortcut method. Without delving too much into the modular arithmetic required, you can think of this problem as exploiting patterns. For example, to find the units digit of $3^{47}$, observe the cycle:

$$
\begin{array}{lrc}
\textbf{Power} & \textbf{Value} & \textbf{Units Digit} \\[4pt]
3^1 & 3 & \mathbf{3} \\
3^2 & 9 & \mathbf{9} \\
3^3 & 27 & \mathbf{7} \\
3^4 & 81 & \mathbf{1} \\
3^5 & 243 & \mathbf{3} \\
3^6 & 729 & \mathbf{9} \\
3^7 & 2187 & \mathbf{7} \\
3^8 & 6561 & \mathbf{1}
\end{array}
$$

The units digit repeats every $4^{\text{th}}$ power. The procedure is:

1. For low values of $n$, compute what the units digit of $x^n$ is.
2. Find out how many unique integers there are before repetition (call it $m\text{)}$.
3. Find the remainder $r$ when dividing the large $n$ value of interest by $m$.
4. Find the units digit of $x^r$, and that's your answer.

For $3^{47}$: $47 \div 4$ has a remainder of $3$, and $3^3$ has the units digit $\mathbf{7}$.

Other popular numbers of interest:

$$
\begin{array}{ccc}
\textbf{Ends in} & \textbf{Repeating Digits} & \textbf{Cycle Length} \\[4pt]
2 & 2, 4, 8, 6 & 4 \\
3 & 3, 9, 7, 1 & 4 \\
4 & 4, 6 & 2 \\
5 & 5 & 1 \\
6 & 6 & 1 \\
7 & 7, 9, 3, 1 & 4 \\
8 & 8, 4, 2, 6 & 4 \\
9 & 9, 1 & 2
\end{array}
$$

For example, to find the units digit of $27^{63}$: from the table it repeats every $4^{\text{th}}$ power, so $63 \div 4 \Rightarrow r = 3$, and $r = 3$ corresponds to $7^3$ which ends in $\mathbf{3}$.

This procedure is also helpful with raising the imaginary number $i$ to any power. The cycle for powers of $i$ is:

$$
i^1 = i, \quad i^2 = -1, \quad i^3 = -i, \quad i^4 = 1, \quad i^5 = i, \ldots
$$

The pattern repeats every $4^{\text{th}}$ power. For example, $i^{114}$: $114 \div 4$ has a remainder of $2$, so $i^{114} = i^2 = \mathbf{-1}$.
