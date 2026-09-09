# Amplitudes and the Mach-Zehnder Interferometer

A beam splitter is a half-silvered mirror: send light in, and half comes out one side and half the other. Turn the source down until photons arrive one at a time, and each photon leaves through exactly one port. Which one appears to be random, fifty-fifty.

That much is not yet quantum mechanics. The quantum part is what happen when you recombine the two paths.

## States as vectors

A photon in the apparatus can be on the upper beam or the lower beam. Write its state as a column of two **amplitudes**:

$$
\begin{pmatrix} \alpha \\ \beta \end{pmatrix}
$$

where $\alpha$ is the amplitude to be on the upper beam and $\beta$ the amplitude to be on the lower one. Amplitudes are complex numbers, and they are not probabilities. The probability of finding the photon on a beam is the modulus squared of its amplitude:

$$
P_{\text{upper}} = |\alpha|^2, \qquad P_{\text{lower}} = |\beta|^2
$$

Since the photon is somewhere, $|\alpha|^2 + |\beta|^2 = 1$. A photon that entered from the top and has not met anything yet is $\begin{pmatrix} 1 \\ 0 \end{pmatrix}$.

## The beam splitter is a matrix

A beam splitter takes an incoming state and produces an outgoing one. It does this linearly — that is the first key feature of quantum mechanics — so it is a $2 \times 2$ matrix. We will use the balanced splitter

$$
\mathrm{BS} = \frac{1}{\sqrt{2}} \begin{pmatrix} 1 & 1 \\ 1 & -1 \end{pmatrix}
$$

Send in a photon from the top:

$$
\mathrm{BS} \begin{pmatrix} 1 \\ 0 \end{pmatrix}
= \frac{1}{\sqrt{2}} \begin{pmatrix} 1 \\ 1 \end{pmatrix}
$$

Both amplitudes are $1/\sqrt{2}$, so both probabilities are $\left|1/\sqrt{2}\right|^2 = 1/2$. Fifty-fifty, as observed. The photon is not on one beam or the other — it is in a **superposition** of both.

Notice that the matrix cannot be just anything. Whatever goes in, the total probability out must still be $1$. That requirement is exactly the statement that $\mathrm{BS}$ is **unitary**:

$$
\mathrm{BS}^\dagger \mathrm{BS} = I
$$

Every operation in quantum mechanics that isn't a measurement is a unitary matrix, for this reason. It is worth checking by hand that ours is.

## Two beam splitters

The Mach-Zehnder interferometer sends the two beams to mirrors, which bring them back together at a second, identical beam splitter. Two detectors, $D_0$ and $D_1$, sit at the two output ports.

Now argue classically for a moment. The photon has a half chance of taking each path, and at the second splitter it again has a half chance of each port. Whichever way you count it, you expect the photon to arrive at $D_0$ half the time and $D_1$ half the time.

The quantum calculation is to apply the matrix twice:

$$
\mathrm{BS}^2 = \frac{1}{2}\begin{pmatrix} 1 & 1 \\ 1 & -1 \end{pmatrix}\begin{pmatrix} 1 & 1 \\ 1 & -1 \end{pmatrix}
= \frac{1}{2}\begin{pmatrix} 2 & 0 \\ 0 & 2 \end{pmatrix} = I
$$

The two beam splitters undo each other. A photon entering from the top leaves as $\begin{pmatrix} 1 \\ 0 \end{pmatrix}$: it arrives at $D_0$ **every single time**, and $D_1$ never fires at all.

This is the result to sit with. Probabilities cannot produce it. Adding two one-half chances can never give you zero. What cancelled at $D_1$ were the *amplitudes* — one path contributed $+\tfrac12$ and the other $-\tfrac12$, and they destroyed each other before anything was squared.

Amplitudes add. Probabilities are what you get at the end, by squaring. Doing it in the other order gives the wrong answer.

And there is only ever one photon in the apparatus. It is not interfering with another photon; it is interfering with itself.

## Putting a phase in one arm

Slide a piece of glass into the upper arm. It delays that beam, multiplying its amplitude by a phase $e^{i\delta}$ while leaving the lower beam alone:

$$
P(\delta) = \begin{pmatrix} e^{i\delta} & 0 \\ 0 & 1 \end{pmatrix}
$$

The whole apparatus is now $\mathrm{BS}\, P(\delta)\, \mathrm{BS}$, and on the input $\begin{pmatrix} 1 \\ 0 \end{pmatrix}$ it gives

$$
\frac{1}{2} \begin{pmatrix} e^{i\delta} + 1 \\ e^{i\delta} - 1 \end{pmatrix}
$$

Squaring the amplitudes:

$$
P(D_0) = \frac{|e^{i\delta}+1|^2}{4} = \cos^2\frac{\delta}{2},
\qquad
P(D_1) = \frac{|e^{i\delta}-1|^2}{4} = \sin^2\frac{\delta}{2}
$$

They sum to $1$, as they must. At $\delta = 0$ we recover $D_0$ always. At $\delta = \pi$ the situation is exactly reversed and every photon lands at $D_1$. In between, the photon divides between the detectors in a way that depends smoothly on how much glass is in one arm.

That is the signature of interference, and it is measurable one photon at a time.

## What to take away

- A state is a vector of complex amplitudes; probability is amplitude squared.
- Amplitudes add first, and only then get squared. Reversing that order loses the physics.
- Anything that isn't a measurement is a unitary matrix, because probability has to come out to $1$.
- Interference is not a property of beams. A single photon does it on its own.

Everything above is $2 \times 2$ complex linear algebra, and nothing in this course will ever be more than a bigger version of it.

---

## Exercises

**1.** Verify by direct multiplication that $\mathrm{BS}^\dagger \mathrm{BS} = I$ for the balanced splitter above.

**2.** A photon enters the interferometer from the *bottom*, in the state $\begin{pmatrix} 0 \\ 1 \end{pmatrix}$, with no phase shifter. Which detector fires, and how often?

**3.** Show that the matrix $\dfrac{1}{\sqrt{2}}\begin{pmatrix} 1 & i \\ i & 1 \end{pmatrix}$ is also a legitimate balanced beam splitter. Compute its square. Is it still the identity? What does that mean physically?

**4.** For what value of $\delta$ do the two detectors fire equally often? Find every solution in $0 \le \delta < 2\pi$.

**5.** Suppose you block the lower arm entirely, so a photon taking that path is absorbed and never reaches the second splitter. Of the photons that *do* reach a detector, what fraction arrive at $D_1$? Compare with the unblocked case and explain why blocking a path makes a detector fire that was previously dark.

**6.** A phase shifter $e^{i\delta}$ is placed in the upper arm and a second one $e^{i\varepsilon}$ in the lower arm. Show that $P(D_0)$ depends only on the difference $\delta - \varepsilon$, not on the two phases separately. What does this tell you about the physical meaning of an overall phase?
