(* 
                         CS 51 Final Project
                         MiniML -- Evaluation
*)

(* This module implements a small untyped ML-like language under
   various operational semantics.
 *)

 open Expr ;;
  
 (* Exception for evaluator runtime, generated by a runtime error in
    the interpreter *)
 exception EvalError of string ;;
   
 (* Exception for evaluator runtime, generated by an explicit `raise`
    construct in the object language *)
 exception EvalException ;;
 
 (*......................................................................
   Environments and values 
  *)
 
 module type ENV = sig
     (* the type of environments *)
     type env
     (* the type of values stored in environments *)
     type value =
       | Val of expr
       | Closure of (expr * env)
    
     (* empty () -- Returns an empty environment *)
     val empty : unit -> env
 
     (* close expr env -- Returns a closure for `expr` and its `env` *)
     val close : expr -> env -> value
 
     (* lookup env varid -- Returns the value in the `env` for the
        `varid`, raising an `Eval_error` if not found *)
     val lookup : env -> varid -> value
 
     (* extend env varid loc -- Returns a new environment just like
        `env` except that it maps the variable `varid` to the `value`
        stored at `loc`. This allows later changing the value, an
        ability used in the evaluation of `letrec`. To make good on
        this, extending an environment needs to preserve the previous
        bindings in a physical, not just structural, way. *)
     val extend : env -> varid -> value ref -> env
 
     (* env_to_string env -- Returns a printable string representation
        of environment `env` *)
     val env_to_string : env -> string
                                  
     (* value_to_string ?printenvp value -- Returns a printable string
        representation of a value; the optional flag `printenvp`
        (default: `true`) determines whether to include the environment
        in the string representation when called on a closure *)
     val value_to_string : ?printenvp:bool -> value -> string
   end
 
 module Env : ENV =
   struct
     type env = (varid * value ref) list
      and value =
        | Val of expr
        | Closure of (expr * env)
 
     let empty () : env = [] ;;
 
     let close (exp : expr) (env : env) : value =
       let env_copy = List.map (fun (varid_val, value_ref) -> (varid_val, ref (!value_ref))) env in
       Closure (exp, env_copy) ;;
 
     let lookup (env : env) (varname : varid) : value =
       let result = List.filter (fun (this_id, _) -> varname = this_id ) env in
       if List.length result = 1 then
         let (_, value_found) = List.hd result in 
         !value_found
       else 
         Val Raise 
       ;;
 
 
     let rec env_to_string (env : env) : string =
       match env with 
       | [] -> ""
       | (varid, valueref) :: tl -> 
         match !valueref with 
         | Val content->
          varid^ " |-> "^ (Expr.exp_to_concrete_string content) ^ (env_to_string tl)
         | Closure (expr, inner_env) ->          
           varid^ " |-> "^ (Expr.exp_to_concrete_string expr) ^" in Environment: ("^
           (env_to_string inner_env)^ ")"^(env_to_string tl)
 
 
       ;;
 
       let extend (env : env) (varname : varid) (loc : value ref) : env =
         let result = List.filter (fun (this_id, _) -> varname = this_id ) env in
         if List.length result = 1 then (* just update the value if it already exists*)
           (*let other = List.filter (fun (this_id, _) -> varname != this_id ) env in  
           let new_env = (varname, loc) :: other in
           raise (EvalError ("What is the new environment? : "^env_to_string new_env))*)
           let (varid, valueref) = List.hd result in 
           valueref := !loc;
           match !valueref with 
           | Val _ ->  env 
           | Closure (func_body, func_env) ->
             let inner_result = List.filter (fun (this_id, _) -> varname = this_id ) func_env in
             if List.length inner_result = 1 then (* This only happens for recursive function*)
               let (inner_varid, inner_valueref) = List.hd inner_result in 
               inner_valueref := !loc;
               env 
             else 
               env
         else (* otherwise add a new entry *)
           (varname, loc) :: env 
       ;;  
   
 
          (* Give you the new value / closure with the updated value*)
       let update_rec_env (fun_name : varid) (closure_val: value) 
                                                           : value =
         match closure_val with 
           | Val _ -> raise(EvalError "illegal")
           | Closure (fun_val, fun_env) -> 
             let result = List.filter (fun (this_id, _) -> fun_name = this_id ) fun_env in
           if List.length result = 1 then
             let (_, value_found) = List.hd result in 
             !value_found
           else 
             Val Raise 
       
 ;;   
 
     let value_to_string ?(printenvp : bool = true) (v : value) : string =
     match v with 
     | Val exp -> Expr.exp_to_concrete_string exp 
     | Closure (exp, env) -> 
       if printenvp then 
         (Expr.exp_to_concrete_string exp)^ " where ["^ (env_to_string env)^"]"
       else 
         Expr.exp_to_concrete_string exp
     ;;
 
   end
 ;;
 
 
 (*......................................................................
   Evaluation functions
 
   Each of the evaluation functions below evaluates an expression `exp`
   in an enviornment `env` returning a result of type `value`. We've
   provided an initial implementation for a trivial evaluator, which
   just converts the expression unchanged to a `value` and returns it,
   along with "stub code" for three more evaluators: a substitution
   model evaluator and dynamic and lexical environment model versions.
 
   Each evaluator is of type `expr -> Env.env -> Env.value` for
   consistency, though some of the evaluators don't need an
   environment, and some will only return values that are "bare
   values" (that is, not closures). 
 
   DO NOT CHANGE THE TYPE SIGNATURES OF THESE FUNCTIONS. Compilation
   against our unit tests relies on their having these signatures. If
   you want to implement an extension whose evaluator has a different
   signature, implement it as `eval_e` below.  *)
 
 (* The TRIVIAL EVALUATOR, which leaves the expression to be evaluated
    essentially unchanged, just converted to a value for consistency
    with the signature of the evaluators. *)
    
 let eval_t (exp : expr) (_env : Env.env) : Env.value =
   (* coerce the expr, unchanged, into a value *)
   Env.Val exp ;;
   
 (* The SUBSTITUTION MODEL evaluator -- to be completed *)
    
 let binopeval (op : binop) (v1 : expr) (v2 : expr) : expr =
   match op, v1, v2 with
   | Plus, Num x1, Num x2 -> Num (x1 + x2)
   | Plus, _, _ -> raise (EvalError "can't add non-integers")
   | Minus, Num x1, Num x2 -> Num (x1 - x2)
   | Minus, _, _ -> raise (EvalError "can't subtract non-integers")
   | Times, Num x1, Num x2 -> Num (x1 * x2) 
   | Times, _, _ -> raise (EvalError "can't multiply non-integers")
   | Equals, Num x1, Num x2 -> Bool (x1 = x2)
   | Equals, _, _ -> raise (EvalError "can't divide non-integers")
   | LessThan, Num x1, Num x2 -> Bool (x1 < x2)
   | LessThan, _, _ -> raise (EvalError "can't divide non-integers") ;;
   
 let conditioncheck (exp : Env.value) : bool = 
   match exp with 
   | Closure (_,_) -> raise (invalid_arg "not supposed to be closure")
   | Val expval->
     match expval with 
     | Bool bool_value -> bool_value
     | _ -> raise (invalid_arg "not boolean value")
 
 let rec eval_s (exp : expr) (env : Env.env) : Env.value =
   match exp with 
   | Var _ -> Env.Val exp                           (* cannot evaluate a variable *)
   | Num _ | Bool _ -> Env.Val exp                         (* Base case constants *)
   | Unop (unop_val , expr_val) ->                           (* unary operators, assume only negate *)
       let Val resulting_term = eval_s expr_val env in
       (match unop_val, resulting_term with 
       | Negate, Num x -> Env.Val (Num (-x))
       | _, _ -> raise (EvalError "can't negate non-integers")) 
   | Binop (binop_val, expr_left, expr_right) ->              (* binary operators *)
       let Env.Val exp_left_extract = (eval_s expr_left env) in
       let Env.Val exp_right_extract = (eval_s expr_right env) in
       Env.Val (binopeval binop_val exp_left_extract exp_right_extract)
   | Conditional (expr_if, expr_then, expr_else)->            (* if then else, potential issue between the then and else statement *)
       if (conditioncheck (eval_s expr_if env)) then
         eval_s expr_then env
       else 
         eval_s expr_else env
   | Fun _ ->                            (* function definitions *)
       Env.Val exp
   | Let (old_varid_val, expr_head, expr_body) ->                 (* local naming *)
       let Env.Val new_expr_head = eval_s expr_head env in 
       eval_s (subst old_varid_val expr_body new_expr_head) env
   | Letrec (old_varid_val, expr_head, expr_body) ->               (* recursive local naming *)
       let Env.Val expr_head_value = eval_s expr_head env in
       eval_s (subst old_varid_val expr_body (subst old_varid_val expr_head_value
              (Letrec (old_varid_val, expr_head_value, Var old_varid_val )))) env
       
   | Raise  -> Env.Val Raise                                    (* exceptions *)
   | Unassigned -> Env.Val Unassigned                (* (temporarily) unassigned *)
   | App (expr1 , expr2) ->                                   (* function applications *)
     match expr1, expr2 with 
     | Fun (varid_val, expr_val), Num _  
     | Fun (varid_val, expr_val), Bool _  
     | Fun (varid_val, expr_val), Binop _   
     | Fun (varid_val, expr_val), Unop _
     | Fun (varid_val, expr_val), Conditional _   
     | Fun (varid_val, expr_val), Let _
     | Fun (varid_val, expr_val), Letrec _ ->  
       let subst_result = subst varid_val expr_val expr2 in
       eval_s subst_result env     
     | App (inner_func, middle_func), argument -> (* nested functions *)
       let Env.Val inner_eval = eval_s (App(middle_func, argument)) env in
       eval_s (App (inner_func, inner_eval)) env    
     | Letrec _, _  -> 
       let Env.Val recursion_eval = eval_s expr1 env in
       eval_s (App (recursion_eval, expr2)) env
     | _,_ -> raise (EvalError "Functional application requires function")
   ;;
 
   
 (* The DYNAMICALLY-SCOPED ENVIRONMENT MODEL evaluator -- to be
    completed *)
 let rec eval_d (exp : expr) (env : Env.env) : Env.value =
   match exp with 
   | Var x -> Env.lookup env x                           (* cannot evaluate a variable *)
   | Num _ | Bool _ -> Env.Val exp                         (* Base case constants *)
   | Unop (unop_val , expr_val) ->                           (* unary operators, assume only negate *)
       let Env.Val result = eval_d expr_val env in
       (match unop_val, result with
       |Negate, Num x -> Env.Val (Num (-x))
       | _, _ -> raise (EvalError "can't negate non-integers"))
   | Binop (binop_val, expr_left, expr_right) ->              (* binary operators *)
       let Env.Val exp_left_extract = (eval_d expr_left env) in
       let Env.Val exp_right_extract = (eval_d expr_right env) in
       Env.Val (binopeval binop_val exp_left_extract exp_right_extract)
   | Conditional (expr_if, expr_then, expr_else)->            (* if then else, potential issue between the then and else statement *)
       if (conditioncheck (eval_d expr_if env)) then
         eval_d expr_then env
       else 
         eval_d expr_else env
   | Fun _ ->                            (* function definitions *)
       Env.Val exp
   | Let (old_varid_val, expr_head, expr_body) ->                 (* local naming *)
       let new_expr_head = eval_d expr_head env in 
       let new_env = Env.extend env old_varid_val (ref new_expr_head) in
       eval_d expr_body new_env
   | Letrec (old_varid_val, expr_head, expr_body) ->               (* recursive local naming *)
       let temp = Env.extend env old_varid_val (ref (Env.Val Unassigned)) in
       let new_expr_head = eval_d expr_head temp in 
       let new_env = Env.extend temp old_varid_val (ref new_expr_head) in
       eval_d expr_body new_env     
   | Raise  -> Env.Val Raise                                    (* exceptions *)
   | Unassigned -> Env.Val Unassigned                (* (temporarily) unassigned *)
   | App (expr1 , expr2) ->                                   (* function applications *)
     match expr1, expr2 with 
     | Fun (varid_val, expr_val), Num _  
     | Fun (varid_val, expr_val), Bool _  
     | Fun (varid_val, expr_val), Binop _   
     | Fun (varid_val, expr_val), Unop _
     | Fun (varid_val, expr_val), Conditional _ 
     | Fun (varid_val, expr_val), Let _
     | Fun (varid_val, expr_val), Letrec _ ->      
       let result = eval_d expr2 env in   
       eval_d expr_val (Env.extend env varid_val (ref result))     
     | Var _, _ -> 
       let Env.Val result = eval_d expr1 env in   
       eval_d (App (result, expr2)) env
     | App (inner_var, middle_var), argument -> (* nested functions *)
       let Env.Val new_arg = eval_d argument env in
       let Env.Val new_middle_func = eval_d middle_var env in
       let Env.Val inner_eval = eval_d (App(new_middle_func, new_arg)) env in
       eval_d (App (inner_var, inner_eval)) env
    | _,_ -> raise (EvalError "Functional application requires function")
   ;;
   
 (* The LEXICALLY-SCOPED ENVIRONMENT MODEL evaluator -- optionally
    completed as (part of) your extension *)
 
 
    let rec eval_l (exp : expr) (env : Env.env) : Env.value =
     match exp with 
     | Var x -> Env.lookup env x                           (* cannot evaluate a variable *)
     | Num _ | Bool _ -> Env.Val exp                         (* Base case constants *)
     | Unop (unop_val , expr_val) ->                           (* unary operators, assume only negate *)
         let Env.Val result = eval_l expr_val env in
         (match unop_val, result with
         |Negate, Num x -> Env.Val (Num (-x))
         | _, _ -> raise (EvalError "can't negate non-integers"))
     | Binop (binop_val, expr_left, expr_right) ->              (* binary operators *)
         let Env.Val exp_left_extract = (eval_l expr_left env) in
         let Env.Val exp_right_extract = (eval_l expr_right env) in
         Env.Val (binopeval binop_val exp_left_extract exp_right_extract)
     | Conditional (expr_if, expr_then, expr_else)->            (* if then else, potential issue between the then and else statement *)
         if (conditioncheck (eval_l expr_if env)) then
           eval_l expr_then env
         else 
           eval_l expr_else env
     | Fun (old_varid_val, expr_val) ->                            (* function definitions *)
         Env.close exp env 
     | Let (old_varid_val, expr_head, expr_body) ->                 (* local naming *)
         let new_expr_head = eval_l expr_head env in 
         let new_env = Env.extend env old_varid_val (ref new_expr_head) in
         eval_l expr_body new_env
     | Letrec (old_varid_val, expr_head, expr_body) ->               (* recursive local naming *)
         let temp_env = Env.extend env old_varid_val (ref (Env.Val Unassigned)) in
         (*let temp_env = Env.extend env old_varid_val (ref (Env.Val (Letrec (old_varid_val, expr_head, Var old_varid_val)))) in*)       
         let new_expr_head = eval_l expr_head temp_env in 
         
         let new_env = Env.extend temp_env old_varid_val (ref new_expr_head) in
         eval_l expr_body new_env     
     | Raise  -> Env.Val Raise                                    (* exceptions *)
     | Unassigned -> Env.Val Unassigned                (* (temporarily) unassigned *)
     | App (expr1 , expr2) ->                                   (* function applications *)
       match expr1, expr2 with 
       | Fun (varid_val, expr_val), Num _  
       | Fun (varid_val, expr_val), Bool _  
       | Fun (varid_val, expr_val), Binop _   
       | Fun (varid_val, expr_val), Unop _
       | Fun (varid_val, expr_val), Conditional _ 
       | Fun (varid_val, expr_val), Let _
       | Fun (varid_val, expr_val), Letrec _ ->      
         let result = eval_l expr2 env in   
         eval_l expr_val (Env.extend env varid_val (ref result))     
       | Var x, _ -> 
         (match Env.lookup env x with 
         | Env.Val exparg -> raise (EvalError ("Shoudln't be an expression: "
                    ^(Expr.exp_to_concrete_string exparg)));
         | Env.Closure (func_exp, closure_env) ->   
         let Fun (varid_name, fun_body) = func_exp in 
         let Env.Val result = eval_l expr2 env in         
         eval_l fun_body (Env.extend closure_env varid_name (ref (Env.Val result))))      
       | App (inner_var, middle_var), argument -> (* nested functions *)
         let Env.Val new_arg = eval_l argument env in
         let Env.Closure (middle_func_exp, middle_env) = eval_l middle_var env in      
         let Fun (varid_name, fun_body) = middle_func_exp in 
         let Env.Val inner_eval = eval_l fun_body (Env.extend middle_env varid_name (ref (Env.Val new_arg))) in     
         eval_l (App (inner_var, inner_eval)) env
      | _,_ -> raise (EvalError "Functional application requires function")
     ;;
 (* The EXTENDED evaluator -- if you want, you can provide your
    extension as a separate evaluator, or if it is type- and
    correctness-compatible with one of the above, you can incorporate
    your extensions within `eval_s`, `eval_d`, or `eval_l`. *)
 
 let eval_e _ =
   failwith "eval_e not implement" ;;
   
 (* Connecting the evaluators to the external world. The REPL in
    `miniml.ml` uses a call to the single function `evaluate` defined
    here. Initially, evaluate is the trivial evaluator `eval_t`. But
    you can define it to use any of the other evaluators as you proceed
    to implement them. (We will directly unit test the four evaluators
    above, not the evaluate function, so it doesn't matter how it's set
    when you submit your solution.) *)
    
 let evaluate = eval_s ;;
 