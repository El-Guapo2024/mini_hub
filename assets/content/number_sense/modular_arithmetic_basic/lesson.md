# Modular Arithmetic (Basic)

When $a$ divided by $b$ gives quotient $q$ and remainder $r$, we write $a \equiv r \pmod{b}$ — meaning $a$ and $r$ leave the same remainder when divided by $b$. For example, $37 \div 4$ has remainder 1, so $37 \equiv 1 \pmod 4$.

The power of this notation is that you can do algebra with remainders directly, without ever computing the full value of $a$.

**Solving for an unknown:** find $x$, with $0 \le x \le 4$, if $x + 3 \equiv 9 \pmod 5$. First reduce the known side: $9 \equiv 4 \pmod 5$. So the problem becomes $x + 3 \equiv 4 \pmod 5$, giving $x = 1$.

**Powers reduce the same way.** To find the remainder of $3^8 \div 7$, reduce the base first if possible, then track powers of the remainder modulo 7:

$$
3^1 \equiv 3,\ \ 3^2 \equiv 2,\ \ 3^3 \equiv 6,\ \ 3^4 \equiv 4,\ \ 3^5 \equiv 5,\ \ 3^6 \equiv 1 \pmod 7
$$

Since $3^6 \equiv 1$, the remainders cycle every 6 powers, so $3^8 = 3^6 \cdot 3^2 \equiv 1 \cdot 2 = 2 \pmod 7$.

**Products work too:** for $2^5 \times 3^5 \div 5$, note $2^5 = 32 \equiv 2$ and $3^5=243 \equiv 3 \pmod 5$, so the product is $\equiv 2 \times 3 = 6 \equiv 1 \pmod 5$.

This same idea — that $10 \equiv 1 \pmod 9$, so any power of 10 also $\equiv 1 \pmod 9$ — is exactly why the "sum of digits divisible by 9" divisibility rule works: a number $n = a_m 10^m + \cdots + a_0$ reduces mod 9 to just $a_m + \cdots + a_0$, the digit sum.

**Solving a congruence with a coefficient on the unknown** (like $3x \equiv 17 \pmod 5\text{)}$ takes one extra step beyond the simple $x + a \equiv b$ case above: you need to "divide" both sides by the coefficient, which in modular arithmetic means multiplying both sides by the coefficient's modular inverse. The inverse of $c$ mod $n$ is whatever small number $c^{-1}$ makes $c \times c^{-1} \equiv 1 \pmod n\text{;}$ with the small moduli on this test, you can just test $c^{-1} = 1, 2, 3, \ldots$ until the product hits $1$.

For example, solve $3x \equiv 17 \pmod 5$: first reduce $17 \equiv 2 \pmod 5$, so $3x \equiv 2 \pmod 5$. Testing inverses of 3 mod 5: $3\times 2 = 6 \equiv 1 \pmod 5$, so $3^{-1} \equiv 2$. Multiply both sides by 2: $x \equiv 2\times 2 = 4 \pmod 5$, so $x = 4$.

Similarly, solve $3x - 2 \equiv 4 \pmod 7$: first isolate, $3x \equiv 6 \pmod 7$. The inverse of 3 mod 7 is 5, since $3\times5=15\equiv 1 \pmod 7$. Multiply both sides by 5: $x \equiv 5\times 6 = 30 \equiv 2 \pmod 7$, so $x = 2$.
