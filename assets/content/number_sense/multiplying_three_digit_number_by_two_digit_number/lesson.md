# Multiplying a Three-Digit Number by a Two-Digit Number

This technique extends FOILing/LIOFing to three-digit by two-digit multiplication. Let $n_1 = abc$ and $n_2 = ef$, where $a, b, c, e, f$ are digits.

The key insight is to treat $n_2$ as a three-digit number $0ef$, group $bc$ and $ef$ as two-digit units, and perform a FOIL/LIOF:

$$
abc = 100a + (bc), \quad 0ef = 100 \cdot 0 + (ef)
$$

$$
[100a + (bc)] \times [100 \cdot 0 + (ef)] = 100a(ef) + 0 \cdot (bc) + (bc)(ef)
$$

which simplifies to:

$$
100a(ef) + (bc)(ef)
$$

This tells us three things:

1. The ones and tens digits of the answer are the last two digits of $(bc) \times (ef)$.
2. There will almost always be a carry — possibly a two-digit carry — from that multiplication.
3. The remaining digits are $a \times ef$ plus the carry.

**Example (simple carry):**

$$
117 \times 15 = \begin{cases} \text{Units and Tens:} & 17 \times 15 = 2\mathbf{55} \\
\text{Remaining:} & 1 \times 15 + 2 = \mathbf{17} \end{cases} \quad \Rightarrow \quad \mathbf{1755}
$$

**Example (two-digit carry):**

$$
233 \times 37 = \begin{cases} \text{Units and Tens:} & 33 \times 37 = 12\mathbf{21} \\
\text{Remaining:} & 2 \times 37 + 12 = \mathbf{86} \end{cases} \quad \Rightarrow \quad \mathbf{8621}
$$

In the second example the carry is two digits because $33 \times 37$ produces a four-digit number. Other tricks (e.g., Multiplying Two Numbers Equidistant from a Third Number, or Squares Ending in 5) can be used for the inner multiplication step.
