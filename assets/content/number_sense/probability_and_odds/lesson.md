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
