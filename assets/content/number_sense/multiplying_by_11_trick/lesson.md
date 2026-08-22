# Multiplying by 11 Trick

The simplest multiplication trick is the 11's trick. It is a mundane version of "moving down the line," where you add consecutive digits and record the answer. Here is an example:

$$
523 \times 11 = \begin{array}{ll}
\text{Ones:}       & 1 \times 3 = \mathbf{3} \\
\text{Tens:}       & 1 \times 2 + 1 \times 3 = \mathbf{5} \\
\text{Hundreds:}   & 1 \times 5 + 1 \times 2 = \mathbf{7} \\
\text{Thousands:}  & 1 \times 5 = \mathbf{5} \\
\text{Answer:}     & \mathbf{5753}
\end{array}
$$

As one can see, the result can be obtained by subsequently adding the digits along the number you're multiplying. Be sure to keep track of the carries as well:

$$
6798 \times 11 = \begin{array}{ll}
\text{Ones:}        & \mathbf{8} \\
\text{Tens:}        & 9 + 8 = \mathit{1}\mathbf{7} \\
\text{Hundreds:}    & 7 + 9 + 1 = \mathit{1}\mathbf{7} \\
\text{Thousands:}   & 6 + 7 + 1 = \mathit{1}\mathbf{4} \\
\text{Ten Thousands:} & 6 + 1 = \mathbf{7} \\
\text{Answer:}      & \mathbf{74778}
\end{array}
$$

The trick can also be extended to 111 or 1111 (and so on). Where as in the 11's trick you are adding pairs of digits "down the line," for 111 you will be adding triples:

$$
6543 \times 111 = \begin{array}{ll}
\text{Ones:}          & \mathbf{3} \\
\text{Tens:}          & 4 + 3 = \mathbf{7} \\
\text{Hundreds:}      & 5 + 4 + 3 = \mathit{1}\mathbf{2} \\
\text{Thousands:}     & 6 + 5 + 4 + 1 = \mathit{1}\mathbf{6} \\
\text{Ten Thousands:} & 6 + 5 + 1 = \mathit{1}\mathbf{2} \\
\text{Hun. Thousands:}& 6 + 1 = \mathbf{7} \\
\text{Answer:}        & \mathbf{726273}
\end{array}
$$

Another common form of the 11's trick is used in reverse. For example:

$$
1353 \div 11 = \quad \text{or} \quad 11 \times x = 1353
$$

$$
\begin{array}{lll}
\text{Ones Digit of } x \text{ is equal to the Ones Digit of 1353:} & & \mathbf{3} \\
\text{Tens Digit of } x \text{ is equal to:} & 5 = 3 + x_{tens} & \mathbf{2} \\
\text{Hundreds Digit of } x \text{ is equal to:} & 3 = 2 + x_{hund} & \mathbf{1} \\
\text{Answer:} & & \mathbf{123}
\end{array}
$$

Similarly you can perform the same procedure with 111, and so on. Let's look at an example:

$$
46731 \div 111 = \quad \text{or} \quad 111 \times x = 46731
$$

$$
\begin{array}{lll}
\text{Ones Digit of } x \text{ is equal to the Ones Digit of 46731:} & & \mathbf{1} \\
\text{Tens Digit of } x \text{ is equal to:} & 3 = 1 + x_{tens} & \mathbf{2} \\
\text{Hundreds Digit of } x \text{ is equal to:} & 7 = 2 + 1 + x_{hund} & \mathbf{4} \\
\text{Answer:} & & \mathbf{421}
\end{array}
$$

The hardest part of the procedure is knowing when to stop. A reliable way is to think about how many digits the answer *should* have. For example, with the above expression, we are dividing a 5-digit number by a roughly 100, leaving an answer which should be 3-digits, so after the third-digit you know you are done.
