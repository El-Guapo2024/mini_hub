# Squares from 41–59 Trick

There is a quick trick for easy computation for squares from $41 - 59$. Let $k$ be a 1-digit integer, then any of those squares can be expressed as $(50 \pm k)$:

$$
(50 \pm k)^2 = 2500 \pm 100 \cdot k + k^2 = 100(25 \pm k) + k^2
$$

What this means is that:

1. The tens/ones digits is just the difference the number is from 50, squared ($k^2\text{)}$.

2. The remainder of the answer is taken by *adding* (if the number is greater than 50) or *subtracting* (if the number is less than 50) that difference from 25.

3. Note: You could extend this concept to squares outside the range of $41 - 59$ as long as you keep up with the carry appropriately.

Let's illustrate with a couple of examples:

$$
46^2 = \begin{array}{ll}
\text{Tens/Ones:}     & (50 - 46)^2 = 4^2 & \mathbf{16} \\
\text{Rest of Answer:}& 25 - 4 & \mathbf{21} \\
\text{Answer:}        & & \mathbf{2116}
\end{array}
$$

$$
57^2 = \begin{array}{ll}
\text{Tens/Ones:}     & (57 - 50)^2 = 7^2 & \mathbf{49} \\
\text{Rest of Answer:}& 25 + 7 & \mathbf{32} \\
\text{Answer:}        & & \mathbf{3249}
\end{array}
$$

$$
61^2 = \begin{array}{ll}
\text{Tens/Ones:}     & (61 - 50)^2 = 11^2 & \mathit{1}\mathbf{21} \\
\text{Rest of Answer:}& 25 + 11 + 1 & \mathbf{37} \\
\text{Answer:}        & & \mathbf{3721}
\end{array}
$$
