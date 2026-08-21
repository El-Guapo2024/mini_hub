# Complex Numbers (NEW)

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
