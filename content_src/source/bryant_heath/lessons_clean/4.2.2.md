# Exotic Definitions of Numbers

These are additional classifications of numbers (similar to Section 3.1.2) that appear on recent Number Sense exams.

1. A **happy number** is a number whose sum of the squares of the individual digits eventually leads to a chain that terminates at 1. For example, 19 is a happy number because $19 \Rightarrow 1^2 + 9^2 = 82 \Rightarrow 8^2 + 2^2 = 68 \Rightarrow 6^2 + 8^2 = 100 \Rightarrow 1^2 + 0^2 + 0^2 = \mathbf{1}$. The first handful of happy numbers are 1, 7, 10, 13, 19, 23, 28, 31, 32, 44, 49, 68, 70, 79, 82, 86, 91, 94, 97, and 100.

2. An **extravagant/wasteful number** is a number whose prime factorization has more digits than the number itself (treating both the base and exponents as individual digits). For example, 18 is extravagant because $18 = 2 \times 3^2$, so 18 contains 2 digits and its prime factorization contains 3 digits. The first handful of extravagant numbers are 4, 6, 8, 9, 12, 18, 20, 22, 24, 26, 28, 30, 33, 34, 36, 38, 39, 40, 42, 44, 45, 46, 48, 50.

3. An **economical/frugal number** is the opposite of an extravagant number: its prime factorization contains fewer digits than the number itself. For example, 128 is economical because $128 = 2^7$, so 128 contains 3 digits and its prime factorization contains 2 digits. Unsurprisingly, cubes and higher powers of 2 and 3 are economical.

4. An **odious number** is a non-negative number whose binary representation has an odd number of 1s. For example, $7 = 111_2$ which has 3 ones in its binary representation.

5. An **evil number** is the opposite of an odious number: it has an even number of 1s. For example, $9 = 1001_2$ which has 2 ones.

All of these (and more) can be found in the On-Line Encyclopedia of Integer Sequences (OEIS).
