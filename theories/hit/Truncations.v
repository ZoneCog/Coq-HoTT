(* -*- mode: coq; mode: visual-line -*- *)

(** * Truncations of types, in all dimensions. *)

Require Import HoTT.Basics Types.Sigma ReflectiveSubuniverse Modality TruncType HProp.
Local Open Scope path_scope.
Local Open Scope equiv_scope.
Generalizable Variables A X n.

(** ** Definition. *)

(** The definition of [Trunc n], the n-truncation of a type.

If Coq supported higher inductive types natively, we would construct this as somthing like:

   Inductive Trunc n (A : Type) : Type :=
   | tr : A -> Trunc n A
   | istrunc_truncation : forall (f : Sphere n.+1 -> Trunc n A)
       (x : Sphere n.+1), f x = f North.

However, while we are faking our higher-inductives anyway, we can take some shortcuts, rather than translating the definition above.  Firstly, we directly posit a “constructor” giving truncatedness, rather than rephrasing it in terms of maps of spheres.  Secondly, we omit the “computation rule” for this constructor, since it is implied by truncatedness of the result type (and, for essentially that reason, is never wanted in practice anyway).
*)

Module Export Trunc.
Delimit Scope trunc_scope with trunc.

Private Inductive Trunc (n : trunc_index) (A :Type) : Type :=
  tr : A -> Trunc n A.
Bind Scope trunc_scope with Trunc.
Arguments tr {n A} a.

(** Without explicit universe parameters, this instance is insufficiently polymorphic. *)
Global Instance istrunc_truncation (n : trunc_index) (A : Type@{i})
: IsTrunc@{j} n (Trunc@{i} n A).
Admitted.

Definition Trunc_ind {n A}
  (P : Trunc n A -> Type) {Pt : forall aa, IsTrunc n (P aa)}
  : (forall a, P (tr a)) -> (forall aa, P aa)
:= (fun f aa => match aa with tr a => fun _ => f a end Pt).

End Trunc.

(** The non-dependent version of the eliminator. *)

