# Distance Between Two Parallel Lines

Two lines are parallel exactly when they share the same $a$ and $b$ coefficients: $ax+by+c_1=0$ and $ax+by+c_2=0$. The distance between them is:

$$
d = \frac{|c_1 - c_2|}{\sqrt{a^2+b^2}}
$$

This is a simplified case of the point-to-line distance formula: since both lines have identical $a$ and $b$, the only thing that differs between them is the constant term, so the numerator collapses to just the difference of the two constants.

**Example:** Find the distance between $3x - 4y = 8$ and $3x - 4y = 3$.

Rewrite both in $ax+by+c=0$ form: $c_1 = -8$, $c_2 = -3$.

$$
d = \frac{|-8-(-3)|}{\sqrt{3^2+4^2}} = \frac{|-5|}{5} = \frac{5}{5} = 1
$$

**Shortcut:** since both lines already share $ax+by$, you can skip rewriting to the $=0$ form and just take the absolute difference of the right-hand-side constants directly: for $3x+4y=-1$ and $3x+4y=6$, the difference is $|(-1)-6| = 7$, so $d = \frac{7}{\sqrt{3^2+4^2}} = \frac{7}{5}$.

As with the point-to-line formula, the denominator is usually a recognizable Pythagorean triple ($3,4,5$ or $5,12,13\text{)}$, and the answer may be a whole number or a fraction depending on whether $|c_1-c_2|$ divides evenly by that hypotenuse.
