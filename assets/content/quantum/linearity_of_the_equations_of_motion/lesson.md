# Linearity of the Equations of Motion

A physical theory is a set of equations for some **dynamical variables**. In classical mechanics those are the positions and velocities of particles. A *solution* of the equations describes a possible reality according to the theory — an expanding universe is a solution of Einstein's equations, so an expanding universe is possible.

Theories divide into linear and nonlinear ones, and the difference is enormous.

## What linearity buys you

In a linear theory, **if you add two solutions you get a third solution**.

Maxwell's electromagnetism is the classic example. One solution describes a wave travelling north; another describes a wave travelling east. Because the theory is linear, there is a third solution with both waves present at once, passing through each other without interacting at all. The electric field of the sum is the sum of the electric fields; likewise the magnetic field.

This sounds abstract until you notice you are sitting in it. The air around you carries waves from thousands of phones, hundreds of wireless messages, and every radio and television station in range — each propagating oblivious to the others. A single transatlantic cable carries millions of calls simultaneously. All of that is linearity.

## Saying it precisely

Write the equation as

$$
L\,u = 0
$$

where $u$ is the unknown and $L$ is an **operator** — something that acts on $u$. The unknown can be a number, a function of time, a function of spacetime, or a whole collection of unknowns. $L$ is a **linear operator** if for any number $a$ and any $u_1, u_2$:

$$
L(a\,u) = a\,L(u), \qquad L(u_1 + u_2) = L(u_1) + L(u_2)
$$

Those two properties are the whole definition, and everything else follows. Combining them, for numbers $\alpha$ and $\beta$:

$$
L(\alpha u_1 + \beta u_2) = \alpha\, L(u_1) + \beta\, L(u_2)
$$

So if $L u_1 = 0$ and $L u_2 = 0$, then $L(\alpha u_1 + \beta u_2) = 0$ as well. The combination $\alpha u_1 + \beta u_2$ is called the **general superposition** of the two solutions, and it is a solution too.

That word — superposition — is going to do a great deal of work later. It starts here, as nothing more mysterious than a consequence of linearity.

## A worked example

Consider

$$
\frac{du}{dt} + \frac{u}{\tau} = 0
$$

with $\tau$ a constant with units of time. Put it in the form $Lu = 0$ by defining

$$
L = \frac{d}{dt} + \frac{1}{\tau}
$$

where it is understood that the derivative acts on whatever stands to the right, and $1/\tau$ acts by multiplication. Check the two properties. For a constant $a$:

$$
L(a u) = \frac{d(au)}{dt} + \frac{au}{\tau} = a\left(\frac{du}{dt} + \frac{u}{\tau}\right) = a\,L(u)
$$

And for two functions:

$$
L(u_1 + u_2) = \frac{d(u_1+u_2)}{dt} + \frac{u_1+u_2}{\tau} = L(u_1) + L(u_2)
$$

So the equation is linear. With a little practice you recognise these by inspection.

## The part that should surprise you

Einstein's general relativity is **nonlinear**. Two gravitational wave solutions cannot be added to make a third. This is a large part of why the theory is so much harder than Maxwell's.

But here is the one that matters for this course: **classical mechanics is also nonlinear.** Newton's second law for a particle on a line in a potential $V(x)$ is

$$
m\,\frac{d^2 x}{dt^2} = -V'(x(t))
$$

The dynamical variable is $x(t)$. If $x_1(t)$ and $x_2(t)$ are both solutions, $x_1 + x_2$ is generally *not* one — because $V'(x_1 + x_2)$ is not $V'(x_1) + V'(x_2)$ unless $V'$ happens to be a linear function. There is no general way to build a third solution out of two.

So the theory you already know, the intuitive one, is the complicated nonlinear one. And quantum mechanics — the theory with the reputation for being strange — is linear. Its equations satisfy the superposition principle exactly, always, with no approximation.

Linearity is a sign of profound simplicity. It is arguably the reason quantum mechanics is, in a precise technical sense, *simpler* than the physics it replaced.

## What to take away

- Linear means: multiples of solutions are solutions, and sums of solutions are solutions.
- The test is two lines: $L(au) = aL(u)$ and $L(u_1+u_2) = L(u_1)+L(u_2)$.
- Superposition is not a quantum mystery. It is what linearity means, and Maxwell had it first.
- Classical mechanics is nonlinear. Quantum mechanics is linear. That is the opposite of most people's intuition, and it is the first real clue about what kind of theory this is.

---

## Exercises

**1.** *(Zwiebach 1.1)* Let $L_1$ and $L_2$ be linear operators, with $(L_1+L_2)u \equiv L_1u + L_2u$ and $(L_1L_2)u \equiv L_1(L_2u)$. Is $L_1 + L_2$ linear? Is $L_1 L_2$ linear? Prove both.

**2.** Classify each equation as linear or not, treating $u$ as the unknown:

  (a) $\dfrac{du}{dt} = -3u$  (b) $\dfrac{du}{dt} = u^2$  (c) $\dfrac{d^2u}{dt^2} + \omega^2 u = 0$  (d) $\dfrac{du}{dt} + u = 5$  (e) $u\dfrac{du}{dx} = 0$

  Part (d) is worth thinking about carefully.

**3.** Write a function that takes an operator and decides whether it is linear, by testing $L(\alpha u_1 + \beta u_2) - \alpha L(u_1) - \beta L(u_2) = 0$ symbolically.

**4.** Show explicitly that if $u_1(t) = e^{-t/\tau}$ solves $\frac{du}{dt} + \frac{u}{\tau} = 0$, then so does $\alpha u_1(t)$ for any constant $\alpha$ — and that $u(t) = t\,e^{-t/\tau}$ does not.

**5.** Newton's second law $m\ddot{x} = -V'(x)$ is nonlinear for general $V$. Find every potential $V(x)$ for which it *is* linear, and say what physical system each one describes.

**6.** The heat equation $\partial_t u = \kappa\, \partial_x^2 u$ is linear, yet heat flow is irreversible while the Schrödinger equation — also linear — is reversible. Since both are linear, linearity cannot be what distinguishes them. What does?
