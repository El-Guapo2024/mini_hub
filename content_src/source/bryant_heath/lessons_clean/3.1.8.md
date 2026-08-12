# Square Root Problems

A common question involves the multiplication of two square roots together to solve for (usually) an integer value. For example:

$$
\begin{aligned}
\sqrt{12} \times \sqrt{27} \\
&= \sqrt{12} \times \sqrt{3} \times \sqrt{9} \\
&= \sqrt{36} \times \sqrt{9} \\
&= 6 \times 3 \\
&= \mathbf{18}
\end{aligned}
$$

Usually the best approach is to figure out what you can take away from one square root and multiply the other one by it. From the above example, notice that we can take a $\sqrt{3}$ away from $\sqrt{27}$ to multiply the 12 with, leading to just $\sqrt{36} \times \sqrt{9}$ which are easy square roots to calculate. With this method, there are really no "tricks" involved, just a method that should be practiced in order to master it.

For **approximating** square roots of large numbers, the basic trick is to "take out" factors of 100 under the radical. For example, $\sqrt{1234567} \approx \sqrt{1230000}$:

$$
\begin{aligned}
\sqrt{1230000} \\
&= \sqrt{123 \cdot 100 \cdot 100} \\
&= 10 \cdot 10\sqrt{123} \approx 100 \cdot 11 \\
&= \mathbf{1100}
\end{aligned}
$$

You can follow the same procedure for cubed roots, only you need to find factors of 1000 under the radical. For example, $\sqrt[3]{1795953} \approx \sqrt[3]{1795000}$:

$$
\sqrt[3]{1795000} = \sqrt[3]{1795 \cdot 1000} = 10 \cdot \sqrt[3]{1795}
$$

Since $12^3 = 1728$, we can form a rough approximation: $10 \cdot 12.1 = \mathbf{121}$.

The trick is: when approximating the $n^{\text{th}}$ root, "factor out" sets of $n\text{-digits}$ and then approximate a much smaller value, moving the decimal place over accordingly.

For finding the **exact** value of a cubed root, for example $\sqrt[3]{830584}$, the procedure is:

1. Figure out how many digits the answer has by counting how many three-digit "sets" there are. Most will only be two-digit numbers.
2. To find the units digit, look at the units digit of the number given and think about what number cubed would give that result.
3. Disregard the last three digits and look at the remaining number; find what number cubed is the first integer *less* than that value — that is the tens digit.

For $\sqrt[3]{830584}$:

1. There are two three-digit sets (584 and 830), so the answer is a two-digit number.
2. The last digit is 4. Since $4^3 = 64$, the units digit of the answer is **4**.
3. Disregarding 584, the remaining number is 830. Since $10^3 = 1000$ and $9^3 = 729$, the largest integer whose cube is less than 830 is **9** — that is the tens digit.
4. The answer is $\mathbf{94}$.
