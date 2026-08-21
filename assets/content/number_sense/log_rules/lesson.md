# Logarithms (Evaluation)

A logarithm answers "what power?" By definition,

$$
\log_a b = x \quad \Longleftrightarrow \quad a^x = b
$$

The core rules you need:

$$
\log_a b^n = n\log_a b \qquad \log_a b + \log_a c = \log_a(bc) \qquad \log_a b - \log_a c = \log_a\!\left(\frac{b}{c}\right) \qquad \log_a b = \frac{\log b}{\log a}
$$

the last one (change of base) lets you rewrite any log in terms of a common base.

**Example:** Find $\log_8 16$. By the definition, $8^x = 16$, so $2^{3x} = 2^4$, giving $x = \mathbf{\frac{4}{3}}$.

**Example:** Find $\log_{12}16 + \log_{12}36 - \log_{12}4$. Combine using addition/subtraction of logs:

$$
\log_{12}\frac{16\cdot 36}{4} = \log_{12}144 = \mathbf{2}
$$

since $12^2 = 144$.

**Example (change of base):** Find $\log_5 8 \div \log_{25} 16$.

$$
\frac{\log 8}{\log 5}\div\frac{\log 16}{\log 25} = \frac{3\log 2}{\log 5}\times\frac{2\log 5}{4\log 2} = \frac{6}{4} = \mathbf{\frac{3}{2}}
$$

writing $8=2^3$, $16=2^4$, $25=5^2$ and canceling.

Two other common patterns: solving $\log_x n = k$ for $x$ (rewrite as $x^k = n\text{)}$, and nested logs like $\log_2(\log_{10}100) = \log_2(2) = 1$ — always evaluate the inside first. For approximation problems, it helps to remember $\log 2 \approx .3$, $\log 5 \approx .7$, $\ln 2 \approx .7$, $\ln 10 \approx 2.3$.