Definition Trunc_rec {n A X} `{IsTrunc n X}
  : (A -> X) -> (Trunc n A -> X)
:= Trunc_ind (fun _ => X).

(** [Trunc] is a modality *)

(** We will define a truncation modality to be parametrized by a [trunc_index].  However, as described in Modality.v, we don't want to simply define [Truncation_Modalities.Modality] to *be* [trunc_index]; we want to think of the truncation modality as being *derived from* rather than *identical to* its truncation index.  In particular, there is a coercion [O_reflector] from [Modality] to [Funclass], but we don't want Coq to print things like [2 X] to mean [Trunc 2 X].  However, in the special case of truncation, it is nevertheless convenient for [Truncation_Modalities.Modality] to be definitionally equal to [trunc_index], so that we can modality functions (particularly connectedness functions) passing a truncation index directly.

These may seem like contradictory requirements, but it appears to be possible to satisfy them because coercions don't unfold definitions.  Thus, rather than a record wrapper, we define a *definitional* wrapper [Truncation_Modality] around [trunc_index], and a notation [Tr] for the identity.  We will define [Truncation_Modalities.Modality] to be [Truncation_Modality] and declare the identity as a coercion; thus a [Truncation_Modality] can be used as a modality and therefore also as a function (via the [O_reflector] coercion).  However, the identity from [trunc_index] to [Truncation_Modality] is not a coercion, so we don't get notation like [2 X]. *)
Definition Truncation_Modality := trunc_index.
Definition Tr : trunc_index -> Truncation_Modality := idmap.

Module Truncation_Modalities <: Modalities.

  Definition Modality : Type2@{u a} := Truncation_Modality.

  Definition O_reflector (n : Modality@{u u'}) A := Trunc n A.

  Definition inO_internal (n : Modality@{u u'}) A := IsTrunc n A.

  Definition O_inO_internal (n : Modality@{u u'}) A : inO_internal n (O_reflector n A).
  Proof.
    unfold inO_internal, O_reflector; exact _.
  Defined.

  Definition to (n : Modality@{u u'}) A := @tr n A.

  Definition inO_equiv_inO_internal (n : Modality@{u u'})
             (A B : Type@{i}) Atr f feq
  := @trunc_equiv A B f n Atr feq.

  Definition hprop_inO_internal `{Funext} (n : Modality@{u u'}) A
  : IsHProp (inO_internal n A).
  Proof.
    unfold inO_internal; exact _.
  Defined.

  Definition O_ind_internal (n : Modality@{u u'}) A B Btr f
    := @Trunc_ind n A B Btr f.

  Definition O_ind_beta_internal (n : Modality@{u u'})
             A B Btr f a
  : O_ind_internal n A B Btr f (to n A a) = f a
    := 1.

  Definition minO_paths (n : Modality@{u a})
             (A : Type@{i}) (Atr : inO_internal@{u a i} n A) (a a' : A)
  : inO_internal@{u a i} n (a = a').
  Proof.
    unfold inO_internal in *; exact _.
  Defined.

End Truncation_Modalities.

(** If you import the following module [TrM], then you can call all the modality functions with a [trunc_index] as the modality parameter, since we defined [Truncation_Modalities.Modality] to be [trunc_index]. *)
Module Import TrM := Modalities_Theory Truncation_Modalities.
(** If you don't import it, then you'll need to write [TrM.function_name] or [TrM.RSU.function_name] depending on whether [function_name] pertains only to modalities or also to reflective subuniverses.  (Having to know this is a bit unfortunate, but apparently the fact that [TrM] [Export]s reflective subuniverses still doesn't make the fields of the latter accessible as [TrM.field].) *)
Export TrM.Coercions.
Export TrM.RSU.Coercions.

(** Here is the additional coercion promised above. *)
Coercion Truncation_Modality_to_Modality := idmap : Truncation_Modality -> Modality.

Section TruncationModality.
  Context (n : trunc_index).

  Definition trunc_iff_isequiv_truncation (A : Type)
  : IsTrunc n A <-> IsEquiv (@tr n A)
  := inO_iff_isequiv_to_O n A.

  Global Instance isequiv_tr A `{IsTrunc n A} : IsEquiv (@tr n A)
  := fst (trunc_iff_isequiv_truncation A) _.

  Definition equiv_tr (A : Type) `{IsTrunc n A}
  : A <~> Tr n A
  := BuildEquiv _ _ (@tr n A) _.

  Definition untrunc_istrunc {A : Type} `{IsTrunc n A}
  : Tr n A -> A
  := (@tr n A)^-1.

  (** ** Functoriality *)

  Definition Trunc_functor {X Y : Type} (f : X -> Y)
  : Tr n X -> Tr n Y
  := O_functor n f.

  Definition Trunc_functor_compose {X Y Z} (f : X -> Y) (g : Y -> Z)
  : Trunc_functor (g o f) == Trunc_functor g o Trunc_functor f
  := O_functor_compose n f g.

  Definition Trunc_functor_idmap (X : Type)
  : @Trunc_functor X X idmap == idmap
  := O_functor_idmap n X.

  Definition isequiv_Trunc_functor {X Y} (f : X -> Y) `{IsEquiv _ _ f}
  : IsEquiv (Trunc_functor f)
  := isequiv_O_functor n f.

  Definition equiv_Trunc_prod_cmp `{Funext} {X Y}
  : Tr n (X * Y) <~> Tr n X * Tr n Y
  := equiv_O_prod_cmp n X Y.

End TruncationModality.

(** We have to teach Coq to translate back and forth between [IsTrunc n] and [In (Tr n)]. *)
Global Instance inO_tr_istrunc {n : trunc_index} (A : Type) `{IsTrunc n A}
: In (Tr n) A.
Proof.
  assumption.
Defined.

(** Having both of these as [Instance]s would cause infinite loops. *)
Definition istrunc_inO_tr {n : trunc_index} (A : Type) `{In (Tr n) A}
: IsTrunc n A.
Proof.
  assumption.
Defined.

(* Instead, we make the latter an immediate instance. *)
Hint Immediate istrunc_inO_tr : typeclass_instances.

(* Unfortunately, this isn't perfect; Coq still can't always find [In n] hypotheses in the context when it wants [IsTrunc]. *)


(** It's sometimes convenient to use "infinity" to refer to the identity modality in a similar way.  This clashes with some uses in higher topos theory, where "oo-truncated" means instead "hypercomplete", but this has not yet been a big problem. *)
Notation oo := purely.
(** TODO: Unfortunately, it doesn't quite work to have two copies of [Modalities_Theory] imported at the same time.  If we ever want to talk about truncation and include [oo], we may want to define a "union" instance of [Modality]. *)

(** ** A few special things about the (-1)-truncation. *)

Local Open Scope trunc_scope.

(** The following definition is doubly sneaky.  Firstly, we define [merely A] to be an inhabitant of the universe [hProp] of hprops, rather than a type.  We can always treat it as a type because there is a coercion, but this means that if we need an element of [hProp] then we don't need a separate name for it.  Secondly, rather than define it as [Trunc -1] we define it as [Tr -1], the action of the truncation modality.  These are of course judgmentally equal, but choosing the latter means that Coq has an easier time applying general modality theorems to it. *)

Definition merely (A : Type@{i}) : hProp@{i} := BuildhProp (Tr -1 A).

Definition hexists {X} (P : X -> Type) : hProp := merely (sigT P).

Definition hor (P Q : Type) : hProp := merely (P + Q).

Definition contr_inhab_prop {A} `{IsHProp A} (ma : merely A) : Contr A.
Proof.
  refine (@contr_trunc_conn -1 A _ _); try assumption.
  refine (contr_inhabited_hprop _ ma).
Defined.

(** Surjections are the (-1)-connected maps, but they can be characterized more simply since an inhabited hprop is automatically contractible. *)
Notation IsSurjection := (IsConnMap -1).

Definition BuildIsSurjection {A B} (f : A -> B) :
  (forall b, merely (hfiber f b)) -> IsSurjection f.
Proof.
  intros H b; refine (contr_inhabited_hprop _ _).
  apply H.
Defined.

Definition isequiv_surj_emb {A B} (f : A -> B)
           `{IsSurjection f} `{IsEmbedding f}
: IsEquiv f.
Proof.
  apply (@isequiv_conn_ino_map -1); assumption.
Defined.


(** ** Tactic to remove truncations in hypotheses if possible. *)
Ltac strip_truncations :=
  (** search for truncated hypotheses *)
  progress repeat match goal with
                    | [ T : _ |- _ ]
                      => revert T;
                        refine (@Trunc_ind _ _ _ _ _);
                        (** ensure that we didn't generate more than one subgoal, i.e. that the goal was appropriately truncated *)
                        [];
                        intro T
                  end.
