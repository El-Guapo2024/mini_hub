# Dividing by 9 Trick

The Remainder by 3, 9 topic explains how a remainder can be found when dividing by 9. However, you can continue this process of adding *select* digits to get the complete answer when dividing by 9. The following is the result when you divide a four digit number $abcd$ by 9 without carries. The details of the proof is omitted, only the result is shown:

$$
abcd \div 9 = \begin{array}{ll}
\text{Fractional Part:} & \dfrac{a+b+c+d}{9} \\[6pt]
\text{Ones:} & a+b+c \\[4pt]
\text{Tens:} & a+b \\[4pt]
\text{Hundreds:} & a
\end{array}
$$

Here is a simple example:

$$
3211 \div 9 = \begin{array}{lll}
\text{Fractional Part:} & \dfrac{1+1+2+3}{9} & \mathbf{\dfrac{7}{9}} \\[8pt]
\text{Ones:} & 1+2+3 & \mathbf{6} \\[4pt]
\text{Tens:} & 2+3 & \mathbf{5} \\[4pt]
\text{Hundreds:} & 3 & \mathbf{3} \\[4pt]
\text{Answer:} & & \mathbf{356\dfrac{7}{9}}
\end{array}
$$

Here is a little bit more complicated of a problem involving a larger number being divided as well as incorporating carries:

$$
32257 \div 9 = \begin{array}{lll}
\text{Fractional Part:} & \dfrac{7+5+2+2+3}{9} & 2\mathbf{\dfrac{1}{9}} \\[8pt]
\text{Ones:} & 5+2+2+3+\mathit{2} & \mathit{1}\mathbf{4} \\[4pt]
\text{Tens:} & 2+2+3+\mathit{1} & \mathbf{8} \\[4pt]
\text{Hundreds:} & 2+3 & \mathbf{5} \\[4pt]
\text{Thousands:} & 3 & \mathbf{3} \\[4pt]
\text{Answer:} & & \mathbf{3584\dfrac{1}{9}}
\end{array}
$$
