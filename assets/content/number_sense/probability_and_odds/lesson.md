# Probability and Odds

$$
\text{Probability} = \frac{\text{Desired Outcomes}}{\text{Total Outcomes}} \qquad \text{Odds} = \frac{\text{Desired Outcomes}}{\text{Undesirable Outcomes}}
$$

Probability is desired-over-total; odds is desired-over-everything-else. If $p$ is the probability of an event, the odds in favor are $\dfrac{p}{1-p}$, and the odds are the ratio "desired : undesired," which always add up to the total.

Example: rolling snake-eyes (a specific sum on two dice) has 1 desired outcome out of 36 total, so the probability is $\frac{1}{36}$. Since 35 of the 36 outcomes are undesired, the odds are $\frac{1}{35}$.

**Converting odds to probability:** if the odds of losing are 4-to-9, that means for every 4 losses there are 9 wins, so the total is $4+9=13$ parts. The probability of winning is $\frac{9}{13}$.

**Converting probability to odds:** if the probability of winning is $\frac{5}{9}$, the probability of losing is $1-\frac{5}{9}=\frac{4}{9}$, and the odds of losing are $\dfrac{4/9}{5/9} = \frac{4}{5}$.

**Watch the phrasing.** Sometimes a problem says "the probability of losing is 4-to-7." Despite the odds-style wording, the word "probability" means you should read this literally as the fraction $\frac{4}{7}$ (not as a part-to-total ratio). So $P(\text{lose}) = \frac{4}{7}$, giving $P(\text{win}) = \frac{3}{7}$, and the odds of winning are $\dfrac{3/7}{4/7} = \frac{3}{4}$.

**Counting outcomes:** for dice, marbles, cards, or letters in a word, count desired outcomes directly. E.g., a bag with 3 red, 6 white, 9 blue marbles (18 total) gives $P(\text{red}) = \frac{3}{18} = \frac{1}{6}$. For two dice (36 equally likely pairs), count pairs summing to a target, e.g. sum of 7 has 6 pairs, so $P = \frac{6}{36} = \frac{1}{6}$ and the odds are $\frac{6}{30} = \frac{1}{5}$.

**Combining sums with "or."** Two dice give exactly one sum per roll, so no roll can hit two different sums at once — the events "sum is 6" and "sum is 8" can never overlap. That means you don't need any new formula for "or": just add the ways-counts for each target sum, then put the combined count over 36 (for probability) or over 36-minus-that-count (for odds). The full ways-count table, sum by sum, is: 2 has 1 way, 3 has 2, 4 has 3, 5 has 4, 6 has 5, 7 has 6, 8 has 5, 9 has 4, 10 has 3, 11 has 2, 12 has 1 — always 36 total.

*Example 1.* What are the odds that the sum is 6 or 8? Sum 6 has 5 ways, sum 8 has 5 ways, so combined desired outcomes are $5+5=10$. Undesired outcomes are $36-10=26$. The odds are $\dfrac{10}{26} = \frac{5}{13}$.

*Example 2.* What is the probability the sum is a multiple of 4? The possible sums that are multiples of 4 are 4, 8, and 12, with 3, 5, and 1 ways respectively. Combined, that's $3+5+1=9$ ways out of 36, so $P = \frac{9}{36} = \frac{1}{4}$.

*Example 3.* What is the probability the sum is a multiple of 5? The sums that qualify are 5 and 10, with 4 and 3 ways respectively (15 is impossible with two dice, so it drops out). Combined, that's $4+3=7$ ways out of 36, so $P = \frac{7}{36}$ — already in lowest terms, since 7 shares no factor with 36.

The pattern is always the same: list which target sums satisfy the "or" condition, read each one's ways-count off the table, add those counts together, and only then divide by 36 (for probability) or convert to a desired-to-undesired ratio (for odds). Adding the ways-counts first and dividing once at the end avoids the mistake of adding two separate fractions like $\frac{1}{6}$ and $\frac{5}{36}$ the long way.
