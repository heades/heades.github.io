---
title: Type Based Verification using Liquid Haskell
---
<div class="hidden">
\begin{code}

module LectLiquid where    

import qualified Data.Text as T
import qualified Data.Text.Unsafe as UT    
    
{-@ type Nat = {n:Int | n > 0} @-}    

notEmpty :: [a] -> Bool
notEmpty [] = False
notEmpty (_:_) = True
                 
{-@ measure notEmpty @-}

{-@ type NEList a = {l:[a] | notEmpty l} @-}

{-@ hd :: l:NEList a -> a  @-}
hd :: [a] -> a
hd (x:xs) = x            

{-@ ex1 :: l:[NEList Char] -> String @-}
ex1 :: [String] -> String
ex1 l = map hd l

\end{code}
</div>

These lectures are based on this
[book](http://ucsd-progsys.github.io/liquidhaskell-tutorial/book.pdf)
by the Liquid Haskell founders.

Haskell can be Unsafe
=====================

Throughout this semester I have made the argument that Haskell's type
system make programming more correct, and more safe, by eliminating
bugs at compiletime as opposed to runtime.

Haskell is indeed a step in the right direction, but it is still
possible to do very unsafe things.  First, one might think that it is
not possible to obtain a segfault in Haskell, because of the type
system, but this is just not true.  Consider the following basic use
of a function called `unsafeIndex :: Vector a -> Int -> a`:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.{haskell}
ghci> :m +Data.Vector
ghci> let v = fromList ["haskell", "C#"]
gchi> unsafeIndex v 0
"haskell"
ghci> unsafeIndex v 1
"C#"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now consider what happens when we ask for an index out of bounds:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.{haskell}
ghci> unsafeIndex v 10
'ghci' terminated by signal SIGSEGV ...
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now this function `unsafeIndex` has *unsafe* in the name, but this
shows that it possible to define a Haskell function that could cause a
segfault.

What about reading past the edge of a memory buffer and returning
bytes stored in memory unintentionally. This is excatly the main poin
behind the heart-bleed exploit. Consider the following:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.{haskell}
ghci> :m + Data.Text Data.Text.Unsafe
ghci> let t = pack "Theory"
ghci> takeWord16 5 t
"Theor"
ghci> takeWord16 100 t
"Theory\NUL\NUL\9880\588\SOH\NUL\25392\2537\SOH\NUL\429108\SOH\NUL\NUL\NUL\NUL\NUL\ENQ\NUL\NUL\NUL\46792[\SOH\NUL\31515\835\SOH\NUL\53497\2100\SOH\NUL\741428\SOH\NUL\11868\24832\NUL\NUL\46792[\SOH\NUL\31515\835\SOH\NUL\53497\2100\SOH\NUL\757812\SOH\NUL\13156\24832\NUL\NUL\50168\637\SOH\NUL\774196\SOH\NUL\790580\SOH\NUL\33979\854\SOH\NUL\830516\SOH\NUL\17409\1652\SOH\NUL\17409\1652\SOH\NUL\41801\1552\SOH\NUL"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Notice that the final command above actually returns bytes stored in
memory that are adjacent to `"Theory"`.  These extra bytes could be
junk, but they could also be passwords to bank accounts or other
sensitive information.

These examples show that while Haskell is a step in the right
direction, there is still more work that needs to be done.

Liquid Haskell: Our First Example
==================================

A real world example might be to use Liquid Haskell to prevent any
misuse of the function `takeWord16` by refining its type.  Now one
might wonder why anyone would want to use this function knowing that
is unsafe.  Haskell allows one to drop down to the C level and
provides many unsafe functions to allow the programmer to control
efficiency.

We are going to define a safe version of `takeWord16` called
`safeTakeWord16 :: Int -> String -> String`.  To use Liquid Haskell to
prevent any misuse of this we will refine its type so that the length
of the input list must be at least the the first input of the
function.  That is, if we apply it like `safeTakeWord16 2 "Liquid"`
then the program should type check using Liquid Haskell, but if we
apply it like `safeTakeWord16 3 "LH"`, then we should expect a type
error from Liquid Haskell.

The first thing we will do is define a new type called `SizedListLB a
N` where `a` is the type of the elements of our new list, and `N` is
the lower bound on the size each list is a allowed to have.  Thus,
`SizedListLB Char 5` is the type of all lists whose size is at least
`5`.  Thus, the list `['a','b','c','d','e']` has type `SizedListLB
Char 5` while `[1,2]` does not have type `SizedListLB Int 4`.

We define our new type as follows:

\begin{code}
{-@ type SizedListLB a N = {s:[a] | len s >= N} @-} 
\end{code}

Think of `len s` as the one true length of the list s, and it is built
into Liquid Haskell.

Finally, using this new type we can refine `safeTakeWord16` as
follows:

\begin{code}
{-@ safeTakeWord16 :: n:Int -> SizedListLB Char n -> String @-}
safeTakeWord16 :: Int -> String -> String
safeTakeWord16 n s = let t = T.pack s
                      in show $ UT.takeWord16 n t
\end{code}

The benefit of all of this is that when we use `safeTakeWord` Liquid
Haskell enforces that the input meets the refinement type.  Thus, the
following type checks:

\begin{code}
ex2 :: String
ex2 = safeTakeWord16 2 "Liquid"
\end{code}

However, the following does not type check:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.{haskell}
ex3 :: String
ex3 = safeTakeWord16  100 "Liquid"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

What are Refinement Types, Really?
==================================

Refinement types can be seen as a pair of a logic predicate and a
type. Logical predicates are constructed from a subset of boolean
valued Haskell expressions.  First, we have the following constants:

$c := 0 \mid 1 \mid 2 \mid 3 \mid \cdots$

An expression $e$ is then defined by the following grammar:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
e := x                 -- Variables
   | c                 -- Constants
   | e + e             -- Addition
   | e - e             -- Subtraction
   | c * e             -- Constant multiplication
   | x e1 e2 ... en    -- Variable application
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Next we define the valid relations:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
r := ==                -- equality
   | /=                -- disequality
   | >=                -- greater than or equal
   | <=                -- less than or equal
   | >                 -- greater than
   | <                 -- less than
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~