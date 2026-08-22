# Remainder by 3, 9

In order to find divisibility with 3, you can sum up all the digits and see if that result is divisible by 3. Similarly, you can do the same thing with 9. Let's look at two examples:

$34952 \div 3$ has what remainder? Sum of the Digits: $(3+4+9+5+2) = 23$, and $23 \div 3 = r\mathbf{2}$

$112321 \div 9$ has what remainder? Sum of the Digits: $(1+1+2+3+2+1) = 10$, and $10 \div 9 = r\mathbf{1}$

For some examples, you can employ faster methods by using modular techniques in order to get the results quicker (see the Modular Arithmetic (Basic) topic). For example, if we were trying to see the remainder of 366699995 when dividing by 3, rather than summing up all the digits (which would be a hassle) and then seeing the remainder when that is divided by 3, you can look at each digit and figure out what its remainder is when dividing by 3 then summing _those_. So for our example:

$$
366699995 \cong (0+0+0+0+0+0+0+0+2) \cong 2\pmod{3}
$$

therefore it leaves a remainder of $\mathbf{2}$.
