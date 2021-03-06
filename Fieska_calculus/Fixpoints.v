(**********************************************************************)
(* This program is free software; you can redistribute it and/or      *)
(* modify it under the terms of the GNU Lesser General Public License *)
(* as published by the Free Software Foundation; either version 2.1   *)
(* of the License, or (at your option) any later version.             *)
(*                                                                    *)
(* This program is distributed in the hope that it will be useful,    *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of     *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the      *)
(* GNU General Public License for more details.                       *)
(*                                                                    *)
(* You should have received a copy of the GNU Lesser General Public   *)
(* License along with this program; if not, write to the Free         *)
(* Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA *)
(* 02110-1301 USA                                                     *)
(**********************************************************************)

(**********************************************************************)
(*                       Fixpoints.v                                  *)
(*                                                                    *)
(*                        Barry Jay                                   *)
(*                                                                    *)
(**********************************************************************)


Require Import Arith Omega Max Bool List.
Require Import IntensionalLib.Fieska_calculus.Test.
Require Import IntensionalLib.Fieska_calculus.General.
Require Import IntensionalLib.Fieska_calculus.Fieska_Terms.
Require Import IntensionalLib.Fieska_calculus.Fieska_Tactics.
Require Import IntensionalLib.Fieska_calculus.Fieska_reduction.
Require Import IntensionalLib.Fieska_calculus.Fieska_Normal.
Require Import IntensionalLib.Fieska_calculus.Fieska_Closed.
Require Import IntensionalLib.Fieska_calculus.Substitution.
Require Import IntensionalLib.Fieska_calculus.Fieska_Eval.
Require Import IntensionalLib.Fieska_calculus.Star.

(* Fixpoints *) 

Fixpoint A_k k := 
match k with 
| 0 => a_op 
| 1 => a_op 
| 2 => a_op 
| S k1 => App a_op (App (App s_op (App k_op (App s_op (App k_op (A_k k1))))) a_op) 
end.

Lemma A_k_closed: forall k, maxvar (A_k k) = 0. 
Proof.
induction k; intros. split_all. 
induction k; intros. split_all. 
clear IHk0. induction k; intros. split_all. clear IHk0.
unfold A_k in *; fold A_k in *.  
repeat rewrite maxvar_app. simpl. rewrite IHk. auto. 
Qed. 

Lemma A_k_normal : forall k, normal (A_k k).
Proof.
induction k; split_all. 
unfold_op; auto. 
induction k; split_all. 
induction k; split_all. 
unfold a_op; auto. repeat eapply2 star_opt_normal. 
unfold_op; unfold a_op; repeat eapply2 nf_compound.
Qed. 

Lemma A_k_normal2 : forall k M, normal M -> normal (App (A_k k) M).
Proof.
induction k; split_all. 
unfold a_op; eapply2 nf_compound. 
assert(normal (App (App a_op
              (App (App s_op (App k_op (App s_op (App k_op (A_k k))))) a_op)) M)). 
unfold_op; repeat eapply2 nf_compound. 
eapply2 A_k_normal. 
gen_case H0 k. unfold a_op; eapply2 nf_compound. 
assert(n= 0 \/ n<> 0) by decide equality. 
inversion H1. subst; auto. unfold a_op; eapply2 nf_compound. 
replace n with (S (pred n)) in * by omega. auto. 
Qed. 

Hint Resolve A_k_closed A_k_normal A_k_normal2.




Ltac nf_out :=
  unfold a_op; unfold_op;
  match goal with
    | |- normal ?M =>
      match M with
        | star_opt _ => apply star_opt_normal; nf_out
        | A_k _ => apply A_k_normal; nf_out
        | App (App (Op _) _) _ => apply nf_compound; [| |auto]; nf_out
        | App (Op _) _ => apply nf_compound; [| |auto]; nf_out
        | _ => split_all
      end
    | _ => auto
        end.


(* fixpoints that wait *) 


Definition app_comb M N := App (App (Op Aop) M) N. 


(* Y2 *) 

Definition omega2 := 
star_opt(star_opt (App (Ref 0) (app_comb (app_comb (Ref 1) (Ref 1)) (Ref 0)))).

Definition Y2 f := app_comb (app_comb omega2 omega2) f.

Lemma Y2_program: forall f, program f -> program (Y2 f).
Proof.
  unfold Y2, omega2; split_all; unfold program; split; 
unfold subst, subst_rec; fold subst_rec; unfold app_comb; nf_out; try eapply2 H. 
Qed.

