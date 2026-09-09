/-
Linearity of the Equations of Motion — proofs (Zwiebach 1.1).

Replace each `sorry` and run `lake build` (or open in VS Code with the Lean
extension). The checker is the kernel: nothing builds until the proof is real,
and nothing here hands you the answer.

`f` and `g` are linear maps on functions ℝ → ℝ (time to value), the setting of
the lesson's operator L = d/dt + 1/τ.
-/
import Mathlib.Algebra.Module.LinearMap.Defs
import Mathlib.Analysis.SpecialFunctions.Exp

set_option linter.style.header false

open Function

variable {V : Type*} [AddCommGroup V] [Module ℝ V]

/-- **Exercise 1a** (Zwiebach 1.1): the sum of two linear operators is linear.
Mathlib can state this as a bundled `LinearMap`; your job is the two fields. -/
def sumIsLinear (L₁ L₂ : V →ₗ[ℝ] V) : V →ₗ[ℝ] V where
  toFun := fun u => L₁ u + L₂ u
  map_add' := by
    sorry
  map_smul' := by
    sorry

/-- **Exercise 1b**: the composition L₁ ∘ L₂ is linear. -/
def productIsLinear (L₁ L₂ : V →ₗ[ℝ] V) : V →ₗ[ℝ] V where
  toFun := fun u => L₁ (L₂ u)
  map_add' := by
    sorry
  map_smul' := by
    sorry

/-- **Exercise 4a**: if `L u = 0` then `L (α • u) = 0` — a multiple of a
solution is a solution. This is the whole superposition principle, in one line
per step. -/
theorem scaled_solution (L : V →ₗ[ℝ] V) (u : V) (α : ℝ) (h : L u = 0) :
    L (α • u) = 0 := by
  sorry

/-- **The general superposition**: two solutions combine, with any complex —
here real — coefficients, into a third. -/
theorem superposition (L : V →ₗ[ℝ] V) (u₁ u₂ : V) (α β : ℝ)
    (h₁ : L u₁ = 0) (h₂ : L u₂ = 0) : L (α • u₁ + β • u₂) = 0 := by
  sorry
