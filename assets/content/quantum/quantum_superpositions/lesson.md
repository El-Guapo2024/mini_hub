# Quantum Superpositions

Linearity says the sum of two solutions is a solution. In classical physics that is unremarkable: add two electromagnetic solutions and you get one whose electric field is the sum of the two electric fields. Nothing strange happens.

Quantum mechanics is linear too. It is the **interpretation** of the sum that is surprising.

## Overall factors don't matter

Take a general superposition of two independent photon polarization states:

$$
|\Psi\rangle = \alpha\,|\text{photon};x\rangle + \beta\,|\text{photon};y\rangle
$$

That looks like two complex parameters, so four real ones. But an overall factor changes no physics — $|\Psi\rangle$ and $c|\Psi\rangle$ are the same state. Divide by $\alpha$:

$$
|\Psi\rangle \simeq |\text{photon};x\rangle + \frac{\beta}{\alpha}\,|\text{photon};y\rangle
$$

Only the **ratio** $\beta/\alpha$ survives. One complex number, two real parameters — which matches the classical count, since a general elliptically polarized wave is fixed by an axis ratio and a tilt angle.

Push this a little further with $|A\rangle$ and $|B\rangle$ standing for any two inequivalent states. Write $\beta/\alpha = re^{i\phi}$, set $r = \tan(\theta/2)$, and rescale symmetrically. The general superposition takes the canonical form

$$
|\Psi\rangle = \cos\frac{\theta}{2}\,|A\rangle + e^{i\phi}\sin\frac{\theta}{2}\,|B\rangle
$$

with $0 \le \theta \le \pi$ and $0 \le \phi < 2\pi$. Those are exactly polar and azimuthal angles. **The superpositions of two states are the points of a sphere.** Every distinct superposition is a direction in three-dimensional space — which is, remarkably, the same structure that will describe a spin one-half particle.

## Electron spin

An electron has spin angular momentum. Classically you would picture a tiny spinning ball, and that picture is wrong in two ways: the electron is a point particle with no apparent size, and once you fix an axis, the measured angular momentum comes out with only two possible values — one positive, one negative, equal in magnitude. These are **spin up** and **spin down** along that axis, written $|{\uparrow};z\rangle$ and $|{\downarrow};z\rangle$. The magnitude is always $\hbar/2$, which is why the electron is a spin one-half particle.

Two possibilities, and only two, **whatever axis you measure along**. That is already peculiar. Take an electron in $|{\uparrow};z\rangle$ and measure its spin along $x$: you do not get zero. You get up along $x$ or down along $x$, at random. So $|{\uparrow};z\rangle$ is not a classical arrow pointing along $z$ — a classical arrow along $z$ has no $x$ component at all.

Now form the superposition:

$$
|\Psi\rangle = \frac{1}{\sqrt{2}}\Big(|{\uparrow};z\rangle + |{\downarrow};z\rangle\Big)
$$

Measure the spin along $z$ on a large ensemble of electrons prepared this way, one at a time. About half come out up, about half down, and there is no predicting which for any individual electron.

An electron in this state is doing something without a classical description: it is somehow spinning up along $z$ and down along $z$ at once, until measured — at which point it must immediately settle on one. Some physicists hold that a physical picture of superposition is neither required nor useful, and that one only needs the rules for manipulating the states correctly. That is a defensible position.

## The critic, and why the critic is wrong

Here is the objection that must be answered, because it is a good one.

A critic says: forget superpositions. Just take an ensemble where 50% of the electrons are in $|{\uparrow};z\rangle$ and 50% are in $|{\downarrow};z\rangle$ — an ordinary mixture, nothing eerie. Measuring spin along $z$ gives half up and half down, exactly as before. The superposition explains nothing that plain ignorance doesn't.

For measurements along $z$, the critic is **correct**. The two ensembles are indistinguishable.

So measure along $x$ instead.

- **The critic's mixture**: 50% up along $x$, 50% down along $x$.
- **The superposition** $|\Psi\rangle$ sends *every single electron* up along $x$.

The two ensembles are not the same, and one experiment separates them. A superposition is not a mixture, and "we don't know which" is not what a superposition means. This distinction is the single most important idea in the chapter, and it is worth more than any verbal picture of what an electron is "really" doing.

