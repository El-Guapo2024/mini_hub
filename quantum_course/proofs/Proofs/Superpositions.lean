/-
Quantum Superpositions — proofs (Zwiebach 1.4, lesson exercise 3).

Replace each `sorry`; `lake build` is the grader.
-/
import Mathlib.Analysis.SpecialFunctions.Complex.Circle

set_option linter.style.header false

open Complex

/-- **Exercise 3**: for the canonical state
`cos(θ/2)|A⟩ + e^{iφ} sin(θ/2)|B⟩`, the two outcome probabilities sum to 1 for
every `θ` and `φ` — and `φ` has already dropped out of both, which is
exercise 4. -/
theorem probabilities_sum_to_one (θ φ : ℝ) :
    ‖(Real.cos (θ / 2) : ℂ)‖ ^ 2 +
      ‖Complex.exp (φ * I) * (Real.sin (θ / 2) : ℂ)‖ ^ 2 = 1 := by
  sorry
