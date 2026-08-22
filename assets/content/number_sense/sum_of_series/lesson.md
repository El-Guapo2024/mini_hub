# Sum of the First m Odd Integers

The following are special series whose sums should be memorized.

**Sum of the First $m$ Integers**

$$
\sum_{n=1}^{m} n = 1 + 2 + 3 + \cdots + m = \frac{m \cdot (m+1)}{2}
$$

*Example:* $1 + 2 + 3 \cdots + 11 = \dfrac{11 \cdot 12}{2} = 66$

**Sum of the First $m$ Odd Integers**

$$
\sum_{n=1}^{m} 2n-1 = 1 + 3 + 5 + \cdots + (2m-1) = \left(\frac{(2m-1)+1}{2}\right)^2 = m^2
$$

*Example:* $1 + 3 + 5 + \cdots + 15 = \left(\dfrac{15+1}{2}\right)^2 = 8^2 = 64$

**Sum of the First $m$ Even Numbers**

$$
\sum_{n=1}^{m} 2n = 2 + 4 + 6 + \cdots + 2m = m \cdot (m+1)
$$

*Example:* $2 + 4 + 6 + \cdots + 22 = \dfrac{22}{2} \cdot \left(\dfrac{22}{2} + 1\right) = 11 \cdot 12 = 132$

**Sum of First $m$ Squares**

$$
\sum_{n=1}^{m} n^2 = 1^2 + 2^2 + \cdots + m^2 = \frac{m \cdot (m+1) \cdot (2m+1)}{6}
$$

*Example:* $1^2 + 2^2 + \cdots + 10^2 = \dfrac{10 \cdot (10+1) \cdot (2 \cdot 10 + 1)}{6} = 35 \cdot 11 = 385$

**Sum of the First $m$ Cubes**

$$
\sum_{n=1}^{m} n^3 = 1^3 + 2^3 + \cdots + m^3 = \left(\frac{m \cdot (m+1)}{2}\right)^2
$$

*Example:* $1^3 + 2^3 + 3^3 + \cdots + 10^3 = \left(\dfrac{10 \cdot 11}{2}\right)^2 = 55^2 = 3025$

**Sum of the First $m$ Alternating Squares**

$$
\sum_{n=1}^{m} (-1)^{n+1} n^2 = 1^2 - 2^2 + 3^2 - \cdots \pm m^2 = \pm\frac{m \cdot (m+1)}{2}
$$

*Examples:*
$1^2 - 2^2 + 3^2 - \cdots + 9^2 = \dfrac{9 \cdot 10}{2} = 45$

$1^2 - 2^2 + 3^2 - \cdots - 12^2 = -\dfrac{12 \cdot 13}{2} = -78$

**Sum of the First $m$ Alternating Cubes**

The same trick applies to cubes, but the pattern splits depending on whether $m$ is odd or even:

$$
\sum_{n=1}^{m} (-1)^{n+1} n^3 = 1^3 - 2^3 + 3^3 - \cdots \pm m^3 =
\begin{cases}
\dfrac{(m+1)^2 (2m-1)}{4} & \text{if } m \text{ is odd} \\
-\dfrac{m^2 (2m+3)}{4} & \text{if } m \text{ is even}
\end{cases}
$$

*Example (odd $m\text{)}$:* $1^3 - 2^3 + 3^3 - 4^3 + 5^3$ has $m = 5$, so:

$$
\frac{(5+1)^2 (2 \cdot 5 - 1)}{4} = \frac{36 \cdot 9}{4} = \mathbf{81}
$$

A question may hand you the terms grouped by parity instead of written in alternating order, such as evens minus odds, or reversed largest-to-smallest. Since addition can be reordered, just rewrite the expression into the standard ascending alternating form first, then apply the formula above.

*Example:* $(6^3 + 4^3 + 2^3) - (5^3 + 3^3 + 1^3)$ is the same value as $-(1^3 - 2^3 + 3^3 - 4^3 + 5^3 - 6^3)$, i.e. the negative of the $m=6$ case:

$$
-\left(-\frac{6^2 (2 \cdot 6 + 3)}{4}\right) = -\left(-\frac{36 \cdot 15}{4}\right) = -(-135) = \mathbf{135}
$$

If the alternating cubes do not start at $n=1$, use the same subtraction idea you would use for any partial sum: compute the full sum up to the last term, and subtract off the full sum up to one term before the first term you want, since the missing early terms cancel out.

