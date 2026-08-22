# Complex Numbers

Recall $i = \sqrt{-1}$, so $i^2 = -1$. Complex numbers are written $a + bi$, and the test mostly asks you to multiply two of them, square one, or divide by one.

**Multiplication:** $(a+bi)(c+di) = (ac - bd) + (ad + bc)i$. FOIL it out and replace $i^2$ with $-1$.

Example: $(3-2i)(4+i)$. Here $a=3, b=-2, c=4, d=1$.

$$
ac - bd = (3)(4) - (-2)(1) = 12 + 2 = 14 \qquad ad + bc = (3)(1) + (-2)(4) = 3 - 8 = -5
$$

So $(3-2i)(4+i) = 14 - 5i$, and $a+b = 14 + (-5) = 9$.

**Squaring** is just this formula with $c=a, d=b$: $(a+bi)^2 = (a^2 - b^2) + 2abi$.

**Conjugate products** collapse to a real number: $(a+bi)(a-bi) = a^2 + b^2$, since the cross terms cancel. So $(6-5i)(6+5i) = 36+25 = 61$.

**Dividing by $i$ or a complex number** (rationalizing): multiply top and bottom by the conjugate of the denominator, using $i^2=-1$ to clear the imaginary part below. For a pure imaginary denominator, multiply by $\dfrac{-i}{-i}$ since $i \cdot (-i) = 1$:

$$
\frac{2+3i}{2i} \cdot \frac{-i}{-i} = \frac{-2i - 3i^2}{2} = \frac{3-2i}{2} = \frac{3}{2} - i
$$

More generally $(a+bi)^{-1} = \dfrac{a-bi}{a^2+b^2}$: multiply by the conjugate over itself, since $(a+bi)(a-bi)=a^2+b^2$ is real.

Also know the **conjugate** of $a+bi$ is simply $a-bi$ (flip the sign of the imaginary part) — no computation needed, just read it off.

**Modulus.** The modulus is the distance from the origin:

$$
\left|a+bi\right| = \sqrt{a^2+b^2}
$$

So $|14+48i| = \sqrt{196+2304} = \sqrt{2500} = \mathbf{50}$. The Pythagorean triples are worth spotting — $7\text{-}24\text{-}25$, $5\text{-}12\text{-}13$, $11\text{-}60\text{-}61$ — because these problems are built from them.

The modulus multiplies, so a power of one is a power of the other:

$$
\left|z^n\right| = \left|z\right|^n
$$

That is what makes the squared forms quick: $|(11+60i)^2| = 61^2 = \mathbf{3721}$, with no need to expand the square at all.

**Powers of $i$ cycle every four:** $i^1=i$, $i^2=-1$, $i^3=-i$, $i^4=1$, and then it repeats. Divide the exponent by 4 and keep the remainder. For $(2i)^6 = 2^6 i^6$, the remainder of 6 is 2, so $i^6 = i^2 = -1$ and the answer is $64 \times -1 = \mathbf{-64}$. Likewise $(-3i)^5 = -243\, i^5$, and $i^5 = i$, giving $-243i$.
