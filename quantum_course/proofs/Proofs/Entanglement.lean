/-
Entanglement — proofs (Zwiebach 1.5, lesson exercise 1).

Replace each `sorry`; `lake build` is the grader.
-/
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Complex.Basic

set_option linter.style.header false

/-- **Exercise 1** (Zwiebach 1.9): the singlet cannot be factorized. Matching
`(α₁|↑⟩+α₂|↓⟩)⊗(β₁|↑⟩+β₂|↓⟩)` against
`(1/√2)(|↑⟩⊗|↓⟩ − |↓⟩⊗|↑⟩)` forces the four displayed equations, and no
complex numbers satisfy them — so no such factorization exists. -/
theorem singlet_not_factorizable :
    ¬ ∃ a₁ a₂ b₁ b₂ : ℂ,
        a₁ * b₁ = 0 ∧
        a₁ * b₂ = (1 / Real.sqrt 2 : ℝ) ∧
        a₂ * b₁ = -(1 / Real.sqrt 2 : ℝ) ∧
        a₂ * b₂ = 0 := by
  sorry
