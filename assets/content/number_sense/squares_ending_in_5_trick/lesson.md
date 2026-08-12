# Squares Ending in 5 Trick

Here is the derivation for this trick. Let $a5$ represent any number ending in 5 ($a$ could be any integer, not just restricted to a one-digit number).

$$
(a5)^2 = (10a + 5)^2 = 100a^2 + 100a + 25 = 100a(a + 1) + 25
$$

So you can tell from this that any number ending in 5 squared will have its last two digits equal to 25 and the remainder of the digits can be found from taking the leading digit(s) and multiplying it by one greater than itself. Here are a couple of examples:

$$
85^2 = \begin{array}{ll}
\text{Tens/Ones:}         & & \mathbf{25} \\
\text{Thousand/Hundreds:} & 8 \times (8 + 1) & \mathbf{72} \\
\text{Answer:}            & & \mathbf{7225}
\end{array}
$$

The next example shows how to compute $15^4$ by applying the square ending in 5 trick twice, one time to get what $15^2$ is then the other to get that result squared.

$$
15^2 = \begin{array}{ll}
\text{Tens/Ones:}         & & \mathbf{25} \\
\text{Thousands/Hundreds:}& 1 \times (1 + 1) = \mathbf{2} \\
\text{Answer:}            & & \mathbf{225}
\end{array}
\qquad
225^2 = \begin{array}{ll}
\text{Tens/Ones:}       & & \mathbf{25} \\
\text{Rest of Answer:}  & 22 \times (23) = 11 \times 46 = \mathbf{506} \\
\text{Answer:}          & & \mathbf{50625}
\end{array}
$$

In the above trick you *also* use the double/half trick *and* the 11's trick. This just shows that for some problems using multiple tricks might be necessary.
