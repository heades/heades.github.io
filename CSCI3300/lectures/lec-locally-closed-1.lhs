---
title: The Locally-Nameless Binding Representation
---

De Bruijn Indices
=================

One of the hardest aspects of implementing programming languages is
implementing binding constructs like `fun x => b` where `x` is bound
in the program `b`.  Consider the naive approach where we just use
some naming device like strings or integers.  Then we could implement
syntax for functions and application as follows[^1]:

<div class="hidden">
\begin{code}
{-@ LIQUID "--short-names" @-}
{-@ LIQUID "--no-termination" @-}

module LectLC where

\end{code}
</div>
\begin{code}
type Name = Integer

data NExp =
    VarN Name 
  | FunN Name NExp
  | AppN NExp NExp
  deriving Show
\end{code}

However, consider an expression `FunN 0 (VarN 0)` how can we tell if
`VarN 0` is free or bound? There is no way to tell.  We might be able
to get around this by saying, well, the binder has to match, but
consider this expression `FunN 0 (FunN 0 (VarN 0))` now which binder
does `VarN 0` belong to?  There is no way to say.  We could then say,
well, associate it with the closest binder to the variable in the
syntax tree. But, notice that all of this requires us to check
external properties.  Thus, code will be riddled with sanity checks.
How can we instead build a data type that is more in line with
enforcing these properties?  This is the name of the binding
implementation game.  That is, how can we make it so that the syntax
enforces the properties we want with as little development overhead as
possible?  Furthermore, can we develop our syntax to allow for
mathematical reasoning about the properties of the PL we are
implementing.

The earliest attempt to make implementing binding constructs a little
less painful is called *De Bruijn Indices* due to the Dutch
mathematician [Nicolaas Govert de
Bruijn](https://en.wikipedia.org/wiki/Nicolaas_Govert_de_Bruijn).
Names are integers in De Bruijn's representation, but we use a
particular pattern for keeping track of which variable is bound to
which binder.  To aid the reader first consider the data type of our
syntax in De Bruijn's representation:

\begin{code}
data BExp =
    VarB Name
  | FunB BExp
  | AppB BExp BExp
  deriving Show  
\end{code}

Now, a `Name` is still an integer, and the syntax for variables did
not change.  However, notice that the `Name` on functions is now
removed.  This is the major contribution of this representation of
syntax.  But, you might be wondering how we associate a binder to a
bound variable.  De Bruijn came up with a naming scheme for bound
variables.  The name of a bound variable, in a program `b`, is equal
to the one less than the number of binders it is below in `b`'s parse
tree.  For example, consider the following expressions:

\begin{code}
expB1 :: BExp
expB1 = FunB (VarB 0)

expB2 :: BExp
expB2 = FunB (AppB (FunB (VarB 1)) (VarB 0))

expB3 :: BExp
expB3 = AppB (FunB (FunB (AppB (VarB 0) (VarB 1)))) (VarB 2)
\end{code}

Using this scheme it is always possible to decide which variable is
associated with which binder.  However, notice that it is relatively
hard to decide which variables are free and which are bound.  This is
where locally-nameless representation comes into play.  

Locally-Nameless Representation (LNR)
===================================

LNR splits the variable constructor into two constructors `Fvar Name`
and `Bvar Name` where the former is the constructor for free
variables, and the later is the constructor for bound variables.  De
Bruin indices are then used for the naming scheme for bound variables,
but there is no naming scheme for free variables.

The following is the datatype of expressions for Functional Iffy using
LNR:

\begin{code}
data Exp =
    Fvar Name
  | Bvar Name
  | T
  | F
  | And Exp Exp
  | Or Exp Exp
  | If Exp Exp Exp
  | Fun Exp
  | App Exp Exp
  deriving Show
\end{code}

Here are some examples:
\begin{code}
exLC1 :: Exp
exLC1 = App (Fun (And (Bvar 0) (Fvar 0))) (Fun (Fun (Bvar 0)))

exLC2 :: Exp
exLC2 = And T (Fvar 42)

exLC3 :: Exp
exLC3 = Fun (If (Bvar 0) (Fun (And (Bvar 1) (App (Fun (Bvar 3)) T))) (Fvar 21))
\end{code}

Here are a few non-examples:
\begin{code}
nexLC1 :: Exp
nexLC1 = Fun (Bvar 1)

nexLC2 :: Exp
nexLC2 = Bvar 0

nexLC3 :: Exp
nexLC3 = Fun (If (Bvar 1) (Fun (And (Bvar 2) (App (Fun (Bvar 4)) T))) (Fvar 21))
\end{code}

Notice that `nexLC3` is `exLC3` with the indices all incrementated.

Opening and Closing
-------------------

The $\beta$-rule states that we can evaluate $app\,
(\mathsf{fun}\,x\,\Rightarrow b2)\,b1$ to $[b1/x]b2$.  The first thing
this rule does is go from $\mathsf{fun}\,x\,\Rightarrow b2$ to $b2$,
which implicitly transforms $x$ from a bound variable into a free
variable.  Consider the same situation using LNR.  We can model
$\mathsf{fun}\,x\,\Rightarrow b2$ by `Fun b2` where $x$ is `Bvar i`.
Then when we go from `Fun b2` to `b2` the variable `Bvar i`
becomes a free-bound variable, and thus, is not replaceable via
substitution.  When we rip off a binder we need an operation that
converts a free-bound variable into an actual free variable.  This
operation is called opening an expression.

Opening an expression converts a free-bound variable into a free
variable:

\begin{code}
open :: Name -> Exp -> Exp
open x b = open' x 0 b
 where
  open' :: Name -> Name -> Exp -> Exp
  open' x y b@(Bvar z) | y == z = Fvar x
                       | otherwise = b
  open' x y (Fun b) = Fun (open' x (y+1) b)
  open' x y (And b1 b2) = And (open' x y b1) (open' x y b2)
  open' x y (Or b1 b2) = Or (open' x y b1) (open' x y b2)
  open' x y (App b1 b2) = App (open' x y b1) (open' x y b2)
  open' x y (If b1 b2 b3) = If (open' x y b1) (open' x y b2) (open' x y b3)                   
  open' x y b = b
