# Wilson's Theorem

Wilson's Theorem states that for a prime $p$:

$$
(p-1)! \equiv (p-1) \pmod{p}
$$

So $6! \equiv 6 \pmod{7}$ since $7$ is prime, and in general $(p-1)!$ always leaves remainder $p-1$ (equivalently, $-1\text{)}$ when divided by a prime $p$.

Test questions dress this up with sums, differences, products, and quotients of factorials, so the real skill is simplifying the expression down to something you can reduce mod $n$ directly.

**Sum/difference inside a factorial:** $(4+2)! \bmod 7 = 6! \bmod 7 = 6$ (Wilson's Theorem, since $7$ is prime). Likewise $(5-2)! \bmod 5 = 3! \bmod 5 = 6 \bmod 5 = 1$.

**Composite modulus — lump factors instead:** Wilson's Theorem only applies when the modulus is prime. If it's not, factor the modulus out of the factorial directly. For $4! \bmod 6$: since $4! = 4\cdot3\cdot2\cdot1 = 24 = 4 \times 6$, it's a multiple of $6$, so $4! \equiv 0 \pmod 6$.

**Products and quotients of factorials:** simplify algebraically first, then reduce. For $\frac{5!\cdot 3!}{4!} \bmod 8$: since $\frac{5!}{4!}=5$, this is $5 \cdot 3! = 5 \cdot 6 = 30$, and $30 \bmod 8 = 6$. For $\frac{5!\cdot 4!}{3!} \bmod 9$: $\frac{4!}{3!}=4$, so this is $5!\cdot 4 = 120\cdot 4 = 480$, and $480 \bmod 9 = 3$. For $5!\cdot 3! \bmod 8$: $5!\cdot 3! = 120\cdot 6 = 720$, and $720 \bmod 8 = 0$.

Always compute the exact product or quotient first (it's usually small), then take the remainder — don't try to reduce factors mod $n$ individually unless you're careful, since division inside a factorial ratio must be done before reducing.
