# Complex Numbers Are Essential

Quantum mechanics is the first theory in physics that genuinely **requires** complex numbers. Not as a convenience, not as a bookkeeping trick that could be undone at the end — as the thing the theory is made of.

That claim needs defending, because complex numbers show up in classical physics all the time. They are just never necessary there.

## The numbers themselves

The imaginary unit $i$ is defined by $i = \sqrt{-1}$, so that $i^2 = -1$. A general complex number is

$$
z = a + ib, \qquad a, b \in \mathbb{R}
$$

with $a$ the **real part** and $b$ the **imaginary part**:

$$
\mathrm{Re}(z) = a, \qquad \mathrm{Im}(z) = b
$$

The **complex conjugate** flips the sign of the imaginary part:

$$
z^* = a - ib
$$

Two quick facts worth checking yourself: $z$ is real exactly when $z^* = z$, and purely imaginary exactly when $z^* = -z$. Zero is both.

The **norm** of $z$ is the nonnegative real number

$$
|z| = \sqrt{a^2 + b^2}, \qquad \text{equivalently} \qquad |z|^2 = z^* z
$$

That second form is the one to remember. It says the norm-squared is a number multiplied by its own conjugate, and it is the operation that will turn amplitudes into probabilities for the rest of this course.

## The complex plane

Picture $z = a + ib$ as a vector in a plane: real part along $x$, imaginary part along $y$. The norm is the length of that vector.

Take the unit vector at angle $\theta$ from the $x$ axis. Its components are $\cos\theta$ and $\sin\theta$, so it is the complex number $\cos\theta + i\sin\theta$. Euler's identity names it:

$$
e^{i\theta} = \cos\theta + i\sin\theta
$$

A number of the form $e^{i\chi}$ with $\chi$ real is called a **pure phase**. It has norm one — it only rotates. Every complex number can be written in polar form

$$
z = r e^{i\theta}, \qquad r = |z|, \quad \theta = \arctan(b/a)
$$

so a complex number is a length and an angle. The length will become a probability. The angle will become the thing that makes interference possible.

## Why classical physics doesn't need them

Complex numbers are often *useful* in classical mechanics and in Maxwell's theory — they make oscillations easy to handle. But none of the dynamical variables in those theories *is* complex. The electric field is a real number at every point. So is a position, a velocity, a pressure.

That is not an accident of style. **Every measurement in physics yields a real number.** A meter never reads $3 + 2i$. In classical physics you can always take the real part at the end and lose nothing, because the imaginary part was scaffolding you erected yourself.

## Why quantum mechanics does

The Schrödinger equation carries an explicit $i$ multiplying the time derivative. That single factor makes real solutions impossible: the dynamical variable of quantum mechanics — the **wave function** $\Psi$ — is a complex-valued function. At every point in space and every moment in time, it evaluates to a complex number:

$$
\Psi(x, t) \in \mathbb{C}
$$

There is no taking the real part at the end. The $i$ is load-bearing, and here is what it carries. Ordinary wave equations are second order in time. The Schrödinger equation is only **first** order in time — and a first-order equation would normally give you exponential growth or decay, not waves. It is precisely the factor of $i$ multiplying $\partial_t$ that turns that decay into oscillation, and so permits waves at all.

## So how do you measure anything?

If the wave function is complex and every measurement is real, the connection between them has to be indirect. Born's proposal was to identify probabilities — which are nonnegative real numbers — with the norm-squared of the wave function:

$$
P = |\Psi|^2 = \Psi^* \Psi
$$

For this reason $\Psi$ is called a **probability amplitude**. And notice what kind of theory this makes quantum mechanics. Underneath the probabilities sit complex amplitudes, and the Schrödinger equation is an equation **for the amplitudes, not for the probabilities**.

That is an unusual arrangement. The thing that obeys the law of motion is not the thing you measure. You evolve the amplitude, and only at the end do you square it.

It is also exactly why interference exists. Two amplitudes can be $+\tfrac12$ and $-\tfrac12$ and cancel completely; two probabilities, both nonnegative, never can.

## What to take away

- $|z|^2 = z^* z$, and a pure phase $e^{i\theta}$ has norm one.
- Classical physics uses complex numbers; quantum mechanics is built from them.
- The $i$ in the Schrödinger equation is what allows waves in a first-order equation.
- The wave function is a probability amplitude. Probability is $|\Psi|^2$.
- The equation of motion governs the amplitude. Squaring happens last, and that ordering is where interference comes from.

The mathematical setting for all of this is a **complex vector space** — objects that can be added, and multiplied by complex numbers, and stay in the space. Thinking of $\Psi$ as a vector in such a space will carry you a long way.

---

## Exercises

**1.** *(Zwiebach 1.4)* Write $i$ as a pure phase. What are the two square roots of $i$?

**2.** Verify that $z$ is real if and only if $z^* = z$, and purely imaginary if and only if $z^* = -z$.

**3.** Show that $|z_1 z_2| = |z_1|\,|z_2|$ for any two complex numbers. Is $|z_1 + z_2| = |z_1| + |z_2|$ ever true? When?

**4.** Solve $x^2 = -4$ over the complex numbers, then solve $x^3 = 1$. How many solutions does each have, and where do they sit in the complex plane?

**5.** Let $\Psi = \alpha + \beta$ where $\alpha$ and $\beta$ are complex. Expand $|\Psi|^2$ in terms of $\alpha$, $\beta$, and their conjugates. Identify the term that has no counterpart when you add two probabilities instead of two amplitudes. That term is interference — say what has to be true of $\alpha$ and $\beta$ for it to vanish.

**6.** The wave function $\Psi$ and the wave function $e^{i\chi}\Psi$, with $\chi$ a real constant, give identical probabilities everywhere. Show this. Does the same hold if $\chi$ is allowed to depend on $x$?
