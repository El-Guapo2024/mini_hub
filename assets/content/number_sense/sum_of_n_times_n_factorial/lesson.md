# Sum of Factorials: 1·1! + 2·2! + ⋯ + n·n!

The sum $1 \cdot 1! + 2 \cdot 2! + \cdots + n \cdot n!$ has a closed form (derivation left to the reader):

$$
1 \cdot 1! + 2 \cdot 2! + \cdots + n \cdot n! = (n+1)! - 1
$$

The simplest case is computing a full sum up to $n$:

$$
1 \cdot 1! + 2 \cdot 2! + 3 \cdot 3! + 4 \cdot 4! = (4+1)! - 1 = 120 - 1 = \mathbf{119}
$$

There are slight variations where some terms are left out. In that case, apply the formula to the highest term present, then subtract the missing terms using the same formula:

$$
\begin{aligned}
1 \cdot 1! + 3 \cdot 3! + 5 \cdot 5! \\
&= (5+1)! - 1 - 2 \cdot 2! - 4 \cdot 4! \\
&= 720 - 1 - 4 - 96 \\
&= \mathbf{619}
\end{aligned}
$$