## Cats, and things that are almost cats

Schrödinger imagined an apparatus putting a cat into a superposition of alive and dead — intending it as a reductio, a demonstration that the rules give absurd results. Most physicists now think no such state of a real cat exists, but for a **technical** reason rather than a philosophical one: superpositions are extremely fragile, and any interaction with the environment destroys them. An electron can be isolated. A cat cannot. So a real cat is alive or dead.

But you can get closer than you might expect. A **SQUID** — a superconducting ring interrupted by a Josephson junction — supports supercurrents flowing clockwise or counterclockwise, each involving something like a billion paired electrons, each producing magnetic flux through the ring in one direction or the other. These are macroscopic states. Superpose them:

$$
|1\rangle = \frac{1}{\sqrt{2}}\Big(|\text{clockwise}\rangle + |\text{counterclockwise}\rangle\Big)
$$

This is a state of **indefinite** current and indefinite flux. Note carefully that it is not a state of *zero* current, which is what classically superposing two opposite currents would give you. Measure the flux on many SQUIDs in state $|1\rangle$ and you get positive sometimes and negative sometimes — never zero.

The skeptic returns: an ensemble half clockwise, half counterclockwise would do the same. And again the answer is to look at a different observable. Form the other combination,

$$
|2\rangle = \frac{1}{\sqrt{2}}\Big(|\text{clockwise}\rangle - |\text{counterclockwise}\rangle\Big)
$$

The minus sign changes nothing if you only measure flux — but $|1\rangle$ and $|2\rangle$ have slightly **different energies**, and states of different energy evolve differently in time. Start with a definite clockwise current, decompose it into $|1\rangle$ and $|2\rangle$, and let it run: after a time set by the energy difference, the combination has turned into the *other* one, and the current is now counterclockwise. The flux has flipped on its own. At every moment in between, the state was a superposition.

These oscillations have been observed. Billions of electrons, circulating both ways at once, and the experiment agrees.

## What to take away

- An overall factor is not physical. What matters in $\alpha|A\rangle + \beta|B\rangle$ is the ratio $\beta/\alpha$.
- Two states superpose into a sphere's worth of distinct states, parameterized by $(\theta,\phi)$.
- Spin measurements give two outcomes along *any* axis, so $|{\uparrow};z\rangle$ is not a classical arrow.
- **A superposition is not a mixture.** They agree on one observable and disagree on another, and experiment decides.
- Superpositions are fragile, not impossible, at large scale — SQUIDs make macroscopic ones and their oscillations are measured.

---

## Exercises

**1.** *(Zwiebach 1.8)* Of the four states $|A\rangle + |B\rangle$, $i\big(|A\rangle + |B\rangle\big)$, $-|A\rangle - |B\rangle$, and $|A\rangle - |B\rangle$, one is not equivalent to the other three. Which, and why?

**2.** Starting from $|\Psi\rangle = |A\rangle + (\beta/\alpha)|B\rangle$, carry out the substitutions $\beta/\alpha = re^{i\phi}$ and $r = \tan(\theta/2)$ and the symmetric rescaling, and derive the canonical form given above.

**3.** For the canonical state, what are the probabilities of finding $|A\rangle$ and of finding $|B\rangle$? Verify they sum to 1 for every $\theta$, and identify which points of the sphere give $|A\rangle$ and $|B\rangle$ themselves.

**4.** Show that $\phi$ drops out of both probabilities in exercise 3. Since $\phi$ is then invisible to this measurement but does distinguish the states, what kind of experiment must be needed to detect it?

**5.** The critic's mixture and the superposition $|\Psi\rangle$ agree on measurements along $z$ and disagree along $x$. Construct a *different* superposition of $|{\uparrow};z\rangle$ and $|{\downarrow};z\rangle$ that also gives 50/50 along $z$, but which gives all electrons **down** along $x$.

**6.** In the SQUID, $|1\rangle$ and $|2\rangle$ differ only by a sign, and flux measurements cannot tell them apart. What does distinguish them, and how does that difference turn into an observable flipping of the current over time?