\end{code}

This definition implies that in the application `open x b` the first
argument, `x`, is the name of the new free variable, the second
argument, `b`, is the program we are opening.  Notice that this
definition does indeed prevent one from replacing a bound variable
that is associated with a binder:

\begin{code}
openEX :: Exp
openEX = open 0 (Fun (Bvar 0))
\end{code}

The previous expression evaluates to `Fun (Bvar 0)` and not 
`Fun (Fvar 0)`, thus, the openly bound variables that `open` will replace are
indeed free-bound variables.

Closing is the dual operation.  It replaces a free variable with a
bound variable.  Keep in mind that in the bound variable that replaces
the free variable must be labeled with the number of abstractions we
pass to reach that variable.  Thus, the recursive definition is
similar to that of `open`.

\begin{code}
close :: Name -> Exp -> Exp
close x b = close' 0 x b
 where            
   close' :: Name -> Name -> Exp -> Exp
   close' x y b@(Fvar z) | y == z = Bvar x
                         | otherwise = b
   close' x y (Fun b) = Fun (close' x (y+1) b)
   close' x y (And b1 b2) = And (close' x y b1) (close' x y b2)
   close' x y (Or b1 b2) = Or (close' x y b1) (close' x y b2)
   close' x y (App b1 b2) = App (close' x y b1) (close' x y b2)
   close' x y (If b1 b2 b3) = If (close' x y b1) (close' x y b2) (close' x y b3)                   
   close' x y b = b
\end{code}

Local Closure
-------------

The only property of expressions we must check externally is that
there are no free-bound variables.  The datatype does not enforce this
internally.  We call a program *locally-closed* if and only if it
contains no free-bound variables.  We now will define a function, `lc
:: Exp -> Bool` that captures this property.  However, before we can
define `lc` we first must define a means of generating a fresh free
variable.

The following function computes the list of free variables in its argument.

\begin{code}
fv :: Exp -> [Name]
fv (Fvar x) = [x]
fv (Fun b) = fv b
fv (And b1 b2) = (fv b1) ++ (fv b2)
fv (Or b1 b2) = (fv b1) ++ (fv b2)
fv (App b1 b2) = (fv b1) ++ (fv b2)
fv (If b1 b2 b3) = (fv b1) ++ (fv b2) ++ (fv b3)
fv _ = []
\end{code}

The previous function follows exactly the definition developed in the
theory section.  Using this we define `freshFV :: Exp -> Name` that
will generate a fresh free variable name with respect to the free
variables in its argument by first computing the list of free
variables, and then adding one to the maximum label.

\begin{code}
freshFV :: Exp -> Name
freshFV b = let fvars = fv b
             in case fvars of
                  [] -> 0
                  _ -> fresh fvars
 where
   fresh :: [Name] -> Name
   fresh n = (maximum n) + 1
\end{code}

Finally, we use `freshFV` to define the local-closure predicate:

