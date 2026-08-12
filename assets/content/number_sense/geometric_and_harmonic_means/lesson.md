# Geometric and Harmonic Means

Geometric, $G_n$, and harmonic, $H_n$, means are starting to be asked on Number Sense exams in a variety of ways. The formulas are:

$$
G_n = \sqrt[n]{x_1 x_2 \cdots x_n} \quad \text{where } x_1, x_2, \ldots, x_n \text{ are values}
$$

$$
\begin{aligned}
H_n \\
&= \frac{n}{\left(\dfrac{1}{x_1} + \dfrac{1}{x_2} + \cdots + \dfrac{1}{x_n}\right)} \quad \text{where } x_1, x_2, \ldots, x_n \text{ are values}
\end{aligned}
$$

Questions asking about geometric means are pretty straightforward. For instance, the geometric mean of 6, 4, and 9 is $\sqrt[3]{6 \times 4 \times 9} = \sqrt[3]{216} = 6$. One interesting application (for the UIL Mathematics Exam) is that the altitude of a right triangle to its hypotenuse is the geometric mean of the two segments the hypotenuse is split into.

As for the harmonic mean, there are two different types of questions. The first involves asking what the harmonic mean of the roots of a cubic polynomial are. Assuming the roots are $r$, $s$, and $t$, applying the formula yields:

$$
H_3 = \frac{3}{\left(\dfrac{1}{r} + \dfrac{1}{s} + \dfrac{1}{t}\right)} = \frac{3pqr}{pq + pr + qr}
$$

So you can relate the harmonic mean of the roots to the product of the roots and the sum of roots taken two at a time (similar to what we found with the Vieta/Newton Factorization in Section 4.4.2). You'll need to familiarize yourself with Section 3.1.4 in order to determine what these sums are. Here is an example:

**Problem:** What is the harmonic mean of the roots of $x^3 + 2x^2 - 3x + 7 = 0$?

*Solution:* Applying the formula: $H_3 = \dfrac{3 \cdot (-7)}{-3} = 7$

The second interpretation of harmonic mean is the classic dual-labor problem. For example: Joe can paint a house in 5 hours and Jane can paint a house in 3 hours; how many hours does it take for both of them to paint a house? The answer is simply one-half of the harmonic mean:

$$
\begin{aligned}
\text{Together: } \frac{1}{2} \times \frac{2}{\left(\dfrac{1}{5} + \dfrac{1}{3}\right)} \\
&= 1\frac{7}{8} \text{ hours}
\end{aligned}
$$

This interpretation is also known as the "Crossed Ladder Problem" (e.g., two ladders are crossed; what is the height at the crossing point).
