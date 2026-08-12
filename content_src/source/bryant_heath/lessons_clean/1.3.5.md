# Sum of Squares: Special Case

There is a special case of the sum of squares that have repeatedly been tested. In order to apply the trick, these conditions must be met:

1. Arrange the two numbers so that the unit's digit of the first number is one greater than the ten's digit of the second number.
2. Make sure the sum of the ten's digit of the first number and the one's digit of the second number add up to ten.
3. If the above conditions are met, the answer is the sum of the squares of the digits of the first number times 101.

Let's look at an example: $72^2 + 13^2$.

1. The unit's digit of the first number (2) is one greater than the ten's digit of the second number (1).
2. The sum of the ten's digit of the first number (7) and the unit's digit of the second number (3) is 10.
3. The answer will be $(7^2 + 2^2) \times 101 = \mathbf{5353}$.

It is important to arrange the numbers accordingly for this particular trick to work. For example, if you see a problem like: $34^2 + 64^2$, it looks like a difficult problem where this particular trick won't apply. However, if you switch the order of the two numbers you get $34^2 + 64^2 = 64^2 + 34^2 = (6^2 + 4^2) \times 101 = \mathbf{5252}$.

Generally this trick is on the third column, and it is relatively simple to notice when to apply it because if you were having to square the two numbers _and_ add them together it would take a long time. That should tip you off immediately that there is trick that you should apply!
