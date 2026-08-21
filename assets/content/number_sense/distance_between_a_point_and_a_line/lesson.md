# Distance Between a Point and a Line

If a line is written in the form $ax + by + c = 0$ and a point has coordinates $(x_0, y_0)$, the distance between them is:

$$
d = \frac{|ax_0 + by_0 + c|}{\sqrt{a^2+b^2}}
$$

The numerator is just plugging the point's coordinates into the left side of the line's equation and taking the absolute value. The denominator is the square root of the sum of squares of the line's $x$ and $y$ coefficients — on the test this is almost always a Pythagorean triple like $3,4,5$ or $5,12,13$, which keeps the arithmetic light.

**Example:** Find the distance between the point $(3, 1)$ and the line $3x + 4y = -2$.

First move everything to one side: $3x + 4y + 2 = 0$, so $a=3$, $b=4$, $c=2$.

$$
d = \frac{|3(3) + 4(1) + 2|}{\sqrt{3^2+4^2}} = \frac{|9+4+2|}{5} = \frac{15}{5} = 3
$$

**Watch the sign of $c$:** if the line is given as $ax+by=k$, rewrite it as $ax+by-k=0$ before substituting, so $c=-k$. For instance, with line $3x-4y=6$ and point $(5,1)$: $c=-6$, giving $d = \frac{|3(5)-4(1)-6|}{5} = \frac{|15-4-6|}{5} = \frac{5}{5} = 1$.

The answer can come out as a whole number, a decimal, or a fraction — don't be surprised if $a^2+b^2$ isn't a perfect square, in which case leave the square root in the denominator or rationalize it.
