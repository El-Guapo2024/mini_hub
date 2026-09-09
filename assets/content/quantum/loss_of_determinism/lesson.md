# Loss of Determinism

By the end of the nineteenth century, physicists were certain light was a wave. Maxwell had predicted propagating fluctuations of the electric and magnetic fields in 1865 and conjectured that light was one; experiment proved him right.

The certainty didn't last. Blackbody radiation and the photoemission of electrons refused to behave. In 1905 Einstein postulated that the energy in a light beam comes in discrete packets — that light is, in some sense, made of particles. He found the idea disturbing himself, and correctly anticipated that something behaving as both particle and wave would bring down classical physics.

It took until 1925 for the community to accept it. Compton's scattering experiments of 1923 convinced most of the holdouts. Those packets are now called **photons**.

## What a photon is

A photon's energy depends only on the colour of the light:

$$
E = h\nu
$$

with $h \simeq 6.626 \times 10^{-34}\,\mathrm{J\cdot s}$ Planck's constant. The Schrödinger equation uses the reduced constant $\hbar = h/2\pi$. Frequency fixes wavelength through $\nu\lambda = c$, with $c \simeq 2.998\times10^8\,\mathrm{m/s}$.

So every photon of 520 nm light is green, and every one of them carries the same energy. To put more energy in a green beam you cannot make the photons brighter — you can only send more of them.

A photon carries very little energy; a small laser pulse holds billions. Your eye, though, is an excellent photon detector: in total darkness you can see a flash of as few as ten photons.

One caution about the word "particle." A photon is a **quantum mechanical particle** — a packet of energy and momentum not made of smaller packets. It is *not* a Newtonian corpuscle with a definite position and velocity.

## The polarizer

Here is the experiment that breaks determinism.

A polarizer transmits light polarized along its preferential direction, say $\hat{x}$, and completely absorbs light polarized along $\hat{y}$. Now send in light polarized at an angle $\alpha$ to the $x$ axis.

Treat it as a wave. The incident field of amplitude $E_0$ decomposes as

$$
\mathbf{E}_\alpha = E_0\cos\alpha\;\hat{x} + E_0\sin\alpha\;\hat{y}
$$

The polarizer passes the $\hat{x}$ component and absorbs the $\hat{y}$ one, leaving $\mathbf{E} = E_0 \cos\alpha\,\hat{x}$. Energy in a wave goes as the square of the amplitude, so the fraction of the beam's energy transmitted is

$$
\cos^2\alpha
$$

and the emerging light has the same frequency as the incident light. So far, entirely classical, and entirely correct.

## Now count photons

The incident photons are all identical, and photons do not interact with each other. To remove any doubt about that, send the beam through **one photon at a time**.

The emerging light has the same frequency as the incident light, so it has the same energy per photon. Therefore each photon either goes through whole or is absorbed whole. A fraction of a photon getting through would emerge with lower energy and so lower frequency — and that never happens.

But the wave analysis says a fraction $\cos^2\alpha$ of the energy is transmitted, so a fraction $\cos^2\alpha$ of the photons must go through, and $1 - \cos^2\alpha$ must be absorbed.

**If all the photons are identical, why does what happens to one not happen to all of them?**

## The answer

There is a genuine loss of determinism. Nobody can predict whether a given photon will pass or be absorbed. The most anyone can do is give probabilities:

$$
P(\text{transmitted}) = \cos^2\alpha, \qquad P(\text{absorbed}) = 1 - \cos^2\alpha
$$

This is a stronger statement than "we don't know enough." It says the outcome is not determined by anything under the experimenter's control.

Two escape routes were tried. Perhaps the polarizer isn't homogeneous, and the outcome depends on exactly where the photon strikes — experiment says no. More seriously, Einstein and others proposed **hidden variables**: the photons only appear identical, and carry some further property, not yet understood, that fixes the outcome in advance.

Hidden variables sound untestable. They are not. Through the work of John Bell and others, experiments have ruled out most versions of them. Nobody has found a way to restore determinism, and it now looks impossible.

## States

To describe photons quantum mechanically we use **states**, which are the same objects as wave functions in another notation. Write a photon polarized along $x$ as

$$
|\text{photon};x\rangle
$$

and one polarized along $y$ as $|\text{photon};y\rangle$. Think of them for now as vectors in a space of photon states. A photon polarized at angle $\alpha$ is a **superposition**:

$$
|\text{photon};\alpha\rangle = \cos\alpha\,|\text{photon};x\rangle + \sin\alpha\,|\text{photon};y\rangle
$$

Compare that with the decomposition of the electric field above. The two look alike, and they are not the same thing at all — one describes a field, the other the state of a single photon.

Any photon emerging beyond the polarizer is polarized along $x$, so it is in the state $|\text{photon};x\rangle$ exactly. Note what is missing: the field beyond the polarizer carried a factor $\cos\alpha$ recording the amplitude. For one photon there is no room for such a factor. It either is there, in that state, or it isn't. The $\cos\alpha$ has become a probability instead.

## A footnote worth keeping

At the Fifth Solvay Conference in 1927 — seventeen of the twenty-nine attendees were or became Nobel laureates — Einstein, unhappy with all this, said "God does not play dice." Bohr is supposed to have replied, "Einstein, stop telling God what to do."

Bohr was willing to give up determinism. Einstein never was.

## What to take away

- $E = h\nu$: a photon's energy is fixed by colour alone.
- A photon passes a polarizer whole or not at all, with probability $\cos^2\alpha$.
- Identical photons, identical conditions, different outcomes. That is the loss of determinism.
- Hidden variables were the natural rescue, and experiment has ruled them out.
- A photon at angle $\alpha$ is in a superposition of $x$ and $y$ states, and the $\cos\alpha$ that was a field amplitude becomes a probability amplitude.

---

## Exercises

**1.** *(Zwiebach 1.5)* Light polarized along $x$ hits two polarizers in sequence. The first is at $45^\circ$, and the second is along $y$. What fraction of the incident photons emerge from the second?

**2.** Without the first polarizer, what fraction of the photons polarized along $x$ would pass the $y$ polarizer? Explain how *inserting* an extra absorber increases the number of photons getting through.

**3.** *(Zwiebach 1.6)* Now put $N \ge 2$ polarizers in sequence, each rotated counterclockwise by the same angle $\theta$ from the previous one. The first sits at $\theta$ from the $x$ axis and the last is along $y$. With light polarized along $x$ incident, find the fraction emerging beyond the last polarizer. For $N = 500$ and 1000 incident photons, how many are expected to emerge? *(Answer: 995.)*

**4.** Take the limit $N \to \infty$ in the previous exercise. What fraction emerges, and what has the stack of polarizers done to the photon's polarization?

**5.** A photon in the state $\cos\alpha\,|x\rangle + \sin\alpha\,|y\rangle$ passes an $x$ polarizer. What is its state afterwards? Show that sending it through a second $x$ polarizer transmits it with probability 1, and say why that is not in tension with the first passage being probabilistic.

**6.** Estimate the number of photons per second emitted by a 1 W green laser at 520 nm. Compare with the ten photons your eye needs to register a flash.
