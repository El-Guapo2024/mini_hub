# Adding Consecutive Terms of Arbitrary Fibonacci Sequence, Method 1

This is a common question where the test writer will give the beginning and end terms of an Arbitrary Fibonacci Sequence and ask for the sum of a subset of the terms. An example is finding the sum of 4, 7, 11, ..., 47, and 76.

The trick uses the telescoping properties of the recursion relation of the Fibonacci sequence. Knowing that $A_n = A_{n-1} + A_{n-2}$, rearranging yields $A_{n-2} = A_n - A_{n-1}$. From here you can see the following:

$$
\begin{aligned}
A_1 &= A_3 - A_2 \\
A_2 &= A_4 - A_3 \\
A_3 &= A_5 - A_4 \\
A_4 &= A_6 - A_5 \\
A_5 &= A_7 - A_6 \\
A_6 &= A_8 - A_7 \\
A_7 &= A_9 - A_8
\end{aligned}
$$

Summing both the left and right-hand sides of all these equations produces the telescoping series:

$$
\begin{aligned}
A_1 + A_2 + A_3 + \ldots + A_7 \\
&= (A_3 - A_2) + (A_4 - A_3) + (A_5 - A_4) + \ldots + (A_9 - A_8) \\
&= A_9 - A_2
\end{aligned}
$$

So in general, when you are summing up an Arbitrary Fibonacci Sequence (starting from the first term), the sum of the first $n$ terms is simply $A_{n+2} - A_2$. Using that fact and applying it to our example question, we just need to find $A_9 - A_2$. We are given up to $A_5$, so all you have to keep straight is appropriately summing up to the ninth term:

$$
A_6 = 47 \text{ and } A_7 = 76 \Rightarrow A_8 = 76 + 47 = 123 \Rightarrow A_9 = 123 + 76 = 199
$$

Therefore the sum is $= 199 - 7 = \mathbf{192}$. The real difficulty with these problems is keeping your previous two Fibonacci numbers in your head in order to find the next term. There is unquestionably a lot of bookkeeping involved, so this method is best if the test writer explicitly writes *most* of the sequence in the problem statement. That way, you only have to compute two or three additional terms before applying the formula to find the sum.
