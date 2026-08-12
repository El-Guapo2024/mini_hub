# Adding Consecutive Terms of Arbitrary Fibonacci Sequence, Method 2

The other way of doing the sum of the terms of an Arbitrary Fibonacci Sequence — especially if you are given few terms in the problem statement — involves using your knowledge of the Standard Fibonacci Sequence, $F_n$. The derivation is lengthy, but you can calculate the sum of the first $n$ terms of an Arbitrary Fibonacci Sequence $(A_n)$ using the following formula:

$$
\sum = A_1 \times F_n + A_2 \times (F_{n+1} - 1)
$$

So taking the example from the previous section, you can find the sum of the first 7 terms of 4, 7, 11, ..., 47, 76 by:

$$
\sum = 4 \times F_7 + 7 \times (F_8 - 1) = 4 \times 13 + 7 \times (21 - 1) = 52 + 140 = \mathbf{192}
$$

This method is calculation-intensive (you have to have your Standard Fibonacci Numbers memorized, perform two multiplications, and then sum everything up), but you don't have to worry about actually *finding* any terms in the sequence. Either way is difficult, so it's best to find the one that works for you and really practice it well.
