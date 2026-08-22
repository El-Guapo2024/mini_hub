# Multiplying a Three-Digit Number by a Three-Digit Number

This extends Section 4.1.1 to three-digit by three-digit multiplication. Let $n_1 = abc$ and $n_2 = def$, where $a, b, c, d, e, f$ are digits. Group $n_1$ as $a$ and $bc$, and $n_2$ as $d$ and $ef$, then FOIL/LIOF:

$$
abc = 100a + (bc), \quad def = 100d + (ef)
$$

$$
[100a + (bc)] \times [100d + (ef)] = 10000 \cdot ad + 100[a(ef) + d(bc)] + (bc)(ef)
$$

This gives four rules:

1. **Ones and Tens:** last two digits of $(bc) \times (ef)$.
2. **Carries are common** — keep track carefully.
3. **Hundreds and Thousands:** $a(ef) + d(bc)$ plus the carry from step 1. (These are the *Inner* and *Outer* products of the two-digit groups with their one-digit counterparts on the opposing number.)
4. **Remainder:** the two leading digits $a \times d$, plus the carry from step 3.

**Example (simple digits):**

$$
211 \times 416 = \begin{cases} \text{Units and Tens:} & 16 \times 11 = 1\mathbf{76} \\
\text{Hundreds and Thousands:} & 16 \times 2 + 11 \times 4 + 1 = \mathbf{77} \\
\text{Remaining:} & 4 \times 2 = \mathbf{8} \end{cases} \quad \Rightarrow \quad \mathbf{87776}
$$
**Example (larger inner products):**

$$
217 \times 245 = \begin{cases} \text{Units and Tens:} & 17 \times 45 = 7\mathbf{65} \\
\text{Hundreds and Thousands:} & 45 \times 2 + 17 \times 2 + 7 = 1\mathbf{31} \\
\text{Remaining:} & 2 \times 2 + 1 = \mathbf{5} \end{cases} \quad \Rightarrow \quad \mathbf{53165}
$$

As an alternative, you can treat each digit as a separate entity and move down the line as described in Section 1.1 — both methods produce the same result.
