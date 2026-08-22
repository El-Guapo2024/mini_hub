# Subtracting Reverses

A common first column problem from the early 2000s involves subtracting two numbers whose digits are reverses of each other (like $715 - 517$ or $6002 - 2006\text{)}$. Let the first number $n_1 = abc = 100a + 10b + c$ so the second number with the digits reversed would be $n_2 = cba = 100c + 10b + a$ so:

$$
\begin{array}{rl}
n_1 - n_2 &= (100a + 10b + c) - (100c + 10b + a) \\
&= 100(a-c) + (c-a) \\
&= 100(a-c) - (a-c)
\end{array}
$$

So the gist of the trick is:

1. Take the difference between the most significant and the least significant digit and multiply it by 100 if it is a three-digit number, or if it is a four digit number multiply by 1000 (however, it only works for 4-digit numbers and above if the middle digits are 0's; for example, $7002 - 2007$ the method works but $7012 - 2107$ it *doesn't* work).

2. Then subtract from that result the difference between the digits.

Let's look at an example:

$$
812 - 218 = \begin{array}{lll}
\text{Step 1:} & (8-2) \times 100 & 600 \\
\text{Step 2:} & 600 - 6 & \mathbf{594} \\
\text{Answer:} & & \mathbf{594}
\end{array}
$$

It also works for when the subtraction is a negative number, but you need to be careful:

$$
105 - 501 = \begin{array}{lll}
\text{Step 1:} & (1-5) \times 100 & -400 \\
\text{Step 2:} & -400 - (1-5) & \mathbf{-396} \\
\text{Answer:} & & \mathbf{-396}
\end{array}
$$

Negative signs are where this goes wrong, so it is worth reversing the subtraction instead: $105 - 501 = -(501 - 105) = -396$. By negating and reversing the numbers, you deal with positive numbers which are naturally more manageable. After you find the solution, you negate the result because of the sign switch.
