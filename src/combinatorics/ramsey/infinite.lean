/-
Copyright (c) 2019 Jared Corduan. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Jared Corduan.
-/

import algebra.order_functions
import logic.basic logic.function
import data.set.finite data.finset
open fin

/-!
# The Infinite Ramsey Theorem

The main theorem, `infinite_ramsey_pairs_two_colors`, states that given
a function from the unordered pairs of natural numbers to a set
with two elements (often named `red` and `blue`), there exists an
infinite set of natural numbers whose unordered pairs are all given
the same color.

The proof given here follows a very standard proof, such as the one
given in chapter 1, theorem 5, of Graham, et al.

The proof roughly goes as follows:

Given a function `f` of unordered pairs into the colors `red` and `blue`,
define a sequence `(Sᵢ, xᵢ)` so that:

* (S₀, x₀) = (ℕ, 0)
* Sᵢ₊₁ ⊆ Sᵢ
* xᵢ₊₁ ∈ Sᵢ
* xᵢ < xᵢ₊₁
* f {xᵢ₊₁, y} = f {xᵢ₊₁, z} for all xᵢ₊₁ < y < z in Sₓ, x = xᵢ

Then the set {xᵢ | i ∈ ℕ} has the property that
f {xᵢ, xⱼ} = f {xᵢ, xₖ} for all i < j < k.
If we color singletons in this set by f' xᵢ = f {xᵢ, xᵢ₊₁},
then by the pigeon hole principle there is an infinite subset
of the xᵢ's whose unordered pairs are all colored the same.

## Notation

This file uses `[S]²` to denote the set of unordered pairs of
the given set `S`.

## Implementation notes

The set of two colors is defined as an emumeration.
This definition is easy to work with, and easy to read,
but comes at the cost of not generalizing.

Unordered pairs are implemented as ordered pairs with the condition
that the second element is strictly greater than the first.
This definition is also easy to work with but does not generalize.

## References

*  [Graham, R.L. and Rothschild, B.L. and Spencer, J.H., *Ramsey Theory*][graham1990]
-/

open set
open classical
open nat

namespace infinite_ramsey_pairs

/--
A set of natural numbers H is infinite if for any natural
number there is a larger number in H.
-/
lemma infinite_unbounded (H : set ℕ) :
  set.infinite H ↔ ∀ x : ℕ, ∃ y : ℕ, x < y ∧ y ∈ H :=
begin
  constructor,
  { intros h x, classical, by_contra H_contra, push_neg at H_contra,
    apply h, refine finite_subset (finite_le_nat x) (λ _ _, by finish) },
  { intros h hf, let x := hf.to_finset.sup id,
    rcases h x with ⟨y,⟨Hy₁,Hy₂⟩⟩,
    have : y ≤ x := finset.le_sup (by simp* : y ∈ hf.to_finset),
    exact nat.lt_le_antisymm ‹_› ‹_› }
end

/-
There are two colors, red and blue.
-/
@[derive decidable_eq]
inductive color
| red : color
| blue : color

open color

/--
An infinite set of natural numbers.
-/
structure Inf :=
(s : set ℕ)
(pf : set.infinite s)

instance Inf.has_coe : has_coe Inf (set ℕ) := ⟨Inf.s⟩
instance : has_mem ℕ Inf := ⟨λ n H, n ∈ H.s⟩
instance : has_subset Inf := ⟨λ H₁ H₂, H₁.s ⊆ H₂.s⟩

/--
Given a function from natural numbers to colors,
this property describes the numbers which are mapped to red.
-/
def is_red (f : ℕ → color) := {n : ℕ | f n = red}

/--
Given a function from natural numbers to colors,
this property describes the numbers which are mapped to blues.
-/
def is_blue (f : ℕ → color) := (λ n : ℕ, f n = blue)

lemma lt_succ_sum (x y : ℕ) : x < x + y + 1 :=
  lt_add_of_pos_right x (succ_pos y)

