/-
Copyright (c) 2019 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes, Johan Commelin
-/

import ring_theory.integral_closure

universes u v w
open polynomial set function

noncomputable theory

/- Turn down the instance priority for subtype.decidable_eq and use classical.dec_eq everywhere,
  to avoid diamonds -/
local attribute [instance, priority 0] subtype.decidable_eq

variables {α : Type u} {β : Type v}

section min_poly_def
variables [decidable_eq α] [decidable_eq β] [comm_ring α] [comm_ring β] [algebra α β]

def minimal_polynomial {x : β} (hx : is_integral α x) : polynomial α :=
well_founded.min polynomial.degree_lt_wf _ (ne_empty_iff_exists_mem.mpr hx)

end min_poly_def

namespace minimal_polynomial

section ring
variables [decidable_eq α] [decidable_eq β] [comm_ring α] [comm_ring β] [algebra α β]
variables {x : β} (hx : is_integral α x)

protected lemma monic : monic (minimal_polynomial hx) :=
(well_founded.min_mem degree_lt_wf _ (ne_empty_iff_exists_mem.mpr hx)).1

@[simp] protected lemma aeval : aeval α β x (minimal_polynomial hx) = 0 :=
(well_founded.min_mem degree_lt_wf _ (ne_empty_iff_exists_mem.mpr hx)).2

protected lemma min {p : polynomial α} (pmonic : p.monic) (hp : polynomial.aeval α β x p = 0) :
  degree (minimal_polynomial hx) ≤ degree p :=
le_of_not_lt $ well_founded.not_lt_min degree_lt_wf _ (ne_empty_iff_exists_mem.mpr hx) ⟨pmonic, hp⟩

end ring

section field
variables [discrete_field α] [discrete_field β] [algebra α β]
variables {x : β} (hx : is_integral α x)

protected lemma ne_zero : (minimal_polynomial hx) ≠ 0 :=
ne_zero_of_monic (minimal_polynomial.monic hx)

protected lemma degree_le_of_ne_zero
  {p : polynomial α} (pnz : p ≠ 0) (hp : polynomial.aeval α β x p = 0) :
  degree (minimal_polynomial hx) ≤ degree p :=
begin
  rw ← degree_mul_leading_coeff_inv p pnz,
  apply minimal_polynomial.min _ (monic_mul_leading_coeff_inv pnz),
  simp [hp]
end

protected lemma unique {p : polynomial α} (pmonic : p.monic) (hp : polynomial.aeval α β x p = 0)
  (pmin : ∀ q : polynomial α, q.monic → polynomial.aeval α β x q = 0 → degree p ≤ degree q) :
  p = minimal_polynomial hx :=
begin
  symmetry, apply eq_of_sub_eq_zero,
  by_contra hnz,
  have := minimal_polynomial.degree_le_of_ne_zero hx hnz (by simp [hp]),
  contrapose! this,
  apply degree_sub_lt _ (minimal_polynomial.ne_zero hx),
  { rw [(minimal_polynomial.monic hx).leading_coeff, pmonic.leading_coeff] },
  { exact le_antisymm (minimal_polynomial.min hx pmonic hp)
      (pmin (minimal_polynomial hx) (minimal_polynomial.monic hx) (minimal_polynomial.aeval hx)) },
end

protected lemma dvd {p : polynomial α} (hp : polynomial.aeval α β x p = 0) :
  minimal_polynomial hx ∣ p :=
begin
  rw ← dvd_iff_mod_by_monic_eq_zero (minimal_polynomial.monic hx),
  by_contra hnz,
  have := minimal_polynomial.degree_le_of_ne_zero hx hnz _,
  { contrapose! this,
    exact degree_mod_by_monic_lt _ (minimal_polynomial.monic hx) (minimal_polynomial.ne_zero hx) },
  { rw ← mod_by_monic_add_div p (minimal_polynomial.monic hx) at hp,
    simpa using hp }
end

protected lemma degree_ne_zero : degree (minimal_polynomial hx) ≠ 0 :=
begin
  assume deg_eq_zero,
  have ndeg_eq_zero : nat_degree (minimal_polynomial hx) = 0,
  { simpa using congr_arg nat_degree (eq_C_of_degree_eq_zero deg_eq_zero) },
  have eq_one : minimal_polynomial hx = 1,
  { rw eq_C_of_degree_eq_zero deg_eq_zero, congr,
    simpa [ndeg_eq_zero.symm] using (minimal_polynomial.monic hx).leading_coeff },
  simpa [eq_one, aeval_def] using minimal_polynomial.aeval hx
end

protected lemma not_is_unit : ¬ is_unit (minimal_polynomial hx) :=
begin
  intro H, apply minimal_polynomial.degree_ne_zero hx,
  exact degree_eq_zero_of_is_unit H
