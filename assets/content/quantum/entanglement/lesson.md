# Entanglement

Superposing states of a *single* particle gives you the strangeness of the last lesson. Superposing states of *two* particles gives you something stranger still.

## Combining two particles

Take two noninteracting particles. Particle $A$ can be in any of the states $|A_1\rangle, |A_2\rangle, \ldots$ and particle $B$ in any of the states $|B_1\rangle, |B_2\rangle, \ldots$

It seems reasonable that the state of the pair is fixed by naming the state of each one. Write that combination with the **tensor product** symbol $\otimes$:

$$
|A_i\rangle \otimes |B_j\rangle
$$

We will study $\otimes$ properly later. For now treat it as a product that distributes over addition, where numbers move freely across the symbol but **the order of the states must be preserved**:

$$
\big(\alpha_1|A_1\rangle + \alpha_2|A_2\rangle\big) \otimes \big(\beta_1|B_1\rangle + \beta_2|B_2\rangle\big)
$$
$$
= \alpha_1\beta_1 |A_1\rangle\otimes|B_1\rangle + \alpha_1\beta_2 |A_1\rangle\otimes|B_2\rangle + \alpha_2\beta_1 |A_2\rangle\otimes|B_1\rangle + \alpha_2\beta_2 |A_2\rangle\otimes|B_2\rangle
$$

Expanded or not, this is still a state where $A$ has its own state and $B$ has its own state. It is **not** entangled.

## States that don't factorize

But superpositions are allowed — that is what linearity guarantees — and nothing stops us writing

$$
|\Psi\rangle = \frac{1}{\sqrt{2}}\Big( |A_1\rangle\otimes|B_1\rangle + |A_2\rangle\otimes|B_2\rangle \Big)
$$

A two-particle state is **entangled** if it *cannot* be written in the factorized form $(\cdots)\otimes(\cdots)$.

This one can't, and the proof is short. If it could, matching it against the expansion above would require

$$
\alpha_1\beta_1 = \tfrac{1}{\sqrt2}, \quad \alpha_1\beta_2 = 0, \quad \alpha_2\beta_1 = 0, \quad \alpha_2\beta_2 = \tfrac{1}{\sqrt2}
$$

The second equation forces $\alpha_1 = 0$ or $\beta_2 = 0$. But $\alpha_1 = 0$ contradicts the first equation, and $\beta_2 = 0$ contradicts the fourth. No solution exists.

So there is **no way to describe this state by giving a state for each particle**. The particles have states only together.

## Two electrons

Make it concrete with spin. The state $|{\uparrow}\rangle\otimes|{\downarrow}\rangle$ has the first electron up along $z$ and the second down. Not entangled. Neither is $|{\downarrow}\rangle\otimes|{\uparrow}\rangle$. But their superposition

$$
|\Psi\rangle = \frac{1}{\sqrt{2}}\Big( |{\uparrow}\rangle\otimes|{\downarrow}\rangle - |{\downarrow}\rangle\otimes|{\uparrow}\rangle \Big)
$$

is entangled. Read what it says: the first electron is up **if** the second is down, or the first is down **if** the second is up. The spins are correlated — always opposite — while neither one has a spin of its own.

## Alice and Bob

Now separate them. Alice keeps one electron on Earth; Bob takes the other to the moon. Nothing we know of connects them any more.

Alice measures her spin along $z$. If she finds up, the first term of the superposition is the one realized, and the state of the pair immediately becomes that term — so Bob's electron is now down along $z$. Bob can measure and find this out **before** a light-speed message from Earth could tell him Alice measured at all.

Run it many times, on many pairs prepared identically. Half the time Earth is up and the moon is down; half the time the reverse.

## The critic returns

And once more the objection is a fair one. These correlations could be produced by an ordinary ensemble: 50% of pairs prepared as $|{\uparrow}\rangle\otimes|{\downarrow}\rangle$ and 50% as $|{\downarrow}\rangle\otimes|{\uparrow}\rangle$. Every $z$ measurement comes out the same. No entanglement needed.

This objection was settled in 1964 by **John Bell**. He showed that if Alice and Bob can each measure spin along *three arbitrary directions*, the correlations predicted for the entangled state **differ** from the correlations of any conceivable conventional ensemble whatsoever — not just this one, but any of them.

That is a remarkable kind of result. It does not merely defeat one proposal; it rules out an entire class of explanations. Experiments with entangled states have since confirmed the quantum correlations. The correlations are subtle and it takes sophisticated experiments to show they are not classical, but the answer is in.

Notice the pattern from the last lesson repeating: a superposition and a mixture agree on one measurement and disagree on another. Bell's theorem is that idea, made sharp and made general.

## What entanglement does not let you do

Bob's electron does become determinate the instant Alice measures. So does this send information faster than light?

**No.** Bob sees random up-and-down results whatever Alice does. He cannot tell from his own data whether Alice has measured, or what she found. Only by comparing notes afterwards — over an ordinary, light-speed channel — do the correlations appear. Entangled states create no paradox with special relativity, and you cannot use them to signal.

## Many particles

Entangled states of many spin one-half particles exist too, and again cannot be described by giving each particle's state. With many particles, such a state is a delicate macroscopic quantum object, easily destroyed by interaction with an environment — the fragility of the last lesson, again.

If they can be built and manipulated, they permit **quantum computation**: a different way of doing what classical computers do, with some new capabilities. Certain computations that are hard classically may become easy.

## What to take away

- $\otimes$ combines two particles' states. Numbers cross it freely; order does not.
- A state is entangled when it cannot be factorized as $(\cdots)\otimes(\cdots)$.
- Entangled particles have no individual states, only correlations.
- Bell ruled out *every* conventional ensemble, not just the obvious one, and experiment agrees with quantum mechanics.
- Correlation is not communication. No signalling, no paradox with relativity.

---

## Exercises

**1.** *(Zwiebach 1.9)* Show that $\frac{1}{\sqrt2}\big(|{\uparrow}\rangle\otimes|{\downarrow}\rangle - |{\downarrow}\rangle\otimes|{\uparrow}\rangle\big)$ cannot be factorized, and is therefore entangled.

**2.** Is $\frac{1}{2}\big(|{\uparrow}\rangle + |{\downarrow}\rangle\big) \otimes \big(|{\uparrow}\rangle + |{\downarrow}\rangle\big)$ entangled? Expand it fully first. Compare with the state in exercise 1 — both are sums of four or two product terms, so what actually decides the question?

**3.** Give a general condition on $\alpha_{11}, \alpha_{12}, \alpha_{21}, \alpha_{22}$ for the state $\sum_{ij}\alpha_{ij}|A_i\rangle\otimes|B_j\rangle$ to factorize. Write it as a single equation in those four numbers.

**4.** In the entangled state of exercise 1, Alice measures along $z$ and finds up. What is Bob's state? Now suppose Alice instead measures along $x$. Argue that Bob's electron is still correlated with hers, and say what that means for any explanation in which each electron carried its answer all along.

**5.** Bob holds one electron of an entangled pair and knows nothing of Alice's actions. Show explicitly that his measurement statistics along $z$ are 50/50 whether or not Alice has measured — and hence that Alice cannot signal to him.

**6.** Why is entanglement of many particles harder to maintain than entanglement of two? Connect your answer to why Schrödinger's cat is alive or dead in practice.
