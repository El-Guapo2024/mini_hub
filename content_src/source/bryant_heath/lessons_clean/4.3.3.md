# Adding Odd or Even Terms of Arbitrary Fibonacci Sequence

The derivations are pretty lengthy, so let's just look at the results.

For the sum of the odd terms (e.g., $A_1, A_3$, etc.) of an Arbitrary Fibonacci Sequence:

$$
\sum_{i=1}^{n} A_{2i-1} = A_1 + A_3 + A_5 + \ldots + A_{2n-1} = A_{2n} - (A_2 - A_1)
$$

What this means is that the sum is equal to the next term in the complete sequence (which will be an *even* term) with the difference between the first and second terms subtracted from it. Using the example sequence of 4, 7, 11, 18, 29, 47, ..., the sum of the first 3 odd terms $(4, 11, 29)$ is:

$$
\sum = A_6 - (A_2 - A_1) = 47 - (7 - 4) = 44
$$

For the sum of the even terms (e.g., $A_2, A_4$, etc.) of an Arbitrary Fibonacci Sequence:

$$
\sum_{i=1}^{n} A_{2i} = A_2 + A_4 + A_6 + \ldots + A_{2n} = A_{2n+1} - A_1
$$

What this means is that the sum is equal to the next term in the complete sequence (which will be an *odd* term) with the first term subtracted from it. Using the example sequence of 4, 7, 11, 18, 29, 47, ..., the sum of the first 3 even terms $(7, 18, 47)$ is:

$$
\sum = A_7 - A_1 = 76 - 4 = 72
$$

In order to use the formulas, you'll need to either have a long list of terms given in the problem statement *or* they'll ask about the Standard Fibonacci Sequence, for which you'd have the next term memorized to help with the calculations.

The sum of the first 7 odd terms of the Standard Fibonacci Sequence:

$$
\sum = F_1 + F_3 + \ldots + F_{13} = F_{14} - (F_2 - F_1) = 377 - (1 - 1) = \mathbf{377}
$$

The sum of the first 5 even terms of the Standard Fibonacci Sequence:

$$
\sum = F_2 + F_4 + \ldots + F_{10} = F_{11} - F_1 = 89 - 1 = \mathbf{88}
$$