*Example:* $3^3 - 4^3 - 2^3 + 5^3$ rearranges to the ascending alternating form $-2^3 + 3^3 - 4^3 + 5^3$, which runs from $n=2$ to $n=5$. Take the $m=5$ total and remove the $m=1$ term:

$$
\left(\frac{6^2 \cdot 9}{4}\right) - \left(\frac{2^2 \cdot 1}{4}\right) = 81 - 1 = \mathbf{80}
$$

**Sum of a General Arithmetic Series**

$$
\sum_{i=1}^{m} a_i = a_1 + a_2 + a_3 + \cdots + a_m = \frac{(a_1 + a_m) \cdot m}{2}
$$

To find the number of terms: $m = \dfrac{a_m - a_1}{d} + 1$, where $d$ is the common difference.

*Example:* $8 + 11 + 14 + \cdots + 35$:

$$
\begin{aligned}
m = \frac{35 - 8}{3} + 1 = 10 \\
\text{So } \sum = \frac{(8+35) \cdot 10}{2} = 43 \cdot 5 = \mathbf{215}
\end{aligned}
$$

**Finding the nth Term of an Arithmetic Sequence**

The term-count formula above can be rearranged to solve for the term value itself instead of the term count. Starting from $m = \dfrac{a_m - a_1}{d} + 1$ and solving for $a_m$:

$$
a_m = a_1 + (m-1) \cdot d
$$

This lets you jump straight to the $m^{\text{th}}$ term of a sequence without listing every term in between: just identify the first term $a_1$, the common difference $d$, and plug in the term number $m$.

*Example:* Find the $25^{\text{th}}$ term of $3, 8, 13, 18, \cdots$. Here $a_1 = 3$ and $d = 5$:

$$
a_{25} = 3 + (25-1) \cdot 5 = 3 + 120 = \mathbf{123}
$$

*Example:* Find the $11^{\text{th}}$ term of $12, 9.5, 7, 4.5, \cdots$. Here $a_1 = 12$ and $d = -2.5$:

$$
a_{11} = 12 + (11-1) \cdot (-2.5) = 12 - 25 = \mathbf{-13}
$$

**Sum of an Infinite Geometric Series**

$$
\sum_{n=0}^{\infty} a_1 \cdot (d)^n = a_1(1 + d + d^2 + \cdots) = \frac{a_1}{1-d}
$$

where $d$ is the common ratio with $|d| < 1$ and $a_1$ is the first term in the series.

*Examples:*

$$
\begin{aligned}
3 + 1 + \frac{1}{3} + \cdots \\
&= \frac{3}{1 - \frac{1}{3}} \\
&= \frac{3}{\frac{2}{3}} \\
&= \mathbf{\frac{9}{2}}
\end{aligned}
$$

$$
\begin{aligned}
4 - 2 + 1 - \frac{1}{2} + \cdots \\
&= \frac{4}{1 - \left(-\frac{1}{2}\right)} \\
&= \frac{4}{\frac{3}{2}} \\
&= \mathbf{\frac{8}{3}}
\end{aligned}
$$

**Special Cases: Factoring**

Sometimes simple factoring can lead to an easier calculation. The following are some examples:

$$
3 + 6 + 9 + \cdots + 33 = 3 \cdot (1 + 2 + \cdots + 11)
= 3\left(\frac{11 \cdot 12}{2}\right)
= 18 \cdot 11 = \mathbf{198}
$$

$$
11 + 33 + 55 + \cdots + 99 = 11 \cdot (1 + 3 + 5 + \cdots + 9)
= 11 \cdot \left(\frac{1+9}{2}\right)^2
= 11 \cdot 25 = \mathbf{275}
$$

Another important question involving sum of integers are word problems which state something similar to: "The sum of three consecutive odd numbers is 129, what is the largest of the numbers?"

In order to solve these problems it is best to know what you are adding. You can represent the sum of the three odd numbers by: $(n-2) + n + (n+2) = 129$. From this you can see that if you divide the number by 3, you will get that the middle integer is 43, thus making the largest integer $43 + 2 = \mathbf{45}$.

Here is another example problem: The sum of four consecutive even numbers is 140, what is the smallest?

For this one you can represent the sum by $(n-2) + (n) + (n+2) + (n+4) = 140$, so dividing the number by 4 will get you the integer *between* the second and third even number. So $140 \div 4 = 35$, so the two middle integers are 34 and 36, making the smallest integer $\mathbf{32}$.

So from this we learned that you can divide the sum by the number of consecutive integers you are adding, and if the number of terms is odd, you get the middle integer, and if the number of terms are even, you get the number between the two middle integers.
