# Changing Between Bases: Special Case

Normally converting between two bases means going through base 10 as a middle step. But when one base is an integer power of the other (say base $n = m^a\text{)}$, you can skip base 10 entirely: split the base-$m$ digits into groups of $a$ (from the right) and convert each group directly to a single base-$n$ digit.

**Example:** convert $1001001_2$ to base 4. Since $4 = 2^2$, group the binary digits in pairs from the right: $1\,00\,10\,01$. Convert each pair to base 4:

$$
01_2 = 1_4 \qquad 10_2 = 2_4 \qquad 00_2 = 0_4 \qquad 1_2 = 1_4
$$

Reading the groups in order gives $1001001_2 = 1021_4$.

**Cube relationship:** since $8 = 2^3$, group binary digits in threes. Converting $110001011_2$ to base 8: split into $110\,001\,011$, giving $6_8, 1_8, 3_8$, so the answer is $613_8$.

**Works in reverse too:** converting from base $9$ to base $3$ (since $9=3^2\text{)}$, expand each base-9 digit into a two-digit base-3 number. Converting $643_9$ to base 3: $6_9=20_3$, $4_9=11_3$, $3_9=10_3$, giving $643_9 = 201110_3$.

The key recognition step is checking whether one base is a power of the other ($4=2^2$, $8=2^3$, $9=3^2$, $16=2^4$, etc.) — once you spot that relationship, you never need to touch base 10.
