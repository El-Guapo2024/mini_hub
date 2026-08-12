# Sum of Reciprocals of Triangular Numbers

This is a very interesting problem whose solution is really independent of knowing the triangular numbers $T_n$ themselves, but rather just knowing what term $n$ they are in the sequence. Here is the formula:

$$
\begin{aligned}
\frac{1}{T_n} + \frac{1}{T_{n+1}} + \frac{1}{T_{n+2}} + \ldots + \frac{1}{T_m} \\
&= 2\left(\frac{1}{n} - \frac{1}{m+1}\right)
\end{aligned}
$$

Here is an example with the formula applied:

$$
\begin{aligned}
1 + \frac{1}{3} + \frac{1}{6} + \frac{1}{10} \\
&= 2\left(\frac{1}{1} - \frac{1}{4+1}\right) \\
&= 2\left(1 - \frac{1}{5}\right) \\
&= \frac{8}{5}
\end{aligned}
$$

All you had to know was that the sequence started with the reciprocal of the first ($n = 1\text{)}$ triangular number and ended with the fourth ($m = 4\text{)}$ triangular number. Also, the sequence doesn't have to start from $n = 1\text{;}$ you can have it start from an arbitrary term:

$$
\begin{aligned}
\frac{1}{6} + \frac{1}{10} + \frac{1}{15} + \frac{1}{21} \\
&= 2\left(\frac{1}{3} - \frac{1}{6+1}\right) \\
&= \frac{8}{21}
\end{aligned}
$$

All that matters is that you need to know what term the first and last triangular numbers in the sequence are (which you can back-track using the formulas supplied in Section 2.2.6).