Lemma omega2_omega2 : 
forall f, sf_red (App (App omega2 omega2) f) (App f (Y2 f)).
Proof.
unfold omega2 at 1, app_comb. intros. 
eapply transitive_red. eapply2 star_opt_beta2. 
unfold subst, subst_rec; fold subst_rec. 
insert_Ref_out. unfold lift.  rewrite lift_rec_null.  
rewrite subst_rec_lift_rec; try omega.  
rewrite lift_rec_null. eapply2 preserves_app_sf_red. 
Qed. 

Lemma Y2_fix: forall M N, 
sf_red (App (Y2 M) N) (App (App M (Y2 M)) N).
Proof.
unfold Y2 at 1, app_comb.  intros.  eval_tac. eval_tac.  
eapply transitive_red. eapply preserves_app_sf_red. eapply2 omega2_omega2. auto. auto. 
Qed. 

(* Y3 *) 

Definition omega3 := 
star_opt(star_opt (star_opt (App (App (Ref 1) 
  (star_opt (app_comb (app_comb (app_comb (Ref 3) (Ref 3)) (Ref 2)) (Ref 0)))) 
                                    (Ref 0)))).

Definition Y3 f := star_opt (app_comb (app_comb (app_comb omega3 omega3) (lift 1 f)) (Ref 0)).

Lemma omega3_program: program omega3. 
Proof. 
split; auto. unfold omega3; nf_out.  eapply2 nf_active.  eapply2 nf_active. 
unfold subst, subst_rec; fold subst_rec; nf_out; try eapply2 H; cbv; auto. 
Qed.  


Lemma Y3_program: forall f, program f -> program (Y3 f).
Proof.
intros.  unfold Y3, app_comb; split; auto.  
nf_out; try eapply2 omega3_program.  
unfold lift; rewrite lift_rec_closed; eapply2 H. 
(* 1 *) 
rewrite maxvar_star_opt.  simpl. 
replace (maxvar (lift 1 f)) with 0. 
auto.  unfold lift; rewrite lift_rec_closed.  
assert(maxvar f = 0) by eapply2 H; auto. 
eapply2 H. 
Qed.

Lemma omega3_omega3 : 
forall f M, sf_red (App (App (App omega3 omega3) f) M) (App (App f (Y3 f)) M).
Proof.
unfold omega3 at 1, app_comb. intros. 
eapply transitive_red. eapply2 star_opt_beta3. 
unfold subst; rewrite ! subst_rec_app.  
rewrite ! subst_rec_preserves_star_opt.
repeat (rewrite ! subst_rec_ref; insert_Ref_out). 
repeat (unfold subst_rec; fold subst_rec; insert_Ref_out). 
unfold lift; rewrite ! lift_rec_lift_rec; try omega. unfold plus. 
rewrite ! subst_rec_lift_rec; try omega. rewrite ! lift_rec_null. 
rewrite ! (lift_rec_closed omega3).  
unfold Y3.  auto. 
unfold omega3; cbv; auto. 
Qed. 



Lemma Y3_fix: forall M N P, 
sf_red (App (App (Y3 M) N) P) (App (App (App M (Y3 M)) N) P).
Proof.
unfold Y3 at 1, app_comb.  intros. 
eapply transitive_red. eapply preserves_app_sf_red. eapply star_opt_beta. auto. 
unfold subst, subst_rec; fold subst_rec. 
rewrite ! (subst_rec_closed omega3). 
2: unfold omega3; cbv; omega. 
unfold lift; rewrite subst_rec_lift_rec; try omega. 
unfold subst_rec; fold subst_rec. insert_Ref_out. unfold lift. 
rewrite ! lift_rec_null. eval_tac. eval_tac. eval_tac. 
eapply transitive_red. eapply preserves_app_sf_red. eapply2 omega3_omega3. auto. auto. 
Qed. 


(* fixpoints that wait *) 


Definition omega_k k := 
star_opt(star_opt (App (Ref 0) 
  (App (App (Op Aop) (App (A_k k) (App (App (Op Aop) (Ref 1)) (Ref 1)))) (Ref 0)))). 


Definition Y_k k := App (A_k k) (App (App (Op Aop) (omega_k k)) (omega_k k)). 

Lemma omega_k_normal: forall k, normal (omega_k k).
Proof.  
intros; unfold omega_k. nf_out. eapply2 nf_active. nf_out. 
Qed. 

