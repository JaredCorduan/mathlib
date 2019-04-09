import algebraic_geometry.stalks
import category_theory.limits.types

universes v u

open category_theory
open category_theory.limits
open algebraic_geometry.PresheafedSpace

namespace algebraic_geometry

structure PreorderPresheaf extends PresheafedSpace.{v} (Type v) :=
(preorder : Π x : X, preorder (to_PresheafedSpace.stalk x))

instance (F : PreorderPresheaf.{v}) (x : F.X) : preorder (F.to_PresheafedSpace.stalk x) :=
F.preorder x

namespace PreorderPresheaf

structure hom (F G : PreorderPresheaf.{v}) :=
(hom : F.to_PresheafedSpace ⟶ G.to_PresheafedSpace)
(monotone : Π (x : F.X) (a b : G.to_PresheafedSpace.stalk (PresheafedSpace.hom.f hom x)),
   (a ≤ b) ↔ ((stalk_map hom x) a ≤ (stalk_map hom x) b))

@[extensionality] lemma hom.ext
  (F G : PreorderPresheaf.{v}) {f g : hom F G}
  (w : f.hom = g.hom) : f = g :=
begin
  cases f, cases g,
  congr; assumption
end

def id (F : PreorderPresheaf.{v}) : hom F F :=
{ hom := 𝟙 F.to_PresheafedSpace,
  monotone := λ x a b, by simp  }

def comp (F G H : PreorderPresheaf.{v}) (α : hom F G) (β : hom G H) : hom F H :=
{ hom := α.hom ≫ β.hom,
  monotone := λ x a b,
  begin
    simp,
    transitivity,
    apply β.monotone,
    apply α.monotone,
  end  }

section
local attribute [simp] id comp
instance : category PreorderPresheaf.{v} :=
{ hom := hom,
  id := id,
  comp := comp,
  comp_id' := λ X Y f, begin ext1, dsimp, simp, end,
  id_comp' := λ X Y f, begin ext1, dsimp, simp, end,
  assoc' := λ W X Y Z f g h, begin ext1, dsimp, simp, end }
end
-- TODO should `dsimp` and `simp` come before `ext` in `tidy`?

end PreorderPresheaf

end algebraic_geometry
