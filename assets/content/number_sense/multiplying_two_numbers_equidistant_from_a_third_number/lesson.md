# Multiplying Two Numbers Equidistant from a Third Number

To illustrate this concept, let's look at an example of this type of problem: $83 \times 87$. Notice that both 83 and 87 are 2 away from 85. So:

$$
83 \times 87 = (85 - 2) \times (85 + 2)
$$

Which notice this is just the difference of two squares:

$$
(85 - 2) \times (85 + 2) = 85^2 - 2^2 = 7225 - 4 = \mathbf{7221}
$$

So the procedure is:

1. Find the middle number between the two numbers being multiplied and square it.

2. Subtract from that the difference between the middle number and one of two numbers squared.

For most of these types of problems, the center number will be a multiple of 5, making the computation of its square relatively simple (See Section 1.2.7, Square's Ending in 5 Trick). The following illustrates another example:

$$
61 \times 69 = 65^2 - 4^2 = 4225 - 16 = \mathbf{4209}
$$

## Extending the Trick to Powers of Equidistant Numbers

Sometimes a problem won't ask for $a \times b$ directly, but instead for $a^n \times b^n$, where $a$ and $b$ are equidistant from a third number. A good example is $4.9^{3} \times 3.3^{3}$. At first glance this looks like it requires cubing each number separately and then multiplying, which is a lot of work. But there's a shortcut using the law of exponents $a^n \times b^n = (a \times b)^n$.

That means you can first collapse the powers into a single product, apply the equidistant trick to that product, and only then raise the result to the power $n$:

$$
a^n \times b^n = (a \times b)^n = (m^2 - d^2)^n
$$

Let's work through $4.9^{3} \times 3.3^{3}$. Combine the exponents first:

$$
4.9^{3} \times 3.3^{3} = (4.9 \times 3.3)^{3}
$$

Now 4.9 and 3.3 are equidistant from their midpoint $m = 4.1$, with $d = 0.8$:

$$
4.9 \times 3.3 = 4.1^2 - 0.8^2 = 16.81 - 0.64 = 16.17
$$

Finally, cube that result:

$$
(4.9 \times 3.3)^{3} = 16.17^{3} \approx \mathbf{4228}
$$

Notice how much easier this is than multiplying $4.9^3$ and $3.3^3$ separately and then combining them — you only ever have to square a two-digit-ish number and cube the small result at the end. The same idea applies to any matching pair of powers, not just cubes: if you ever see $a^n \times b^n$ with $a$ and $b$ equidistant from a third number, combine the exponents first, collapse the product with the equidistant trick, then apply the exponent last.