Lemma omega_k_closed: forall k, maxvar (omega_k k) = 0.
Proof.  intros; unfold omega_k. rewrite ! maxvar_star_opt. rewrite ! maxvar_app. 
rewrite A_k_closed. auto. Qed. 


Hint Resolve A_k_closed A_k_normal omega_k_normal omega_k_closed. 


Lemma omega_omega : 
forall k M, sf_red (App (App (omega_k k) (omega_k k)) M) (App M (App (App (Op Aop) (Y_k k)) M)).
Proof.
unfold omega_k at 1. intros. 
eapply transitive_red. eapply2 star_opt_beta2. 
unfold subst, subst_rec; fold subst_rec. 
insert_Ref_out. unfold lift. rewrite lift_rec_null.  rewrite subst_rec_lift_rec; try omega.  
rewrite lift_rec_null. eapply2 preserves_app_sf_red. 
repeat rewrite (subst_rec_closed (A_k k)); try (rewrite A_k_closed; omega). 
unfold subst_rec; fold subst_rec. insert_Ref_out. unfold lift. 
repeat rewrite lift_rec_null.  
auto. 
Qed. 

Lemma Y_k_program: forall k, program (Y_k k).
Proof.
  unfold Y_k; split_all; nf_out.   
  (* 2 *) 
  case k; split_all. unfold a_op;   nf_out. split; auto. 
 case n; intros; nf_out. split; nf_out. 
 case n0; intros; split; nf_out. 
(* 1 *)
  rewrite!  maxvar_app. rewrite A_k_closed. rewrite omega_k_closed. auto. 
Qed.

Lemma Y_k_normal: forall k, normal (Y_k k). Proof. eapply2 Y_k_program. Qed. 
Lemma Y_k_closed: forall k, maxvar (Y_k k) = 0. Proof. eapply2 Y_k_program. Qed. 


Lemma Y4_fix: forall M N P Q, 
sf_red (App (App (App (App (Y_k 4) M) N) P) Q) (App (App (App (App M (App (App (Op Aop) (Y_k 4)) M)) N) P) Q).
Proof.
unfold Y_k at 1, A_k. intros; unfold_op. eval_tac. eval_tac.  eval_tac. eval_tac. 
 eval_tac. eval_tac. eval_tac. eval_tac.  eval_tac. eval_tac. 
eapply transitive_red. eapply preserves_app_sf_red. eapply preserves_app_sf_red. 
eapply preserves_app_sf_red. eapply2 omega_omega. auto. auto. auto. auto. 
Qed. 

Lemma Y5_fix: forall M N P Q R, 
sf_red (App (App (App (App (App (Y_k 5) M) N) P) Q) R) 
       (App (App (App (App (App M (App (App (Op Aop) (Y_k 5)) M)) N) P) Q) R).
Proof.
unfold Y_k at 1, A_k. intros; unfold_op. eval_tac. eval_tac.  eval_tac. eval_tac. 
 eval_tac. eval_tac. eval_tac. eval_tac.  eval_tac. eval_tac.  eval_tac.  eval_tac. 
eval_tac.   eval_tac. 
eapply transitive_red. eapply preserves_app_sf_red. eapply preserves_app_sf_red. 
eapply preserves_app_sf_red. eapply preserves_app_sf_red. eapply2 omega_omega. auto. auto. 
auto. auto. auto. 
Qed. 

Lemma Y6_fix: forall M N P Q R T, 
sf_red (App (App (App (App (App (App (Y_k 6) M) N) P) Q) R) T)
       (App (App (App (App (App (App M (App (App (Op Aop) (Y_k 6)) M)) N) P) Q) R) T).
Proof.
unfold Y_k at 1, A_k. intros; unfold_op. eval_tac. eval_tac.  eval_tac. eval_tac. 
 eval_tac. eval_tac. eval_tac. eval_tac.  eval_tac. eval_tac.  eval_tac. eval_tac. 
 eval_tac. eval_tac. eval_tac. eval_tac. eval_tac. 
eapply transitive_red. eapply preserves_app_sf_red. eapply preserves_app_sf_red. eval_tac. 
auto. auto. 
eapply transitive_red. eapply preserves_app_sf_red. eapply preserves_app_sf_red. 
eapply preserves_app_sf_red. eapply preserves_app_sf_red. eapply preserves_app_sf_red. 
eapply2 omega_omega. auto. auto. auto. auto. auto. auto. 
Qed. 


