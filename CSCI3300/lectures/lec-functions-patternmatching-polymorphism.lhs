---
title: Functions, Pattern Matching, and Polymorphism
---
<div class="hidden">
\begin{code}

module LectFuns where

\end{code}
</div>

Functions
---------

In C# the predominant way to structure programs is by using objects
and methods.  Haskell is a bit different which uses *functions* to
structure programs.  Now do not think this means that Haskell lacks in
the ability to structure large programs, because as we will see
throughout the semester structuring programs using functions is very
powerful.

Throughout this section we will design a prime number generator which
will require the construction of a number of functions.  The general
layout of a function in Haskell is as follows:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
name :: a1 -> a2 -> ... -> ai -> b
name x1 x2 ... xi = y
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Here the type of `x1` is `a1`, the type of `x2` is `a2`, and so on
until the type of `xi` is `ai`, and finally, the type of `y` is `b`. 

For example, here is the divides function:

\begin{code}
divides :: Integer -> Integer -> Bool
divides d n = rem n d == 0
\end{code}

This function takes in two integers, and returns `True` when `n`
divided by `d` has a remainder of `0`.  Here the function `rem` is the
remainder function which is equivalent to `n % d` in C#. For example,

~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
ghci> divides 2 6
True
ghci> divides 3 12
True
ghci> divides 4 9
False
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

