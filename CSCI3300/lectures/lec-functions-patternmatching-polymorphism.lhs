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

This is called a *guarded equation* which has the general form:

~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
name x1 x2 ... xi | b1 = y1
name x1 x2 ... xi | b2 = y2
name x1 x2 ... xi | b3 = y3
name x1 x2 ... xi | b4 = y4
...
name x1 x2 ... xi | otherwise = yj
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Each of the `x1 ... xi` are the arguments to the function, and each
`b1 ... bj` are booleans and are called *guards*.  Finally, each of
`y1 ... yj` are the respective bodies of the function.  Ghci evaluates
this function by starting at the first equation, and determining if
`b1` is true, if it is, then the function returns `y1`, but if it is
false, then Haskell movies on to the second equation and determines if
`b2` is true, and if it is, then returns `y2`, and so on.  Notice that
the guard in the last equation is `otherwise`, this is the "catch all"
case.  That is, it is exactly like `else` in an if-then-else
expression, and thus, if all the guards on the previous equations are
false, then this equation is chosen.

So consider `ldf 7 24`.  First, ghci checks to see if `divides 7 24`
is true, but it is false, and so abandons that equation and moves onto
the second one, and asks if `k^2 > n`, and it is, and so `ldf 7 24 =
24`.

As a second example, consider `ldf 7 2224`.  Notice that `7` does
not divide `2224`, nor is `7^2 > 2224`, and thus, the equation ghci
runs is the third equation, because that is the catch all case. Thus,
`ldf 7 2224 = ldf (7+1) 2224 = ldf 8 2224`.  In this branch we make a
recursive call which increases the first argument by one.  Finally, we
can see that `divides 8 2224` is true, and hence, `ldf 7 2224 = ldf 8
2224 = 8`.

Note that in Haskell doing recursive calls is easy, because we can
simply call the function again within the body of the function.  This
is just like mathematics!  In this class all functions we define must
be terminating, and thus, one must make sure that when making a
recursive call to increase or decrease at least one argument to the
function, so that it tends towards the base cases.  In `ldf` we
increase by one, because we know from algebra that it is a property of
the least divisor function that we will eventually find the least
divisor greater than `k`.

Using `ldf` we can define the least common divisor function as follows:

\begin{code}
ld :: Integer -> Integer
ld n = ldf 2 n
\end{code}

Here are a few examples:

~~~~~~~~~~~~~~~~~~~~~~.(haskell)
ghci> ld 14
2
ghci> ld 15
3
ghci> ld 16
2
ghci> ld 55
5
~~~~~~~~~~~~~~~~~~~~~~

At this point we have everything we need to define a prime number test.

\begin{code}
isPrime n | n < 1 = error "not a positive integer"
          | n == 1 = False
          | otherwise = ld n == n
\end{code}

In the definition of `isPrime` we used a bit a simplified form of the
guards.  This definition is equivalent to the following one:

~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
isPrime n | n < 1 = error "not a positive integer"
isPrime n | n == 1 = False
isPrime n | otherwise = ld n == n
~~~~~~~~~~~~~~~~~~~~~~~~

The `error` function tells Haskell to throw an exception and output
its argument to STDOUT -- the screen -- the message.  For example,

~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
ghci> isPrime (-1)
*** Exception: not a positive integer
CallStack (from HasCallStack):
  error, called at lectures/lec-functions-patternmatching-polymorphism.lhs:164:21 in main:LectFuns
ghci> 
~~~~~~~~~~~~~~~~~~~~~~ 