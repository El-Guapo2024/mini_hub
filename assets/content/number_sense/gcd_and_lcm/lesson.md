# GCD and LCM

How finding the Greatest Common Divisor (or GCD) is taught in classes usually involves prime factorizing the two numbers and then comparing powers of exponents. However, this is not the most efficient way of doing it during a number sense competition. One of the quickest ways of doing it is by employing Euclid's Algorithm. The following outlines the procedure:

1. Arrange the numbers so that $n_1 < n_2$, then find the remainder when $n_2$ is divided by $n_1$ and call it $r_1$.
2. Now divide $n_1$ by $r_1$ and get a remainder of $r_2$.
3. Continue the procedure until any of the remainders are 0 and the number you are dividing by is the GCD, or when you notice what the GCD of any pair of numbers is.

For example, $\text{GCD}(36, 60)$: when 60 is divided by 36 it leaves a remainder of 24, so $\text{GCD}(36,60) = \text{GCD}(24,36)$. Continuing the procedure, when 36 is divided by 24 it leaves a remainder of 12, so $\text{GCD}(24,36) = \text{GCD}(12,24)$, which from here you can tell the GCD is $\mathbf{12}$.

Another example: $\text{GCD}(108,140) \to \text{GCD}(32,108) \to \text{GCD}(12,32) \to \text{GCD}(8,12) \to \text{GCD}(4,8) = \mathbf{4}$.

If at any point in the process you notice what the GCD of the two numbers is by observation, you can cut down on the amount of steps in computation.

For computing the LCM between two numbers $a$ and $b$, use the formula:

$$
\text{LCM}(a, b) = \frac{a \times b}{\text{GCD}(a, b)}
$$

So to find the LCM, first compute the GCD. For example:

$$
\text{LCM}(36, 60) = \frac{36 \times 60}{12} = 3 \times 60 = \mathbf{180}
$$

Another example: $\text{GCD}(44,84) = \text{GCD}(40,44) = \text{GCD}(4,40) = 4$, so

$$
\text{LCM}(44,84) = \frac{44 \times 84}{4} = 11 \times 84 = \mathbf{924}
$$

For the GCD of more than two numbers (usually no more than three), the procedure is:

1. Find the GCD of two of the numbers.
2. Find the LCM of those two numbers using the GCD and the formula above.
3. Calculate the GCD of the LCM of those two numbers and the third number.

It should be noted that usually one of the numbers is a multiple of another, thus leaving less required calculations (because the LCM between two numbers which are multiples of each other is just the larger of the two numbers).