\begin{code}
lc :: Exp -> Bool
lc (Bvar _) = False
lc (Fun b) = lc (open x b)
 where
   x = freshFV b
lc (And b1 b2) = (lc b1) && (lc b2)
lc (Or b1 b2) = (lc b1) && (lc b2)
lc (App b1 b2) = (lc b1) && (lc b2)
lc (If b1 b2 b3) = (lc b1) && (lc b2) && (lc b3)       
lc _ = True
\end{code}                     

The take away from this definition is that to test local closure of `Fun b` we rip off the binder, and open `b`.  This eliminates the bound variable associated with that binder, and thus, if we keep eliminating bound variables, then we should eventually reach a program with only free variables left.  If this does not happen, then we know the input is not locally closed.  In addition, notice that when we open `b` we generate a fresh variable.

The Evaluator
-------------

At last we have reached the pinnacle of this section the evaluator.  First, we need capture-avoiding substitution.  This actually has a straightforward definition:
    
\begin{code}    
subst :: Exp -> Name -> Exp -> Exp
subst b x b'@(Fvar y) | x == y = b
                      | otherwise = b'
subst b x (Fun b') = Fun (subst b x b')
subst b x (App b1 b2) = App (subst b x b1) (subst b x b2)
subst b x (And b1 b2) = And (subst b x b1) (subst b x b2)
subst b x (Or b1 b2) = Or (subst b x b1) (subst b x b2)
subst b x (If b1 b2 b3) = If (subst b x b1) (subst b x b2) (subst b x b3)
subst b x b' = b'
\end{code}

Notice that if the input of `subst` is locally closed, then it is
capture avoiding by definition, because the only way for a binder to
capture a variable is if the variable is a `Bvar`, and hence, since
the input is locally closed, then this cannot be the case.  In fact,
we have the following result:

If `lc(b1)` and `lc(b2)`, then `lc(subst b1 x b2)` for any `x`.

Thus, to prevent capture simply restrict oneself to the locally-closed
expressions.

Finally, we have the evaluator:
\begin{code}                           
eval' :: Exp -> Exp
eval' (Fun b) = Fun $ eval' b            

eval' (App b1 b2) = case v1 of
                     (Fun v) -> let fvar = freshFV v
                                 in eval' $ subst v2 fvar $ open fvar v
                     _ -> App v1 v2
 where
   v1 = eval' b1
   v2 = eval' b2

eval' (And e1 e2) = case (v1,v2) of
                     (T,T) -> T
                     (F,T) -> F
                     (T,F) -> F
                     (F,F) -> F
                     (_,_) -> And v1 v2
 where
   v1 = eval' e1
   v2 = eval' e2
        
eval' (Or e1 e2) = case (v1,v2) of
                     (T,T) -> T
                     (F,T) -> T
                     (T,F) -> T
                     (F,F) -> F
                     (_,_) -> Or v1 v2
 where
   v1 = eval' e1
   v2 = eval' e2

eval' (If e1 e2 e3) = case v1 of
                       T -> v2
                       F -> v3
                       _ -> If v1 v2 v3
 where
   v1 = eval' e1
   v2 = eval' e2
   v3 = eval' e3
   
eval' b = b

eval :: Exp -> Exp
eval b | lc b = eval' b
       | otherwise = error "Input to eval is not locally closed."              
\end{code}
The most interesting case of the evaluators definition is function application.  In this case we first evaluate the arguments to `App`, and then we decide if the first is a function or not, and if it is, then we apply the $\beta$-rule.  To $\beta$-contract we first, rip off the binder, open the body of the function with a fresh-free variable, and then do the substitution.  The remainder of the cases are straightforward.  Lastly, notice that we check for local closure in `eval` before evaluating.  This prevents any type of capture.

The following are several examples:    

\begin{code}
evalTest1 :: Exp
evalTest1 = eval $ App (Fun (Bvar 0)) T

evalTest2 :: Exp
evalTest2 = eval $ And T $ Or F $ App (App (Fun (Fun (Bvar 1))) T) T

evalLoop :: Exp
evalLoop = let l = (Fun (App (Bvar 0) (Bvar 0)))
            in eval $ App l l

evalTest3 :: Exp
evalTest3 = eval $ Or (Fvar 0) T                

evalTest4 :: Exp
evalTest4 = eval $ App (Fun (Bvar 1)) T   
\end{code}        

[^1]: We append `N` to each to each constructor, because this file is
a [Literate Haskell](https://wiki.haskell.org/Literate_programming)
file that can be interpreted by GHCi, and thus, the data types we
implement in this post all must be distinct.