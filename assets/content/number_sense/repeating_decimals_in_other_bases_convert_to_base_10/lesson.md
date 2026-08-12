# Repeating Decimals in Other Bases - Convert to Base 10

There are two types of questions involving converting repeating decimals in other bases. The first asks you to convert them into a base-10 fraction while the second asks you to keep the base the same as the repeating decimal. We'll tackle the base-10 conversion here and in the next section we'll look at keeping the bases the same. We'll start off with a simple type of conversion where you only need to use the sum of an infinite geometric series (Section 2.2.1) in order to solve. Here is an example of that type:

$$
\text{Change } .555\ldots_8 \text{ to a base-10 fraction.}
$$

For these types of problems, you can apply the change of base (as explained in Section 3.2.2) to produce an infinite geometric series which you can then sum using the well-known formula:

$$
.555\ldots_8 = \frac{5}{8} + \frac{5}{64} + \frac{5}{512} + \cdots
= \frac{\dfrac{5}{8}}{1 - \dfrac{1}{8}}
= \frac{5}{8} \times \frac{8}{7} = \mathbf{\frac{5}{7}}
$$

Although these problems look pretty intimidating they are pretty straightforward to solve. Now there is a more complicated form of the repeated decimal problem that uses a general variant of all the procedures outlined in Section 3.3.2 and Section 3.3.3 (because of the complexity, it is hard to imagine they'd do something like Section 3.3.4, but you can certainly extend these methods to come up with a procedure).

For instance, for a repeating fraction in the form $.\overline{xyxy}_b$, with base $b$, the procedure for converting to a base-10 fraction is:

1. For the numerator, convert the two-digit number $xy$ into base-10.
2. The denominator is $(b^2 - 1)$.
3. Reduce the fraction if necessary.

**Problem:** Change $.353535\ldots_8$ to a base-10 fraction.

*Solution:* Numerator: $35_8 = 29_{10}\text{;}$ Denominator: $8^2 - 1 = 63$. So your answer is: $\dfrac{29}{63}$

For a repeating fraction in the form $.x\overline{yyyy}_b$, the procedure is:

1. For the numerator, convert the two-digit number $xy$ into base-10 and subtract $x$ from it.
2. For the denominator, it is $b(b-1)$.
3. Reduce the fraction if necessary.

**Problem:** Change $.3555\ldots_8$ to a base-10 fraction.

*Solution:* Numerator: $35_8 - 3_8 = 26_{10}\text{;}$ Denominator: $8(8-1) = 56$. So your answer is: $\dfrac{26}{56} \Rightarrow \dfrac{13}{28}$
