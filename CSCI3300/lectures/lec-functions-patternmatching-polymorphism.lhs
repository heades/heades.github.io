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

Guards
------

The next step of our prime number test is to define a means of
computing the least divisor of a number `n` that is greater than `1`.
The algorithm is a bit eaiser if we define it in terms of one that
computes the least divisor of `n` greater than or equal to a
threshold `k`.  The algorithm is as follows:

1. If `divides k n`, then `ldf k n = k`
2. If `k^2 > n`, then `ldf k n = n`
3. Otherwise `ldf k n = ldf (k+1) n`

So we need to find a way to write a function which uses a condition,
and a means of doing recursion, because the previous description calls
`ldf` again in the result.

There are two ways to define `ldf`.  The first way is as follows:

\begin{code}
ldf1 :: Integer -> Integer -> Integer
ldf1 k n = if (divides k n)
           then k
           else if (k^2 > n)
                then n
                else ldf1 (k+1) n
\end{code}

This function definition uses the if-then-else expression `if b then
e1 else e2` where `b` is a boolean, `e1` has some type `a`, and `e2`
has the same type `a`.

However, there is a better way using what are called *guards*.

\begin{code}
ldf :: Integer -> Integer -> Integer
ldf k n | divides k n = k
ldf k n | k^2 > n = n
ldf k n | otherwise = ldf1 (k+1) n
\end{code}

This is called a *guard equation* which of the general form:
~~~~~~~~~~~~~~~~~~~~~~~.(haskell)

~~~~~~~~~~~~~~~~~~~~~~~