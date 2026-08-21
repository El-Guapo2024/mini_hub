# Triangle Inequality

A popular triangle question gives two sides of a triangle and asks for the minimum/maximum value for the other side conforming to the restriction that the triangle is right, acute, or obtuse. The two key formulas are:

$$
\text{Triangle Inequality: } a + b > c
$$

**Variations on the Pythagorean Theorem:**

- Right Triangle: $a^2 + b^2 = c^2$
- Acute Triangle: $a^2 + b^2 > c^2$
- Obtuse Triangle: $a^2 + b^2 < c^2$

If you don't have the Pythagorean relationships for acute/obtuse triangles memorized, the easiest way to think about the relationship on the fly is remembering that an equilateral triangle is acute so $a^2 + a^2 > a^2$.

**Example:** An acute triangle has integer sides of 4, $x$, and 9. What is the largest value of $x$?

**Solution:** Using the Pythagorean relationship we know: $4^2 + 9^2 > x^2$ or $97 > x^2$. Knowing this and the fact that $x$ is an integer, we know that the largest value of $x$ is $\mathbf{9}$.

**Example:** An acute triangle has integer sides of 4, $x$, and 9. What is the smallest value of $x$?

**Solution:** The triangle inequality alone gives $4 + x > 9$, so $x > 5$ — but that only says the sides *form* a triangle, not that it is acute, and both are required. With 9 the largest side, acute means $4^2 + x^2 > 9^2$, so $x^2 > 65$ and the smallest integer is $\mathbf{9}$.

Together with the example above, $x$ must be exactly 9: sides 4, 9, 9. It is worth checking why the inequality on its own is not enough — 4, 6, 9 satisfies it, but $4^2 + 6^2 = 52 < 81$, so that triangle is obtuse. The manual stops at the triangle inequality here and prints 6; the practice questions below are answered the full way, and so should you be.

**Example:** An obtuse triangle has integer sides of 7, $x$, and 8. What is the smallest value of $x$?

**Solution:** For this, we want the largest value in the obtuse triangle to be 8 then apply the Triangle Inequality: $7 + x > 8$ with $x$ being an integer. This makes the smallest value of $x$ to be $\mathbf{2}$.

**Example:** An obtuse triangle has integer sides of 7, $x$, and 8. What is the largest value of $x$?

**Solution:** Here, $x$ is restricted by the Triangle Inequality (if we used the Pythagorean Theorem for obtuse, we would get an unbounded result for $x$: $7^2 + 8^2 < x^2$ makes $x$ unbounded). So we know from that equation: $7 + 8 > x$ so the largest integer value for $x$ is $\mathbf{14}$.

Another important type of triangle problem involves being given one side of a right triangle and having to compute the other sides. For example, the sides of a right triangle are integers, one of its sides is 9, what is the hypotenuse?

Where this gets its foundation is from the Pythagorean Theorem which states that $a^2 + b^2 = c^2$. If the smallest side is given (call it $a\text{)}$, then we can express $a^2 = c^2 - b^2 = (c-b)(c+b)$. The goal becomes to find two numbers that when subtracted together from each other multiplied with them added to each other is the smallest side squared. When the smallest side squared gives an odd number (in our case 81 is odd), the goal is reduced considerably by thinking of taking consecutive integers (so $c - b = 1\text{)}$ and $c + b = a^2$. The easiest way to find two consecutive integers whose sum is a third number is to divide the third number by 2, and the integers straddle that mixed number. So in our case $9^2 = 81 \div 2 = 40.5$ so $b = 40$ and $c = \mathbf{41}$.

**Example:** The sides of a right triangle are integers, one of its sides is 11, what is the other side?

**Solution:** $11^2 = 121$ which is odd, so $121 \div 2 = 60.5$ so the other side is $\mathbf{60}$.

Very seldom do they give you a side whose square is even. In that case, divide the number they give you by a certain amount to get an odd number, then perform the usual procedure on that odd number, then multiply each side by the number you originally divided by. For example, the sides of a right triangle are integers, one of its sides is 10, what is the hypotenuse? So to get an odd number we must divide 10 by 2 to get 5. Now to find the other side/hypotenuse with smallest side 5: $5^2 \div 2 = 12.5 \Rightarrow b = 12$ and $c = 13$. Now to get the correct side/hypotenuse lengths, we must multiply by what we divided by (2) so $b = 12 \cdot 2 = 24$ and $= 13 \cdot 2 = \mathbf{26}$.

There are some variations to this, say they tell you that the hypotenuse is 61 and ask for the smallest side. Since half of the smallest side squared is roughly the hypotenuse, you will be looking for squares who are near $61 \cdot 2 = 122$, so you know that $s = \mathbf{11}$.

In addition, there are some algebraic applications that frequently ask the same thing. For example, if it is given that $x^2 - y^2 = 53$ and asks you to solve for $y$. You do the same procedure: $(x+y)(x-y) = 53$, since 53 is odd, you are concerned with consecutive numbers adding up to 53, so $53 \div 2 = 26.5 \Rightarrow x = 27$ and $y = \mathbf{26}$.