end

protected lemma degree_pos : 0 < degree (minimal_polynomial hx) :=
degree_pos_of_ne_zero_of_nonunit (minimal_polynomial.ne_zero hx) (minimal_polynomial.not_is_unit hx)

protected lemma prime : prime (minimal_polynomial hx) :=
begin
  refine ⟨minimal_polynomial.ne_zero hx, minimal_polynomial.not_is_unit hx, _⟩,
  rintros p q ⟨d, h⟩,
  have :    polynomial.aeval α β x (p*q) = 0 := by simp [h, minimal_polynomial.aeval hx],
  replace : polynomial.aeval α β x p = 0 ∨ polynomial.aeval α β x q = 0 := by simpa,
  cases this; [left, right]; apply minimal_polynomial.dvd; assumption
end

protected lemma irreducible : irreducible (minimal_polynomial hx) :=
irreducible_of_prime (minimal_polynomial.prime hx)

@[simp] protected lemma algebra_map (a : α) (ha : is_integral α (algebra_map β a)) :
  minimal_polynomial ha = X - C a :=
begin
  refine (minimal_polynomial.unique ha (monic_X_sub_C a) (by simp [aeval_def]) _).symm,
  intros q hq H,
  rw degree_X_sub_C,
  suffices : 0 < degree q,
  { -- This part is annoying and shouldn't be there.
    have q_ne_zero : q ≠ 0,
    { apply polynomial.ne_zero_of_degree_gt this },
    rw degree_eq_nat_degree q_ne_zero at this ⊢,
    rw [← with_bot.coe_zero, with_bot.coe_lt_coe] at this,
    rwa [← with_bot.coe_one, with_bot.coe_le_coe], },
  apply degree_pos_of_root (ne_zero_of_monic hq),
  show is_root q a,
  apply is_field_hom.injective (algebra_map β : α → β),
  rw [is_ring_hom.map_zero (algebra_map β : α → β), ← H],
  convert polynomial.hom_eval₂ _ _ _ _,
  { exact is_semiring_hom.id },
  { apply_instance }
end

variable (β)
protected lemma algebra_map' (a : α) :
  minimal_polynomial (@is_integral_algebra_map α β _ _ _ _ _ a) =
  X - C a :=
minimal_polynomial.algebra_map _ _
variable {β}

@[simp] protected lemma zero {h₀ : is_integral α (0:β)} :
  minimal_polynomial h₀ = X :=
by simpa only [add_zero, polynomial.C_0, sub_eq_add_neg, neg_zero, algebra.map_zero]
  using minimal_polynomial.algebra_map' β (0:α)

@[simp] protected lemma one {h₁ : is_integral α (1:β)} :
  minimal_polynomial h₁ = X - 1 :=
by simpa only [algebra.map_one, polynomial.C_1, sub_eq_add_neg]
  using minimal_polynomial.algebra_map' β (1:α)

protected lemma root {x : β} (hx : is_integral α x) {y : α}
  (h : is_root (minimal_polynomial hx) y) : algebra_map β y = x :=
begin
  have ndeg_one : nat_degree (minimal_polynomial hx) = 1,
  { rw ← polynomial.degree_eq_iff_nat_degree_eq_of_pos (nat.zero_lt_one),
    exact degree_eq_one_of_irreducible_of_root (minimal_polynomial.irreducible hx) h },
  have coeff_one : (minimal_polynomial hx).coeff 1 = 1,
  { simpa [ndeg_one, leading_coeff] using (minimal_polynomial.monic hx).leading_coeff },
  have hy : y = - coeff (minimal_polynomial hx) 0,
  { rw (minimal_polynomial hx).as_sum at h,
    apply eq_neg_of_add_eq_zero,
    simpa [ndeg_one, finset.sum_range_succ, coeff_one] using h },
  subst y,
  rw [algebra.map_neg, neg_eq_iff_add_eq_zero],
  have H := minimal_polynomial.aeval hx,
  rw (minimal_polynomial hx).as_sum at H,
  simpa [ndeg_one, finset.sum_range_succ, coeff_one, aeval_def] using H
end

@[simp] protected lemma coeff_zero_eq_zero : coeff (minimal_polynomial hx) 0 = 0 ↔ x = 0 :=
begin
  split,
  { intro h,
    have zero_root := polynomial.zero_is_root_of_coeff_zero_eq_zero h,
    rw ← minimal_polynomial.root hx zero_root,
    exact is_ring_hom.map_zero _ },
  { rintro rfl, simp }
end

protected lemma coeff_zero_ne_zero (h : x ≠ 0) : coeff (minimal_polynomial hx) 0 ≠ 0 :=
by { contrapose! h, simpa using h }

end field

end minimal_polynomial
