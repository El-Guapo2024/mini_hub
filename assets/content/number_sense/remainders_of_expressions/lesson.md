# Remainders of Expressions

Questions like $(4^3 - 15 \times 43) \div 6$ has what remainder, are very popular and appear anywhere from the $2^{nd}$ to the $4^{th}$ column. This problem has its root in modular arithmetic (see the Modular Arithmetic (Basic) topic), and the procedure for solving it is simply knowing that "the remainders after algebra is equal to the algebra of the remainders." So instead of actually finding what $4^3 - 15 \times 43$ is and then dividing by 6, we can figure out what the remainder of each term is when dividing by 6, then do the algebra. So:

$$
(4^3 - 15 \times 43) \div 6 \cong (4 - 3 \times 1) \div 6 = r\mathbf{1}
$$

It should be noted that if a negative value is computed as the remainder, addition of multiples of the number which you are dividing by are required. Let's look at an example:

$$
\begin{aligned}
(15 \times 43 - 34 \times 12) \div 7 \cong (1 \times 1 - 6 \times 5) \div 7 \\
&= -29 \Rightarrow -29 + 5 \cdot (7) \\
&= r\mathbf{6}
\end{aligned}
$$

So in the above question, after computing the algebra of remainders, we get an unreasonable remainder of $-29$. So to make this a reasonable remainder (a positive integer such that $0 \le r < 7\text{)}$, we added a multiple of 7 (in this case 35) to get the correct answer.

You can use this concept of "negative remainders" to your benefit as well. For example, if we were trying to see the remainder of $13^8 \div 14$, the long way of doing it would be noticing that $13^2 = 169 \div 14 = r1 \Rightarrow 1^4 \div 14 = r\mathbf{1}$ or you could use this concept of negative remainders (or congruencies if you are familiar with that term) to say that $13^8 \div 14 \Rightarrow (-1)^8 \div 14 = r\mathbf{1}$.
