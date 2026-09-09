/-
Complex Numbers Are Essential — proofs (Zwiebach 1.2, lesson exercises 2, 3, 6).

Replace each `sorry`; `lake build` is the grader.
-/
import Mathlib.Analysis.SpecialFunctions.Complex.Circle

set_option linter.style.header false

open Complex

/-- **Exercise 2a**: a complex number is real exactly when it equals its own
conjugate. -/
theorem real_iff_conj_eq (z : ℂ) : (starRingEnd ℂ) z = z ↔ z.im = 0 := by
  sorry

/-- **Exercise 2b**: purely imaginary exactly when conjugation flips the sign. -/
theorem imaginary_iff_conj_neg (z : ℂ) : (starRingEnd ℂ) z = -z ↔ z.re = 0 := by
  sorry

/-- **Exercise 3**: the norm of a product is the product of the norms. -/
theorem norm_of_product (z₁ z₂ : ℂ) : ‖z₁ * z₂‖ = ‖z₁‖ * ‖z₂‖ := by
  sorry

/-- **Exercise 6**: a constant phase changes no probability — `e^{iχ}Ψ` has the
same norm as `Ψ`, for every real `χ`. This is why an overall phase is not
physical. -/
theorem phase_preserves_norm (χ : ℝ) (ψ : ℂ) :
    ‖Complex.exp (χ * I) * ψ‖ = ‖ψ‖ := by
  sorry
