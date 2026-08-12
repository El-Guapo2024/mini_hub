# Number of Prime Integral Divisors

The following are formulas dealing with integral divisors. On all the formulas, it is necessary to prime factorize the number of interest such that $n = p_1^{e_1} \cdot p_2^{e_2} \cdot p_3^{e_3} \cdots p_n^{e_n}$.

**Number of Prime Integral Divisors**

Number of prime integral divisors can be found by simply prime factorizing the number, and counting how many distinct prime numbers $(p_1, p_2, \ldots)$ you have in its representation.

*Example:* Find the number of prime integral divisors of 120.

$$
120 = 2^3 \cdot 3 \cdot 5 \implies \text{\# of prime divisors} = (1 + 1 + 1) = \mathbf{3}
$$

**Number of Integral Divisors**

$$
\text{Number of Integral Divisors} = (e_1 + 1) \cdot (e_2 + 1) \cdot (e_3 + 1) \cdots (e_n + 1)
$$

*Example:* Find the number of integral divisors of 48.

$$
48 = 2^4 \cdot 3^1 \implies (4+1) \cdot (1+1) = \mathbf{10}
$$

**Sum of the Integral Divisors**

$$
\begin{aligned}
\sum \\
&= \frac{p_1^{e_1+1} - 1}{p_1 - 1} \cdot \frac{p_2^{e_2+1} - 1}{p_2 - 1} \cdots \frac{p_n^{e_n+1} - 1}{p_n - 1}
\end{aligned}
$$

*Example:* Find the sum of the integral divisors of 36.

$$
36 = 2^2 \cdot 3^2
$$

$$
\begin{aligned}
\sum \\
&= \frac{2^3 - 1}{2 - 1} \cdot \frac{3^3 - 1}{3 - 1} \\
&= \frac{7}{1} \cdot \frac{26}{2} \\
&= 7 \cdot 13 \\
&= \mathbf{91}
\end{aligned}
$$

**Number of Relatively Prime Integers less than** $n$

$$
\begin{aligned}
\text{Number of Relatively Prime} \\
&= (p_1 - 1) \cdot (p_2 - 1) \cdots (p_n - 1) \cdot (p_1^{e_1 - 1}) \cdot (p_2^{e_2 - 1}) \cdots (p_n^{e_n - 1})
\end{aligned}
$$

or equivalently:

$$
\begin{aligned}
\text{Number of Relatively Prime} \\
&= \frac{p_1 - 1}{p_1} \cdot \frac{p_2 - 1}{p_2} \cdots \frac{p_n - 1}{p_n} \times n
\end{aligned}
$$

Both techniques are relatively quick and you should do whichever you feel comfortable with. Here is an example to display both methods:

*Example:* Find the number of relatively prime integers less than 20.

$$
20 = 2^2 \cdot 5
$$

$$
\text{\# of Relatively Prime Integers} = (2-1)(5-1)(2^{2-1})(5^{1-1}) = 4 \cdot 2 = \mathbf{8}
$$

or

$$
\text{\# of Relatively Prime Integers} = \frac{1}{2} \cdot \frac{4}{5} \times 20 = \mathbf{8}
$$

**Sum of Relatively Prime Integers less than** $n$

$$
\sum = (\text{\# of Relatively Prime Integers}) \times \frac{n}{2}
$$

*Example:* Find the sum of the relatively prime integers less than 24.

$$
24 = 2^3 \cdot 3
$$

$$
\text{\# of Relatively Prime Integers} = \frac{1}{2} \cdot \frac{2}{3} \times 24 = 8
$$

$$
\sum = 8 \times \frac{24}{2} = 8 \cdot 12 = \mathbf{96}
$$

We should introduce a distinction between proper and improper integral divisors here. A proper integral divisor is any positive integral divisor of the number excluding the number itself. So for example, the number 14 has 4 total integral divisors $(1, 2, 7, 14)$, but only 3 proper integral divisors $(1, 2, 7)$. Some number sense questions will ask for the sum of proper integral divisors or the number of proper integral divisors of a number. When those are asked, you need to be aware to *exclude* the number itself from those calculations. For example, the sum of the proper integral divisors of $22 = 3 \times 12 - 22 = 36 - 22 = \mathbf{14}$.

In addition, on the questions asking for the number of co-prime (or relatively prime) within a range of values, it is best to calculate the total number of relatively prime integers and then start excluding ones that are out of range. For example, to calculate the number of integers greater than three which are co-prime to 20 you would find the number of co-prime integers less than 20 which is $(2-1)(5-1)(2^{2-1})(5^{1-1}) = 8$ then you can exclude the numbers 1 and 3. So the number of integers greater than three which are co-prime to 20 would be $8 - 2 = 6$. The quickest way of finding whether or not an integer is co-prime to another integer, is to put it in fraction form and see if the fraction is reducible. For example, 3 is co-prime to 20 because $\frac{3}{20}$ is irreducible.

With integral divisor problems it is best to get a lot of practice so that better efficiency can be reached.