/--
Unordered pairs are defined as ordered pairs with the condition
that the second element is strictly greater than the first.
-/
def unordered_pairs (S : set ℕ) :=
  {p : ℕ × ℕ // p.fst < p.snd ∧ p.fst ∈ S ∧ p.snd ∈ S}

local notation `[ℕ]²` := unordered_pairs univ
local notation `[` S `]²` := unordered_pairs S

/--
Given a number m and a coloring f, the projection of a coloring
of unordered_pairs to a coloring of numbers is given by fixing
the first element as m. Note that red is arbitrarily chosen
as the color assigned to any number below m.
-/
def project (f : [ℕ]² → color) (m : ℕ) : ℕ → color :=
  λ n : ℕ,
    if h : m < n
      then f ⟨(m, n), ⟨h, trivial, trivial⟩⟩
      else red

/--
The coloring of an unordered pair {a, b}, where a < b,
agrees with the projection of a applied to b.
-/
@[simp] lemma project_eq (f : [ℕ]² → color) (p : [ℕ]²):
  project f p.val.fst p.val.snd = f p :=
begin
  unfold project,
  simp [p.property.left]
end

/--
Given coloring of natural numbers, a homogeneous set is
one which is always mapped to the same color.
-/
def homogeneous (f : ℕ → color) (H : set ℕ) :=
  ∃ c : color, ∀ n, n ∈ H → f n = c

/--
Given a coloring f, a homogeneous projection is a set of natural numbers
together with a single natural number.
The intended use is a set which is homogeneous when projected
with the given number and coloring.
-/
structure homogeneous_proj (f : [ℕ]² → color) extends Inf := (pt : ℕ)

instance homogeneous_proj.has_coe (f : [ℕ]² → color) :
  has_coe (homogeneous_proj f) Inf := ⟨λ c, c.to_Inf⟩

/--
A homogeneous projection p is refined by another homogeneous projection q if:
the number given by q is greater than the number given by p,
the number given by q is an elment of the set given by p,
the set given by q is contained in the set given by p,
and the projection using the number given by q is homogeneous
on the set given by q.
-/
def refines {f : [ℕ]² → color} (p q: homogeneous_proj f) :=
p.pt < q.pt ∧ q.pt ∈ p.s ∧ q.s ⊆ p.s ∧ homogeneous (project f q.pt) q

instance (f : [ℕ]² → color) : has_lt (homogeneous_proj f) :=
  ⟨λp q : homogeneous_proj f, refines p q⟩

structure cardinality_two (α : Type) :=
  (s : finset α)
  (h : s.card = 2)

lemma equiv_card_2 : unordered_pairs univ ≃ cardinality_two ℕ :=
{ to_fun := λ p, ⟨{p.val.1, p.val.2},
    begin
      simp,
      have hlt : p.val.fst < p.val.snd, apply p.property.left,
      have h : p.val.snd ∉ finset.singleton p.val.fst,
      simp, intro hne,
      rw hne at hlt, apply lt_irrefl (p.val.fst) hlt,
      simp * at *,
    end⟩,
  inv_fun := sorry,
  left_inv := sorry,
  right_inv := sorry,
}

/-
Intuitively, split_coloring reduces a (k+1)-coloring
to a 2-coloring by coloring k "red" and everything else "blue".
This is the key trick for the inductive argument that
extends Ramsey's theorem for two colors to k colors.
-/
def split_coloring
  {α : Type}
  {k : ℕ}
  (f : α → fin (succ k))
  (p : α)
  : color := if (f p = k) then red else blue

lemma red_split {k : ℕ} {α : Type} (f : α → fin (succ k)) (p : α)
  (h : split_coloring f p = red) : f p = k :=
begin
  unfold split_coloring at h,
  sorry
end

lemma blue_split {k : ℕ} {α : Type} (f : α → fin (succ k)) (p : α)
  (h : split_coloring f p = blue) : f p < k :=
begin
  unfold split_coloring at h,
  cases f p with fp hfp,
  sorry,
end


local attribute [instance] prop_decidable

/-
A version of the infinite pigeon hole principle, tailored to our use case.
-/
lemma pigeon_hole_principle (f : ℕ → color) (H : Inf):
  set.infinite (is_red f ∩ H) ∨ set.infinite (is_blue f ∩ H) :=
begin -- The proof is essentiall "a finite union of finite sets is finite"
  unfold set.infinite, rw ←not_and_distrib,
  intro c,
  have hf : finite ((is_red f ∩ H) ∪ (is_blue f ∩ H)),
    apply finite_union c.left c.right,
    rw ←inter_distrib_right at hf,
  have hrb : ∀ x, f x = red ∨ f x = blue,
    intro x, cases f x, left, refl, right, refl,
  have he : (is_red f ∪ is_blue f) ∩ H = H, rw ext_iff,
    intro x, constructor,
      { intro h, apply h.right },
      { intro h, constructor, apply hrb, apply h },
  rw he at hf,
  exact H.pf hf,
end

/-
This is the key lemma, reducing the Ramsey Theorem for pairs
to the pigeon hole principle. It shows how to refine one homogeneous
projection to get another homogeneous projection.
-/
lemma refine_homo_proj (f : [ℕ]² → color) :
  ∀ (p : homogeneous_proj f), ∃ q : homogeneous_proj f, p < q :=
begin
  intros p,
  have Hp : ∀ x : ℕ, ∃ y : ℕ, x < y ∧ y ∈ p.s,
    exact (infinite_unbounded p.s).elim_left p.pf,
  cases Hp p.pt with x Hx,
  have Hinf :
    set.infinite (is_red (project f x) ∩ p.s) ∨ set.infinite (is_blue (project f x) ∩ p.s),
    apply pigeon_hole_principle,
  cases Hinf,
  any_goals
  -- Red Case
  { apply exists.intro (homogeneous_proj.mk f ⟨is_red (project f x) ∩ p.s, Hinf⟩ x) },
  -- Blue Case
  any_goals
  { apply exists.intro (homogeneous_proj.mk f ⟨is_blue (project f x) ∩ p.s, Hinf⟩ x) },
  all_goals
  { constructor,
    { exact Hx.left },
    constructor,
    { exact Hx.right },
    constructor,
    { intros n Hn, exact Hn.right },
    { apply exists.intro, intros n Hn, exact Hn.left } }
end

/--
The natural numbers, as an infinite set.
-/
def NatInf : Inf := Inf.mk univ
begin
  rw infinite_unbounded,
  intro x, apply exists.intro (x+1),
  constructor, exact lt_succ_sum x 0, trivial,
end

/-
The initial set and number used to define
all the homogeneous projections.
-/
def init (f : [ℕ]² → color) : homogeneous_proj f := ⟨f, NatInf, 0⟩

/-
Iterate the procedure of refining a homogeneous projection.
-/
def iterate_refinement (f : [ℕ]² → color)
    (cf : Π (x : homogeneous_proj f), (λ (x : homogeneous_proj f), homogeneous_proj f) x) :
  ℕ → homogeneous_proj f
| 0 := cf (init f)
| (n+1) := let p := iterate_refinement n in cf ⟨f, p, p.pt⟩

/--
There exists an infinite sequence of homogeneous projections,
each a refinement of the previous one.
-/
lemma exists_homo_proj_seq (f : [ℕ]² → color) :
∃ (g : ℕ → homogeneous_proj f), init f < g 0 ∧ ∀ n, g n < g (n+1) :=
begin
  have ac : ∃ (cf : Π (x : homogeneous_proj f), (λ (x : homogeneous_proj f), homogeneous_proj f) x),
    ∀ (p : homogeneous_proj f), (λ (p q : homogeneous_proj f), p<q) p (cf p),
    exact axiom_of_choice (refine_homo_proj f),
  cases ac with cf Hcf,
  let g := λ m : ℕ, (iterate_refinement f cf m),
  apply exists.intro g,
  constructor,
  { exact Hcf (init f) },
  { intro n,
    have h1 : (g n) < cf (g n),
      exact Hcf (g n),
    have h2 : ∀ p : homogeneous_proj f, p = ⟨f, ↑p, p.pt⟩,
      intro p, cases p with H n, cases H with s pf, refl,
    have h3 : cf (g n) = iterate_refinement f cf (n+1),
      unfold iterate_refinement, simp, rw ← (h2 (g n)),
    simp * at * }
end

/--
The sets in a sequence of refined homogeneous projections are
closed upward under inclusion.
-/
lemma homo_proj_seq_mono_sets
  (f : [ℕ]² → color)
  (g : ℕ → homogeneous_proj f)
  (h : ∀ n, g n < g (n+1))
  (x y : ℕ) :
  (g (x+y)).s ⊆ (g x).s :=
begin
  induction y with y ih,
  { intros y hy, exact hy },
  { intros a ha,
    exact ih ((h (x+y)).right.right.left ha) }
end

/--
The points in a sequence of refined homogeneous projections are
contained in the previous sets.
-/
lemma homo_proj_seq_mono_pts
  (f : [ℕ]² → color)
  (g : ℕ → homogeneous_proj f)
  (h : ∀ n, g n < g (n+1))
  (x y : ℕ) :
  (g (x+y+1)).pt ∈ (g x).s :=
(homo_proj_seq_mono_sets f g h x y) ((h (x+y)).right.left)

/--
The points in a sequence of refined homogeneous projections have
the property that f {xᵢ, y} = f {xᵢ, z} for all xᵢ < y < z in Sₓ, x = xᵢ.
-/
lemma homo_proj_seq_stable_colors
  (f : [ℕ]² → color)
  (g : ℕ → homogeneous_proj f)
  (h0 : (init f) < g 0)
  (hn : ∀ n, g n < g (n+1))
  (x y : ℕ) :
  (project f (g x).pt) (g (x+1)).pt = (project f (g x).pt) (g (x+y+1)).pt :=
begin
  cases x,
  { have h : homogeneous (project f (g 0).pt) (g 0),
      exact h0.right.right.right,
    cases h with c hm,
    simp,
    rw hm ((g 1).pt) (homo_proj_seq_mono_pts f g hn 0 0),
    have hzy : y + 1 = 0 + y + 1, simp,
    rw hzy,
    rw hm ((g (0+y+1)).pt) (homo_proj_seq_mono_pts f g hn 0 y) },
  { have hgx : g x < g (x+1), exact (hn x),
    have hm : homogeneous (project f (g (x+1)).pt) (g (x+1)),
      exact hgx.right.right.right,
    cases hm with c Hm',
    rw Hm' ((g (x + 1 + 1)).pt) (homo_proj_seq_mono_pts f g hn (x+1) 0),
    rw Hm' ((g (x + 1 + y + 1)).pt) (homo_proj_seq_mono_pts f g hn (x+1) y) }
end

section increasing_functions

lemma increasing_by_step (f : ℕ → ℕ) :
  (∀ n : ℕ, f n < f (n+1)) → strict_mono f :=
    λ (hf : ∀ n : ℕ, f n < f (n+1)) (x y : ℕ), nat.rec_on y
    (λ (contr : x < 0), absurd contr (not_succ_le_zero x))
    (λ (z : ℕ) (ih : x < z → f x < f z) (h : x < succ z),
      or.cases_on (nat.eq_or_lt_of_le (le_of_lt_succ h))
      (λ hxz : x = z, hxz ▸ (hf x))
      (λ (hxz : x < z), lt_trans (ih hxz) (hf z)))

lemma x_le_fx_incr (f : ℕ → ℕ) (x : ℕ): strict_mono f → x ≤ f x :=
λ (incr : strict_mono f),
  nat.rec_on x (nat.zero_le (f 0))
  (λ (n : ℕ) (ih : n ≤ f n),
  le_trans (succ_le_succ ih) (incr n (succ n) (lt_succ_self n)))

lemma incr_range_inf (H : Inf) (g : ℕ → ℕ) (hg : strict_mono g) :
  set.infinite (image g H) :=
begin
  rw infinite_unbounded,
  intros x,
  have hu : ∀ x : ℕ, ∃ y : ℕ, x < y ∧ y ∈ H,
    exact (infinite_unbounded H.s).elim_left H.pf,
  have h : ∃ h, x < h ∧ h ∈ H, exact hu x,
  cases h with h Hh,
  apply exists.intro (g h),
  constructor,
  exact (lt_of_lt_of_le Hh.left (x_le_fx_incr g h hg)),
  unfold image,
  apply exists.intro h, constructor, exact Hh.right, refl,
end

end increasing_functions

/-
Trivial lemma needed below.
-/
lemma domain_dist_rw (x y : ℕ) (h : x < y): y = x + (y - (x+1)) + 1 :=
by rw [ add_assoc x (y - (x+1)) 1
      , add_comm (y - (x+1)) 1
      , ←add_assoc x 1 (y - (x+1))
      , add_sub_of_le (succ_le_of_lt h)]

/--
The points in a sequence of refined homogeneous projections
are increasing.
-/
lemma homo_proj_seq_incr
(f : [ℕ]² → color)
(g : ℕ → homogeneous_proj f)
(h : ∀ n, g n < g (n+1)) :
strict_mono (λ n : ℕ, (g n).pt) :=
begin
  have h : ∀ n : ℕ, (g n).pt < (g (n+1)).pt,
  intro, exact (h n).left,
  exact increasing_by_step (λ n : ℕ, (g n).pt) h,
end

/--
Restrict a coloring of unordered pairs of all natural numbers
to unordered pairs of a given infinite set H.
-/
def restrict {α : Type }(f : [ℕ]² → α) (H : set ℕ) : [H]² → α :=
  λ h, f (⟨h.val, ⟨h.property.left, ⟨true.intro, true.intro⟩⟩⟩)

/--
Given a function from the unordered pairs of natural numbers to a set
with two elements, there exists an infinite set of
natural numbers whose unordered pairs are all given the same color.
-/
theorem infinite_ramsey_pairs_two_colors (f : [ℕ]² → color) :
  ∃ H : Inf, ∃ c : color,
  ∀ h : [H]²,
  (restrict f H) h = c :=
begin
  have hseq : ∃ (g : ℕ → homogeneous_proj f), init f < g 0 ∧ ∀ n, g n < g (n+1),
    exact exists_homo_proj_seq f,
  cases hseq with g Hg,
  cases Hg with HgInit HgSeq,
  let g' := (λ n, (g n).pt),
  let f' := (λ n, project f (g' n) (g' (n+1))),
  have HgIncr : strict_mono g', exact homo_proj_seq_incr f g HgSeq,
  let preH := (⟨image g' NatInf, incr_range_inf NatInf g' HgIncr⟩ : Inf),
  cases (pigeon_hole_principle f' preH) with Hred Hblue,

  any_goals
  -- Red Case
  { let H := (⟨is_red f' ∩ preH, Hred⟩ : Inf),
    apply exists.intro (⟨image g' H, incr_range_inf H g' HgIncr⟩ : Inf),
    apply exists.intro red },
  any_goals
  -- Blue Case
  { let H := (⟨is_blue f' ∩ preH, Hblue⟩ : Inf),
    apply exists.intro (⟨image g' H, incr_range_inf H g' HgIncr⟩ : Inf),
    apply exists.intro blue },
  all_goals
  { intros p,
    have hp1 : p.val.fst ∈ image g' H, exact p.property.right.left,
    cases hp1 with h₁ Hh₁,
    have hfh₁ : f' h₁ = _, exact Hh₁.left.left,
    have hfgh₁ : project f (g' h₁) (g' (h₁+1)) = _, rw ←hfh₁,
    have hp2 : p.val.snd ∈ image g' H, exact p.property.right.right,
    cases hp2 with h₂ Hgh₂,
    have hg : p.val.fst < p.val.snd, exact p.property.left,
    rw [←Hh₁.right, ←Hgh₂.right] at hg,
    let d := h₂ - (h₁ + 1),
    have hd : h₂ = h₁ + d + 1,
      exact domain_dist_rw h₁ h₂ ((strict_mono.lt_iff_lt HgIncr).elim_left hg),
    have stable :
      (project f (g' h₁)) (g' (h₁+1)) = (project f (g' h₁)) (g' (h₁+d+1)),
      exact homo_proj_seq_stable_colors f g HgInit HgSeq h₁ d,
    rw [hfgh₁, ←hd, Hh₁.right, Hgh₂.right] at stable,
    have hproj : f ⟨p.val, _⟩ = project f p.val.fst p.val.snd,
      simp [project_eq f ⟨p.val, ⟨p.property.left, trivial, trivial⟩⟩],
    rw [←stable, hproj] at hproj,
    rw ←hproj, refl }
end

/--
An equivalenc of color and fin 2
-/
lemma e : color ≃ fin 2 :=
{ to_fun := λ c, color.rec_on c 0 1,
  inv_fun := λ n, nat.rec_on n.val red (λ _ _, blue),
  left_inv := begin intro x, cases x, refl, refl end,
  right_inv :=
    begin
      intro x,
      cases x with x hx,
      cases x,
      { refl },
      { simp,
        cases x,
        { refl },
        { rw [fin.eq_iff_veq],
          simp [lt_succ_iff, succ_le_succ_iff, succ_pos ] at hx,
          simp, rw hx } },
    end }

theorem infinite_ramsey_pairs_two_colors' (f : [ℕ]² → fin 2) :
  ∃ H : Inf, ∃ k : fin 2,
  ∀ h : [H]²,
  (restrict f H) h = k :=
begin
  have h : ∃ H : Inf, ∃ c : color, ∀ h : [H]²,
    (restrict (e.inv_fun ∘ f) H) h = c,
    exact infinite_ramsey_pairs_two_colors (e.inv_fun ∘ f),
  cases h with H hH,
  cases hH with c hc,
  apply exists.intro H,
  apply exists.intro (e.to_fun c),
  intros p,
  have hp : (restrict (e.inv_fun ∘ f) H) p = c, exact hc p,
  unfold restrict at hp,
  have hc2 :
    e.to_fun ((e.inv_fun ∘ f)  ⟨p.val, _⟩ ) =
      e.to_fun (c), rw hp,
  simp at hc2,
  rw e.right_inv
    (f ⟨p.val, ⟨p.property.left, trivial, trivial⟩⟩) at hc2,
  exact hc2,
end

theorem infinite_ramsey_pairs_n_colors (k : ℕ) (f : [ℕ]² → fin (k+2)) :
  ∃ H : Inf, ∃ c : fin (k+2),
  ∀ h : [H]²,
  (restrict f H) h = c :=
begin
  induction k with k IH,
  simp [infinite_ramsey_pairs_two_colors' f],
  have rt22 : ∃ H : Inf, ∃ c : color, ∀ h : [H]²,
    (restrict (split_coloring f) H) h = c,
  exact infinite_ramsey_pairs_two_colors (split_coloring f),
  cases rt22 with S hS,
  cases hS with c hRT,
  cases c,

  /-
  From here, the proof informally is:
  If c is red, then f restricted to S is always equal to k+1,
    and so S satisfies the conclusion of the theorem.
  Otherwise, if c is blue, f restricted to S is contained in fin (k+2),
    and we can use the induction hypothesis.
  -/

  -- red case
  have hRT' : ∀ (h : [S]²), restrict f S h = ↑(succ k+1),
    unfold restrict at hRT,
    intros s,
    apply red_split (restrict f S) s (hRT s),
  apply exists.intro S,
  have h' : k + 2 < succ k + 2, sorry,
  apply exists.intro (fin.mk (k+2) h'),
  intros s, simp [hRT'], rw eq_iff_veq, simp, sorry,

-- blue case
  have hRT' : ∀ (h : [S]²), restrict f S h < succ k+1,
  unfold restrict at hRT,
  intros s,
  apply blue_split (restrict f S) s (hRT s),
  apply exists.intro S,
  -- we now need an injection g of ℕ into S,
  -- then show that f ∘ g maps ℕ into fin (k+2) using hRT'.
  -- apply IH to (f ∘ g) to get inf H
  -- then g(H) is our monochrome set
  sorry,
end

end infinite_ramsey_pairs