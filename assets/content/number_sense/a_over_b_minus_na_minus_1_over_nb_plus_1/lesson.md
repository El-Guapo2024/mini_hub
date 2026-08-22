# a/b − (na−1)/(nb+1) Trick

The following deals with subtracting fractions in the form $\frac{a}{b} - \frac{na-1}{nb+1}$. Most of these problems are on the $3^{rd}$ or $4^{th}$ columns, and they are relatively easy to pick out because of how absurd the problem would be if you didn't know the formula:

$$
\frac{a}{b} - \frac{na-1}{nb+1} = \frac{(a+b)}{b \cdot (nb+1)}
$$

So the numerator of the answer is just the sum of the numerator and denominator of the first number (e.g., the number who's numerator and denominators are small values) while the denominator of the answer is just the multiplication of the two denominators. Here is an example:

$$
\frac{6}{7} - \frac{29}{36} = \frac{6+7}{7 \cdot 36} = \frac{\mathbf{13}}{\mathbf{252}}
$$

This shape is easy to spot, which matters: without the formula it is slow to do any other way.

There is one variation to the formula which is:

$$
\frac{a}{b} - \frac{na+1}{nb-1} = \frac{-(a+b)}{b \cdot (nb-1)}
$$

When approached with these problems, it is best to take time to notice which type it is. The easiest way of seeing which formula to apply is to look at the denominator of the more "complicated" number and see if it is one *greater* or one *less* than a multiple of the denominator of the "simple" number. Here's an example:

$$
\frac{7}{11} - \frac{43}{65} = \frac{-(7+11)}{11 \cdot 65} = \frac{-\mathbf{18}}{\mathbf{715}}
$$

So on the above question, notice that 65 is one less a multiple of 11, so you know to apply the second formula.
