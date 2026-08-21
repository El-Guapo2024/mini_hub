# Sets

Set questions test four ideas: intersection, union, complement, and subset counting. Let $A = \{M,E,N,T,A,L\}$ and $B = \{M,A,T,H\}$.

**Intersection** ($A \cap B\text{)}$: elements in *both* sets. Here $A \cap B = \{M,A,T\}$, 3 elements.

**Union** ($A \cup B\text{)}$: all elements appearing in *either* set (no repeats). Here $A \cup B = \{M,E,N,T,A,L,H\}$, 7 elements.

**Complement** ($\overline{E}$ or $E'\text{)}$: everything in the universal set that is *not* in $E$. If $E = \{T,E,N\}$ and the universal set is $A$, then $\overline{E} = \{M,A,L\}$, 3 elements. When a problem doesn't state a universal set explicitly, it's the largest set named in the problem.

**Subsets:** a set with $n$ elements has $2^n$ subsets (this count is also called its power set). *Proper* subsets exclude the full set itself, so there are $2^n - 1$ proper subsets. If a question asks for proper subsets with *at least one element*, also exclude the empty set: $2^n - 2$.

Since $A=\{M,E,N,T,A,L\}$ has $n=6$ elements, it has $2^6 = 64$ subsets and $2^6-1=63$ proper subsets. Since $B$ has $n=4$ elements, its power set has $2^4=16$ elements.

Working backward: if a set has 15 proper subsets, then $2^n - 1 = 15 \Rightarrow 2^n = 16 \Rightarrow n=4$.

**Chained operations** use parentheses/brackets to show which operation happens first, e.g. $[\{z,e,r,o\} \cap \{o,n,e\}] \cup \{t,w,o\}$: first intersect ($\{e,o\}\text{)}$, then union with $\{t,w,o\}$ to get $\{e,o,t,w\}$, 4 distinct elements.
