# Introduction: FOILing/LIOFing When Multiplying

Multiplication is at the heart of every Number Sense test. Slow multiplication hampers how far you are able to go on the test as well as making you prone to making more errors. To help beginners learn how to speed up multiplying, the concept of FOILing, learned in beginning algebra classes, is introduced as well as some exercises to help in speeding up multiplication. What is nice about the basic multiplication exercises is that *anyone* can make up problems, so practice is unbounded.

When multiplying two two-digit numbers $ab$ and $cd$ swiftly, a method of FOILing — or more accurately named LIOFing (Last-Inner+Outer-First) — is used. To understand this concept better, lets take a look at what we do when we multiply $ab \times cd$:

$$
ab = 10a + b \quad \text{and} \quad cd = 10c + d
$$

$$
(10a + b) \times (10c + d) = 100(ac) + 10(ad + bc) + bd
$$

A couple of things can be seen by this:

1. The one's digit of the answer is simply $bd$ or the *Last* digits (by *Last* I mean the least significant digit) of the two numbers multiplied.

2. The ten's digit of the answer is $(ad + bc)$ which is the sum of the *Inner* digits multiplied together plus the *Outer* digits multiplied.

3. The hundred's digit is $ac$ which are the *First* digits (again, by *First* I mean the most significant digit) multiplied with each other.

4. If in each step you get more than a single digit, you carry the extra (most significant digit) to the next calculation. For example:

> **Note:** Gray digits are the carry — we do not write them down, we pass them to the next step.

$$
74 \times 23 = \begin{array}{ll}
\text{Units:}    & 3 \times 4 = {\color{gray}1}\mathbf{2} \\
\text{Tens:}     & 3 \times 7 + 2 \times 4 + 1 = {\color{gray}3}\mathbf{0} \\
\text{Hundreds:} & 2 \times 7 + 3 = \mathbf{17} \\
\text{Answer:}   & \mathbf{1702}
\end{array}
$$

Where the bold represents the answer and the gray represents the carry.

Similarly, you can extend this concept of LIOFing to multiply any $n\text{-digit}$ number by $m\text{-digit}$ number in a procedure I call "moving down the line." Let's look at an example of a 3-digit multiplied by a 2-digit:

$$
493 \times 23 = \begin{array}{ll}
\text{Ones:}      & 3 \times 3 = \mathbf{9} \\
\text{Tens:}      & 3 \times 9 + 2 \times 3 = {\color{gray}3}\mathbf{3} \\
\text{Hundreds:}  & 3 \times 4 + 2 \times 9 + 3 = {\color{gray}3}\mathbf{3} \\
\text{Thousands:} & 2 \times 4 + 3 = \mathbf{11} \\
\text{Answers:}   & \mathbf{11339}
\end{array}
$$

As one can see, you just continue multiplying the two-digit number "down the line" of the three-digit number, writing down what you get for each digit then moving on (always remembering to carry when necessary).
