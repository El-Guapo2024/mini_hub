# Triangular Numbers

We are all familiar with the concept of square numbers $1, 4, 9, 16, \ldots, n^2$ and have a vague idea of how they can be viewed geometrically ($n^2$ can be represented by $n$ rows of dots by $n$ columns of dots). This same concept of translating "dots to numbers" can extend to any regular polygon. For example, the idea of a triangular number is the amount of dots which can be arranged into an equilateral triangle ($1, 3, 6, \ldots\text{)}$. The following are formulas for these "geometric" numbers:

$$
\begin{array}{ll}
\text{Triangular:} & T_n = \dfrac{n(n+1)}{2} \\[8pt]
\text{Square:} & S_n = \dfrac{n(2n-0)}{2} = n^2 \\[8pt]
\text{Pentagonal:} & P_n = \dfrac{n(3n-1)}{2} \\[8pt]
\text{Hexagonal:} & H_n = \dfrac{n(4n-2)}{2} \\[8pt]
\text{Heptagonal:} & E_n = \dfrac{n(5n-3)}{2} \\[8pt]
\text{Octagonal:} & O_n = \dfrac{n(6n-4)}{2} \\[8pt]
\text{M-Gonal:} & M_n = \dfrac{n[(M-2)n-(M-4)]}{2}
\end{array}
$$

As one can see, only the last formula is necessary for memorization (all the others can be derived from that one).

Some other useful formulas:

**Sum of Consecutive Triangular Numbers:** $T_{n-1} + T_n = n^2$

**Sum of First $m$ Triangular Numbers:** $\displaystyle\sum_{n=1}^{m} T_n = T_1 + T_2 + \cdots + T_m = \frac{m(m+1)(m+2)}{6}$

**Sum of the Same Triangular and Pentagonal Numbers:** $T_n + P_n = 2n^2$

**Examples:**

1. The 6th Triangular Number: $\dfrac{6(6+1)}{2} = \mathbf{21}$

2. The 4th Octagonal Number: $\dfrac{4(6 \cdot 4 - 4)}{2} = \dfrac{4 \cdot 20}{2} = \mathbf{40}$

3. The 5th Pentagonal Number: $\dfrac{5(3 \cdot 5 - 1)}{2} = \dfrac{5 \cdot 14}{2} = \mathbf{35}$

4. The Sum of the 6th and 7th Triangular Numbers: $7^2 = \mathbf{49}$
