# Multiplying Two Numbers Near 100

Let's look at two numbers over 100 first. Express $n_1 = (100 + a)$ and $n_2 = (100 + b)$ then:

$$
\begin{aligned}
n_1 \cdot n_2 \\
&= (100 + a) \cdot (100 + b) \\
&= 10000 + 100(a + b) + ab \\
&= 100(100 + a + b) + ab \\
&= 100(n_1 + b) + ab \\
&= 100(n_2 + a) + ab
\end{aligned}
$$

1. The Tens/Ones digits are just the difference the two numbers are above 100 multiplied together ($ab\text{)}$

2. The remainder of the answer is just $n_1$ plus the amount $n_2$ is above 100, or $n_2$ plus the amount $n_1$ is above 100.

$$
103 \times 108 = \begin{array}{ll}
\text{Tens/Units:}    & 8 \times 3 & \mathbf{24} \\
\text{Rest of Answer:}& 103 + 8 \text{ or } 108 + 3 & \mathbf{111} \\
\text{Answer:}        & & \mathbf{11124}
\end{array}
$$

Now let's look at two numbers below 100. $n_1 = (100 - a)$ and $n_2 = (100 - b)$ so:

$$
\begin{aligned}
n_1 \cdot n_2 \\
&= (100 - a) \cdot (100 - b) \\
&= 10000 - 100(a + b) + ab \\
&= 100(100 - a - b) + ab \\
&= 100(n_1 - b) + ab \\
&= 100(n_2 - a) + ab
\end{aligned}
$$

1. Again, Tens/Ones digits are just the difference the two numbers are above 100 multiplied together ($ab\text{)}$

2. The remainder of the answer is just $n_1$ minus the difference $n_2$ is from 100, or $n_2$ minus the difference $n_1$ is from 100.

$$
97 \times 94 = \begin{array}{ll}
\text{Tens/Ones:}     & (100 - 97) \times (100 - 94) = 3 \times 6 & \mathbf{18} \\
\text{Rest of Answer:}& 97 - 6 \text{ or } 94 - 3 & \mathbf{91} \\
\text{Answer:}        & & \mathbf{9118}
\end{array}
$$

Now to multiply two numbers, one above and one below is a little bit more tricky. Let $n_1 = (100 + a)$ which is the number above 100 and $n_2 = (100 - b)$ which is the number below 100, then:

$$
\begin{aligned}
n_1 \cdot n_2 \\
&= (100 + a) \cdot (100 - b) \\
&= 10000 + 100(a - b) - ab \\
&= 100(100 + a - b) - ab \\
&= 100(100 + a - b - 1) + (100 - ab) \\
&= 100(n_1 - b - 1) + (100 - ab)
\end{aligned}
$$

To see what this means, it is best to use an example:

$$
103 \times 94 = \begin{array}{ll}
\text{Tens/Ones:}     & 100 - 3 \times 6 & \mathbf{82} \\
\text{Rest of Answer:}& 103 - 6 - 1 & \mathbf{96} \\
\text{Answer:}        & & \mathbf{9682}
\end{array}
$$

So the trick is:

1. The Tens/Ones is just the difference the two numbers are from 100 multiplied together then subtracted from 100.

2. The rest of the answer is just the number that is larger than 100 minus the difference the smaller number is from 100 minus an additional 1.

Let's look at another example to solidify this:

$$
108 \times 93 = \begin{array}{ll}
\text{Tens/Ones:}     & 100 - 8 \times 7 & \mathbf{44} \\
\text{Rest of Answer:}& 108 - 7 - 1 & \mathbf{100} \\
\text{Answer:}        & & \mathbf{10044}
\end{array}
$$

It should be noted that you can extend this trick to not just integers around 100 but 1000, 10000, and so forth. For the extension, you just need to keep track how many digits each part is. For example, when we are multiplying two numbers over 100 (say $104 \times 103\text{)}$ the first two digits would be $4 \times 3 = 12$, however if we were doing two numbers over 1000 (like $1002 \times 1007\text{)}$ the first *three* digits would be $2 \times 7 = \mathbf{014}$ not 14 like what you would be used to putting. Let's look at the example presented above and the procedure:

$$
1002 \times 1007 = \begin{array}{ll}
\text{Hundreds/Tens/Ones:} & 2 \times 7 & \mathbf{014} \\
\text{Rest of Answer:}     & 1002 + 7 = 1007 + 2 & \mathbf{1009} \\
\text{Answer:}             & & \mathbf{1009014}
\end{array}
$$

The best way to remember to include the "extra" digit is to think that when you multiply $1002 \times 1007$ you are going to *expect* a seven digit number. Now adding $1002 + 7 = 1009$ gives you four of the digits, so you need the first part to produce three digits for you.

Let's look at an example of two numbers below 1000:

$$
993 \times 994 = \begin{array}{ll}
\text{Hundreds/Tens/Ones:} & 7 \times 6 & \mathbf{042} \\
\text{Rest of Answer:}     & 993 - 6 = 994 - 7 & \mathbf{987} \\
\text{Answer:}             & & \mathbf{987042}
\end{array}
$$
