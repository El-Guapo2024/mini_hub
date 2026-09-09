# Making Atoms Possible

The most dramatic argument for quantum mechanics is also the simplest to state:

**Atoms are impossible in classical physics.**

Not difficult, not finely tuned — impossible. Two independent arguments show it, and both use nothing beyond first-year mechanics.

## The classical hydrogen atom

Model hydrogen as an electron circling a stationary proton, which is fair since the proton is far more massive. The proton has charge $e$, the electron $-e$, and the Coulomb potential energy is

$$
V(r) = -\frac{e^2}{r}
$$

giving an attractive force of magnitude $e^2/r^2$. For a circular orbit, set the force equal to mass times centripetal acceleration:

$$
\frac{e^2}{r^2} = \frac{m_e v^2}{r}
$$

Look at what this does **not** determine. The radius $r$ is free — any value works, provided the speed $v$ adjusts to match. Classical mechanics does not fix the size of the atom. Yet every hydrogen atom in the universe is the same size, which is already a problem.

## Trying to fix the size by minimizing energy

The natural repair is to find the radius of lowest energy. The total energy is kinetic plus potential:

$$
E_{\text{cl}} = \tfrac{1}{2}m_e v^2 - \frac{e^2}{r}
$$

The force equation, multiplied by $r/2$, gives $\tfrac{1}{2}m_e v^2 = e^2/2r$. Substituting:

$$
E_{\text{cl}}(r) = \frac{e^2}{2r} - \frac{e^2}{r} = -\frac{e^2}{2r}
$$

This is **unbounded below**. The smaller $r$ gets, the lower the energy goes, without limit. There is no minimum, so minimization fixes nothing. The atom would rather be smaller, always.

## And it gets worse

Suppose you set that aside and imagine the orbit is simply stable, the way planetary orbits are. There is a second, fatal problem.

**Accelerating charges radiate.** Circular motion is accelerated motion, so the orbiting electron continuously radiates electromagnetic waves. That radiated energy is energy the electron loses, so it spirals inward.

How fast? About $10^{-11}$ seconds for the atom to collapse.

Classical physics does not merely fail to explain atoms. It predicts, in ten picoseconds, that there are none.

## What quantum mechanics changes

The rescue comes from the **uncertainty principle**. For position and momentum it says that an uncertainty $\Delta x$ in position forces an uncertainty $\Delta p$ in momentum, with

$$
\Delta x\, \Delta p \gtrsim \hbar
$$

The more tightly you localize a particle, the less definite its momentum becomes.

Now redo the energy estimate. If the electron is localized within a distance $r$ of the proton, the potential energy is about $-e^2/r$ as before. But take $\Delta x \sim r$, and the momentum uncertainty is $\Delta p \simeq \hbar/r$. Even if the *average* momentum is zero, that spread carries kinetic energy:

$$
\text{KE} \simeq \frac{(\Delta p)^2}{2m_e} \simeq \frac{\hbar^2}{2 m_e r^2}
$$

Here is the whole trick. Classically the kinetic energy grew like $1/r$ as the atom shrank — the same rate the potential energy fell, which is why nothing stopped the collapse. Quantum mechanically it grows like $1/r^2$, **faster**. Squeezing the electron now costs more than it gains.

$$
E_{\text{qm}}(r) \simeq \frac{\hbar^2}{2m_e r^2} - \frac{e^2}{r}
$$

At small $r$ the first term dominates and is large and positive. At large $r$ the second dominates and is negative, rising toward zero. A minimum must exist in between. Differentiate and set to zero:

$$
-\frac{\hbar^2}{m_e r^3} + \frac{e^2}{r^2} = 0
\quad\Longrightarrow\quad
r = \frac{\hbar^2}{m_e e^2}
$$

That is the **Bohr radius** $a_0$ — the actual size of the hydrogen atom, obtained from an argument with no rigor at all, only the right physics.

## What the ground state is really like

The quantum picture is not an electron going round in circles. In the ground state of hydrogen the electron has a spherically symmetric probability distribution whose most probable radius is $a_0$. It has **zero angular momentum** — there is no orbit to speak of. It is a spherical cloud.

And because it is a stationary state, it does not radiate. It can stay there forever.

So quantum mechanics does both things classical physics could not: it **selects a size** for atoms, and it **removes the radiative instability**. The uncertainty principle, which is usually introduced as a limitation, turns out to be the thing holding matter up.

## What to take away

- Classically the atomic radius is undetermined, the energy is unbounded below, and radiation collapses the atom in $10^{-11}$ s.
- Uncertainty makes the kinetic energy grow as $1/r^2$ instead of $1/r$ under compression.
- That single change of exponent creates a minimum, and the minimum is the Bohr radius $a_0 = \hbar^2/m_e e^2$.
- The ground state is a spherical cloud with zero angular momentum, stationary and non-radiating.
- Uncertainty is not only a limit on knowledge. It is why matter has size.

---

## Exercises

**1.** Verify $E_{\text{cl}}(r) = -e^2/2r$ from the force balance, and confirm the virial relation $\text{KE} = -\tfrac{1}{2}V$ that it encodes.

**2.** Carry out the differentiation of $E_{\text{qm}}(r)$ and confirm $a_0 = \hbar^2/m_e e^2$. Then evaluate it numerically in metres and compare with the accepted size of a hydrogen atom.

**3.** Substitute $a_0$ back into $E_{\text{qm}}$ to estimate the ground state energy. Compare with the measured $-13.6\,\mathrm{eV}$. How good is an argument this crude?

**4.** Redo the quantum estimate for a potential $V(r) = -k/r^n$. For which $n$ does a minimum exist? What does your answer say about the stability of matter under forces other than Coulomb's?

**5.** *(Zwiebach problem 1.3)* Estimate the time for a classical electron starting at $r = a_0$ to spiral into the proton by radiating. The Larmor formula gives the radiated power of a charge with acceleration $a$ as $P = 2e^2a^2/3c^3$.

**6.** The argument replaced $\Delta p$ with a typical momentum, and $\Delta x$ with $r$, and dropped every numerical factor. Identify each place a factor of order unity was thrown away, and explain why the *scaling* $a_0 \propto \hbar^2/m_e e^2$ survives all of it even though the number does not.
