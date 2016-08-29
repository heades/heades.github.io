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

Here the type of `x1` is `a1, the type of `x2` is `a2`, and so on
until finally the type of `xi` is `ai` and the type of `y` is `b`.