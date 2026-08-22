# Performing Operations in Other Bases

Addition, subtraction, and multiplication work in any base exactly like base-10, except carries/borrows move in groups of $n$ instead of groups of $10$.

**Addition:** add digit by digit; whenever a column reaches $n$ or more, carry 1 to the next column and keep the remainder. For example, in base 6:

$$
124_6 + 53_6: \quad 4_6+3_6=7_{10}=11_6 \ (\text{write } 1,\text{ carry }1),\ \ 2_6+5_6+1=8_{10}=12_6\ (\text{write }2,\text{ carry }1),\ \ 1+1=2
$$

$$
124_6 + 53_6 = \mathbf{221_6}
$$

**Subtraction:** borrow the same way, but a borrow adds $n$ (not 10) to the digit you're subtracting from. For example, $122_4 - 13_4$: the last digit needs $2-3$, so borrow, making it $(4+2)-3=3\text{;}$ the next digit is now $2-1-1=0\text{;}$ the top digit is $1$, giving $\mathbf{103_4}$.

**Multiplication:** multiply the digits pairwise in ordinary base-10 (like FOIL/long multiplication), then convert each partial result to base $n$ and carry as needed. For example, $13_9 \times 21_9$: units digit $3\times1=3\text{;}$ next $1\times1+2\times3=7\text{;}$ next $2\times1=2$ — giving $\mathbf{273_9}$ (no carries needed since each partial product stayed under 9).

The safest fallback for any of these — especially division, which is rarely tested — is to convert both numbers to base 10, do the arithmetic normally, then convert the result back to base $n$. This is slower but always correct, and worth using as a check when the direct method gets messy.

**Division in base $n$:** convert the dividend and divisor to base 10, divide as ordinary integers, then convert the resulting quotient back to base $n$ digit by digit (repeatedly divide by $n$ and read off the remainders from last to first, or just build the base-$n$ digits from place values).

Worked example: $431_5 \div 4_5$. Convert both to base 10: $431_5 = 4(25)+3(5)+1 = 116$, and $4_5 = 4$. Then $116 \div 4 = 29$ in base 10. Converting $29$ back to base 5: $29 = 1(25) + 0(5) + 4(1)$, so $29_{10} = 104_5$. Thus $431_5 \div 4_5 = \mathbf{104_5}$, matching the stored answer of $104\text{.}$

A second check with a smaller case: $26_9 \div 6_9$. Base 10: $26_9 = 2(9)+6=24$, and $6_9=6$, so $24 \div 6 = 4$, which is a single digit in any base, giving $26_9 \div 6_9 = \mathbf{4}$.

If the division comes out exact (as it will on the test), you can also divide digit-by-digit left to right the same way you would do long division in base 10, just remembering that each digit only ranges from $0$ to $n-1$ and any "bring-down" step is read as a base-$n$ number before dividing.
