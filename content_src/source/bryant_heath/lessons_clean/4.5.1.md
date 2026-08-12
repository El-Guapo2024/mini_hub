# More on Sets

Questions asking for the number of subsets containing a set amount of elements (e.g., in a set with 5 elements, how many subsets contain exactly 3 elements) are more of a combinatorics problem involving the $_nC_k$ formula, where $n$ is the number of total elements in the set and $k$ is the number of elements in the requested sub-set. Here is an example:

**Problem:** How many subsets containing only 2 elements does the set $\{N, U, M, B, E, R\}$ have?

*Solution:* Applying the formula:

$$
{}_6C_2 = \frac{6!}{2! \cdot (6-2)!} = \frac{6 \times 5}{2} = 15
$$

The only way to really complicate this is if they ask for the number of subsets containing either 2 or 3 elements (or whatever those arbitrary values are). In this case, you just apply the combination formula twice and then add $({}_6C_2 + {}_6C_3)$.
