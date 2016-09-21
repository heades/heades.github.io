---
title: Functions, Pattern Matching, and Polymorphism
---
<div class="hidden">
\begin{code}

module LectFuns where

import Prelude hiding (zip,zipWith,curry,uncurry,(.),foldr,foldl,any,all,concatMap,map)

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
the guard in the last equation is `otherwise`, this is the "catch-all"
case.  That is, it is exactly like `else` in an if-then-else
expression, and thus, if all the guards on the previous equations are
false, then this equation is chosen.

So consider `ldf 7 24`.  First, ghci checks to see if `divides 7 24`
is true, but it is false, and so abandons that equation and moves onto
the second one, and asks if `k^2 > n`, and it is, and so `ldf 7 24 =
24`.

As a second example, consider `ldf 7 2224`.  Notice that `7` does
not divide `2224`, nor is `7^2 > 2224`, and thus, the equation ghci
runs is the third equation, because that is the catch-all case. Thus,
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
** Exception: not a positive integer
CallStack (from HasCallStack):
  error, called at lectures/lec-functions-patternmatching-polymorphism.lhs:164:21 in main:LectFuns
ghci> 
~~~~~~~~~~~~~~~~~~~~~~~

Keep in mind that this exception cannot be caught, and it causes the
current execution to be terminated.

Pattern Matching
----------------

There is one extremely powerful tool Haskell -- as well as many other
functional programming languages -- provides called *pattern
matching*.  This allows one to case split on the shape of a data type.
First, we will concentrate on pattern matching on input arguments, and
then discuss a more general form which allows for one to case split on
the outputs of function calls.

We begin with an example.  Suppose we wished to define disjunction over
the booleans.  One way would be to use guards:

\begin{code}
or1 :: Bool -> Bool -> Bool
or1 b1 b2 | b1 = True
          | b2 = True
          | otherwise = False
\end{code}

This works, but consider a second way:

\begin{code}
or2 :: Bool -> Bool -> Bool
or2 True b2 = True
or2 b1 True = True
or2 b1 b2 = False
\end{code}

The function `or2` uses pattern matching on the input arguments by
enforcing when either `b1` or `b2` are `True`.  Consider the first
equation of `or2`, this equation states that `b1` must be `True`, and
if during evaluation it is not, then Haskell will move on to the next
equation where it will check to see if `b2` is `True`.  In the second
equation, `b1` means that the first argument can be either `True` or
`False`, but if during evaluation this argument is chosen, then it is
necessarily the case that `b1` is `False`, or the first equation would
have triggered.  Finally, if during evaluation the third equation is
chosen, then both inputs must be `False`.

Haskell's evaluation strategy is called "call-by-need evaluation."
This means that Haskell will only evaluate a program when it needs its
value and in all other cases it will leave the program completely
unevaluated.  Consider as an example the following two functions:

\begin{code}
foo :: Integer -> Bool
foo 0 = False
foo n = True

bar :: Bool
bar = or2 True (foo 5)
\end{code}

When evaluating `bar` Haskell will evaluate as little as possible to
determine the output of `or2`, and hence, since the first argument is
`True` Haskell does not have to evaluate `foo 5` at all, and in fact,
it does not evaluate it, and simply returns `True`, because that is
all it needs to determine the correct output.  This style of
evaluation is often called *lazy evaluation* for obvious reasons.

Here is a third way to define this function:

\begin{code}
or3 :: Bool -> Bool -> Bool
or3 False False = False
or3 b1 b2 = True
\end{code}

In this version we use pattern matching to determine when the function
should be `False`, and then leave the catch-all case to handle when it
should return `True`.

We can simplfy this function one last time:

\begin{code}
or4 :: Bool -> Bool -> Bool
or4 False False = False
or4 _ _ = True
\end{code}

Notice that in the definition of `or3` the second equation does not
use the variables `b1` and `b2` in the body of the function.  This new
definition tells Haskell to ignore those inputs completely, because we
are not going to use them.  The `_` is called the "joker".  It can be
read as "I don't care what this argument is, in fact, I am not even
going to use it."

Booleans are fun, but they do not have a lot of structure, and so it
is hard to see just how powerful pattern matching is.  Recall that
every list `[x1,x2,x3,...,xi]` is just syntactic sugar for the list
`x1 : x2 : x3 : ... : xi : []`.  In addition, both of the previous
lists are equivalent to `x1:[x2,x3,...,xi]`.  It turns out that the
latter form can be used to pattern match on lists.

Consider the following example:

\begin{code}
firstInt :: [Int] -> Int
firstInt [] = error "empty list has no first integer"
firstInt (i:rest) = i
\end{code}

We know that either a list is empty or it has at least one element
inside of it.  The first equation in `firstInt` checks to see if the
input list is empty, and if so outputs an error.  If during evaluation
the second equation is hit, then we know that the list cannot be
empty, because Haskell starts with the first equation and moves
downward until it matches the pattern.  The pattern `i:rest` tells
Haskell to name the first element of the input list `i`, and to name
the remainder of the list `rest`.  For example, suppose we applied
`firstInt` to the list `[1,2,3]`, then we know that this list is
equivalent to the list `1:[2,3]`.  Haskell will then set `i = 1`, and
`rest = [2,3]`.

Let us check to see if this is the case by writing a program to show us
the values of `i` and `rest`:

\begin{code}
ext :: [Int] -> (Int, [Int])
ext [] = error "ext doesn't like the empty list"
ext (i:rest) = (i,rest)
\end{code}

The return type of the previous function is a pair type, and has the
form `(a,b)` where `a` and `b` are some other types.  It is simply the
type of all pairs where the first projection is of type `a` and the
second projection is of type `b`.  Thus, `(1,2)` has type `(Int,Int)`,
and the pair `(1,[2,3])` has type `(Int,[Int])`.  The pair `(42,True)`
has type `(Int, Bool)`.

Now we can run our test using `ext`:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
ghci> ext [1,2,3]
(1,[2,3])
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The real power of pattern matching comes in when it is mixed with
recursion.  First, notice that we can place an ordering on lists.  The
empty list is the smallest list, and we have the following:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
x:xs > xs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We call an ordering like this a *structural ordering*, because it
decreases with the structure of the data type.  Using this structural
ordering we can write terminating structurally recursive functions.

Consider the following example:

\begin{code}
double :: [Int] -> [Int]
double [] = []
double (x:xs) = 2*x : double xs
\end{code}

First, `double` pattern matches on the input list, and if it is empty,
then it simply returns the empty list, but if the input is not empty
then `double` returns a new list with the head set to `2*x`, but we
compute the tail of the list by recursion effectively doubling the
rest of the list.  Notice that the recursive call is applied to `xs`
which is a structurally smaller list than the input.  This tells us
that we know `double` will eventually terminate.

Pattern matching can work with other data types as well.  For example,
if we need to get access to the projections of a pair we can use
pattern matching.

\begin{code}
proj1 :: (Int,Int) -> Int
proj1 (x,y) = x

proj2 :: (Int,Int) -> Int
proj2 (x,y) = y
\end{code}

Every data type supports pattern matching.

Higher-Order functions
----------------------

Recall that every a function type

~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
a1 -> a2 -> ... -> a(i-1) -> ai
~~~~~~~~~~~~~~~~~~~~~~~~~

is full parenthesized as

~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
a1 -> (a2 -> ... -> (a(i-1) -> ai))
~~~~~~~~~~~~~~~~~~~~~~~~~

Hence, a type `a1 -> a2 -> a3 -> a4` is fully parenthesized as `a1 ->
(a2 -> (a3 -> a4))`. This implies that every function in Haskell, and
indeed in any functional programming language, is an unary function
that takes in one input, and returns a function that may be waiting
for another input.  

Consider the following function:

\begin{code}
zip :: [a] -> [b] -> [(a,b)]
zip (a:as) (b:bs) = (a,b) : zip as bs
zip _ _ = []
\end{code}

The previous function is equivalent to the following one:

\begin{code}
zip' :: [a] -> ([b] -> [(a,b)])
zip' (a:as) =
       \l -> case l of
               (b:bs) -> (a,b) : zip' as bs
               _ -> []
zip' _ = \l -> []    
\end{code}

The expression `\x -> e` is called a $\lambda$-expression, which are
the anonymous functions of Haskell; they are equivalent to
$\mathsf{fun}\, \Rightarrow e$ in Functional Iffy.  The function
`zip'` takes a single input, and then outputs another function that is
waiting for the second input.  In fact, `zip` is syntactic sugar for
`zip'`.

Every function being unary comes with a very nice property called
*partial application*.  This is where a function is applied to only a
few inputs, and not all of them.  For example,

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
ghci> :t zip [1]
zip [1] :: [Integer] -> [(Integer, Integer)]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Here we asked for the type of `zip [1]`, and we can see that it is
indeed a function waiting for an integer-list input.  Now checkout:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
ghci> let z = zip [1] in z [2]
[(1,2)]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

So we can see that `zip [1]` is indeed a function, that can be applied
to a second list.

We have only considered functions that return functions as output, but
what about functions that take functions as input?  This is also
supported in Haskell, and any other functional programming language.

Consider the `zipWith` function:

\begin{code}
zipWith :: (a -> b -> c) -> [a] -> [b] -> [c]
zipWith f (a:as) (b:bs) = (f a b) : zipWith f as bs
zipWith _ _ _ = []
\end{code}

This function takes as input a binary function `f : a -> b -> c`, a
list of first arguments, and a list of second arguments, but then
collects all of the outputs into a list.

Functions that take in functions as arguments or returns arguments as
output are called *higher-order functions* and they are the driving
force of functional programming.  The real power of functional
programming comes from higher-order functions.

We consider some further examples.  The three most used functions in
all of functional programming has to be `map`, `foldl`, and `foldr`.
A map takes a function, and applied it accross a list:

\begin{code}
map :: (a -> b) -> [a] -> [b]
map f [] = []
map f (x:xs) = (f x) : map f xs
\end{code}

The recursive pattern of the definition of map pops up all the time in
functional programming.  Here is an example evaluation of `map`.
Suppose we have the following function on characters:

\begin{code}
mangle :: Char -> Char
mangle x | x == 'a' || x == 'A' = 'Z'
mangle x | x == 'h' || x == 'H' = '*'
mangle x | x == 'l' || x == 'L' = '$'
mangle x = x
\end{code}

Then `map` evaluates like so:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
map mangle "Haskell" 
~> (mangle 'H') : map mangle "askell"
~> (mangle 'H') : (mangle 'a') : map mangle "skell"
~> (mangle 'H') : (mangle 'a') : (mangle 's') : map mangle "kell"
~> (mangle 'H') : (mangle 'a') : (mangle 's') : (mangle 'k') : map mangle "ell"
~> (mangle 'H') : (mangle 'a') : (mangle 's') : (mangle 'k') : (mangle 'e') : map mangle "ll"
~> (mangle 'H') : (mangle 'a') : (mangle 's') : (mangle 'k') : (mangle 'e') : (mangle 'l') : map mangle "l"
~> (mangle 'H') : (mangle 'a') : (mangle 's') : (mangle 'k') : (mangle 'e') : (mangle 'l') : (mangle 'l') : map mangle ""
~> (mangle 'H') : (mangle 'a') : (mangle 's') : (mangle 'k') : (mangle 'e') : (mangle 'l') : (mangle 'l') : []
~> '*' : (mangle 'a') : (mangle 's') : (mangle 'k') : (mangle 'e') : (mangle 'l') : (mangle 'l') : []
~> '*' : 'Z' : (mangle 's') : (mangle 'k') : (mangle 'e') : (mangle 'l') : (mangle 'l') : []
~> '*' : 'Z' : 's' : (mangle 'k') : (mangle 'e') : (mangle 'l') : (mangle 'l') : []
~> '*' : 'Z' : 's' : 'k' : (mangle 'e') : (mangle 'l') : (mangle 'l') : []
~> '*' : 'Z' : 's' : 'k' : 'e' : (mangle 'l') : (mangle 'l') : []
~> '*' : 'Z' : 's' : 'k' : 'e' : 'l' : (mangle 'l') : []
~> '*' : 'Z' : 's' : 'k' : 'e' : '$' : '$' : []
= "*Zske$$"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

So map allows one to apply an operation accross a collection of data,
but folds allow one to reduce a collection to some other value.  There
are two types of folds: left folds and right folds.

First, we consider the left fold:

\begin{code}
foldl :: (b -> a -> b) -> b -> [a] -> b
foldl f x [] = x
foldl f x (a:as) = foldl f (f x a) as
\end{code}

Think of `x` in the definition of `foldl` as an accumilator which
accumilates repeatedly applying `f` starting with `x`.  Suppose we
wanted to reverse a list.  One way we saw to do it earlier in this
course is to do the following:

\begin{code}
reverseBad :: [a] -> [a]
reverseBad [] = []
reverseBad (x:xs) = reverseBad xs ++ [x]
\end{code}

This version of `reverse` is bad, because it is not tail recrusive,
and it has an expoential runtime, because the use of append requires
us to go through the input list multiple times.

If we use a well-known pattern called the *accumilator pattern* we can
rewrite `reverse` so that it is tail recursive, and has a linear
runtime cost.  This pattern says to add an additional argument to the
program we are interested in, and use it to *accumilate* the return
value.  First, we define an auxiliary function that computes the
reverse of a list, but uses an accumilator:

\begin{code}
reverseAux :: [a] -> [a] -> [a]
reverseAux acc [] = acc
reverseAux acc (a:as) = reverseAux (a:acc) as
\end{code}

The second argument to `reverseAux` is the list we want to reverse, but
the first argument is the accumilator.  Its job is to accumilate the
ultimate return value, which in this example happens to be the
reversed list.  This will force the step case to be tail recursive.

Now we can define the reverse function interms of `reverseAux`:

\begin{code}
reverse' :: [a] -> [a]
reverse' l = reverseAux [] l
\end{code}

We can think of the accumilator in `reverseAux` as a global variable.
Then in `reverse'` we initialize this variable to the empty list.  The
runtime of `reverse` is indeed linear.

The first argument to the function `revAux` is the accumilator. Now
compare the structure of `foldl` and the structure of `reverseAux`.
We can see a pattern.  The left fold `foldl` embodies the accumilator
pattern.  Thus, we can use `foldl` whenever we want to accumilate, so
for example, we can define `reverse` as follows:

\begin{code}
reverse :: [a] -> [a]
reverse l = foldl revAux [] l
 where
  revAux :: [a] -> a -> [a]
  revAux acc x = x:acc
\end{code}

When you think accumilator, think `foldl`.  Now we can do an
evaluation of `reverse` to see how `foldl` works:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
reverse [1,2,3]
~> foldl revAux [] [1,2,3]
~> foldl revAux (revAux [] 1) [2,3]
~> foldl revAux (revAux (revAux [] 1) 2) [3]
~> foldl revAux (revAux (revAux (revAux [] 1) 2) 3) []
~> revAux (revAux (revAux [] 1) 2) 3
~> revAux (revAux (1:[]) 2) 3
~> revAux (2:1:[]) 3
~> 3:2:1:[]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Another common fold is the *right fold* called `foldr`, and it is
defined as follows:

\begin{code}
foldr :: (a -> b -> b) -> b -> [a] -> b
foldr f x [] = x
foldr f x (y:ys) = f y (foldr f x ys)
\end{code}

Suppose we have a list `[x1,x2,x3,x4,x5,x6]`, a `x : b`, and a
function `f : a -> b -> b`, then the `foldr` function computes the
following:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
foldr f x [x1,x2,x3,x4,x5,x6]
~> f x1 (foldr f x [x2,x3,x4,x5,x6])
~> f x1 (f x2 (foldr f x [x3,x4,x5,x6]))
~> f x1 (f x2 (f x3 (foldr f x [x4,x5,x6])))
~> f x1 (f x2 (f x3 (f x4 (foldr f x [x5,x6]))))
~> f x1 (f x2 (f x3 (f x4 (f x5 (foldr f x [x6])))))
~> f x1 (f x2 (f x3 (f x4 (f x5 (f x6 (foldr f x []))))))
~> f x1 (f x2 (f x3 (f x4 (f x5 (f x6 x)))))
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

As an example, suppose we have a list of lists, and we want to flatten
that list into a list of all the elements that occur in the inner
lists.  We can do this using `foldr`:

\begin{code}
flatten :: [[a]] -> [a]
flatten l = foldr (++) [] l
\end{code}

Here is an example evaluation:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
flatten [[1,2],[3,4],[42,24]]
~> foldr (++) [] [[1,2],[3,4],[42,24]]
~> [1,2] ++ (foldr (++) [] [[3,4],[42,24]])
~> [1,2] ++ ([3,4] ++ (foldr (++) [] [[42,24]]))
~> [1,2] ++ ([3,4] ++ ([42,24] ++ (foldr (++) [] [])))
~> [1,2] ++ ([3,4] ++ ([42,24] ++ []))
~> [1,2] ++ ([3,4] ++ [42,24])
~> [1,2] ++ [3,4,42,24]
~> [1,2,3,4,42,24]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Higher-order functions give rise to what is called *pointfree
programming* where we try to use actual inputs as little as possible.
Recall the following example from above:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
flatten :: [[a]] -> [a]
flatten l = foldr (++) [] l
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Input variables like `l` are called points. We can turn the definition
of `flatten` into point-free style by not naming any of the inputs,
and simply construct a function as follows:

\begin{code}
flattenPF :: [[a]] -> [a]
flattenPF = foldr (++) []
\end{code}

Notice that we do not name the input list, that is, we do not require
a point.  Let's think about this from a type perspective.  The type of
`flattenPF` is `[[a]] -> [a]`, but the type of `flattenPF l` -- we are
naming the input `l` -- is `[a]`.  Furthermore, the type of `foldr
(++) []` is `[[a]] -> [a]`, and thus, we really do not need to name
the input, because we have a function with the same type as
`flattenPF`.

Constructing complex point-free programs requires the use of function
composition, which is another example of a higher-order function.  We
need the following higher-order function:

\begin{code}
(.) :: (b -> c) -> (a -> b) -> (a -> c)
(g . f) a = g (f a)
\end{code}

Function composition allows us to chain several functions together
like a pipe.  For example, if I have four functions `f :: a -> b`, `g
:: b -> c`, `h :: c -> d`, and `i :: d -> e`, then suppose I want to
first run `f`, and then run `g` on the output of `f`, but then run `h`
on the output of that, and so on, but this is equivalent to defining a
function from `a -> e` by chaining each of the functions together.  So
we can do this using function composition as follows:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
i.h.g.f :: a -> e
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Suppose we want to take a list of lists of integers, and first flatten
it, but then double each element.  Then we can do this in point-free
style as follows:

\begin{code}
collapseDouble :: [[Integer]] -> [Integer]
collapseDouble = (map (2*)).flatten
\end{code}

It turns out that any higher-order function that returns a function as
output, can be turned into an $n$-ary function using pairs as inputs:

\begin{code}
curry :: ((a,b) -> c) -> (a -> b -> c)
curry f a b = f (a , b)
\end{code}

This operation is called *currying* after the mathematician and
logician [Haskell Curry](https://en.wikipedia.org/wiki/Haskell_Curry).
This operation also has an inverse called `uncurrying`:

\begin{code}
uncurry :: (a -> b -> c) -> ((a,b) -> c)
uncurry f (a,b) = f a b
\end{code}

We can proof that these are bijections.  Suppose `f :: (a,b) -> c`, `x
:: a`, and `y :: b`, then we can see show that `uncurry` is the inverse
of `curry` as follows:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
uncurry (curry f) a b
= (curry f) a b
= curry f a b
= f (a, b)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Thus, `uncurry (curry f) = f`.  We can show the opposite.  Suppose `f
:: a -> b -> c`.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
curry (uncurry f) a b
= (uncurry f) a b
= uncurry f a b
= f a b
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Therefore, `curry (uncurry f) = f`. These two proofs show that
functions of type `a -> (b -> c)` are isomorphic -- essentially
equivalent to functions of type `(a,b) -> c`.

We can phrase these mutual inverse properties as test cases as
follows:

\begin{code}
curryUncurry1 :: Eq c => ((a,b) -> c) -> a -> b -> Bool
curryUncurry1 f a b = (uncurry (curry f)) (a,b) == f (a,b)

curryUncurry2 :: Eq c => (a -> b -> c) -> a -> b -> Bool
curryUncurry2 f a b = (curry (uncurry f)) a b == f a b
\end{code}

One important thing about currying is that we can view it as a test
for whether or not a programming language supports general
higher-order functions, and hence, functional programming.  Any
programming language that doesn't cannot be called functional.

Currying and uncurrying also allow us to choose a representation to
fit the problem we might be modeling.  For example, if I am
programming with a coordinate system, then I would use functions of
type `(a,b) -> c`, but then this doesn't fit the type of functions for
some of the higher-order operations we have been studying, but I know
that I can always curry my function to put its type in the right form.

Polymorphism
------------

Recall the curry function:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
curry :: ((a,b) -> c) -> (a -> b -> c)
curry f x y = f (x , y)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This is an example of a polymorphic function.  The variables `a`, `b`,
and `c` are called *type variables*.  Think of them as holes which any
type at all can fill.  For example, the following is an
*instantiation* of the type variables in the type of `curry`:

\begin{code}
curry1 :: ((Integer,Bool) -> String) -> (Integer -> Bool -> String)
curry1 f x y = f (x , y)
\end{code}

Take note that that the type of `curry` changed, but the
implementation stayed the same.  This is the main property of a
polymorphic function.  That is, a function is polymorphic if a portion
of its type is generic in that it can be instantiated with more than
one type without the implementation changing.

Here is another example of a polymorphic function:

\begin{code}
append :: [a] -> [a] -> [a]
append [] l2 = l2
append l1 [] = l1
append (x:xs) l2 = x : append xs l2
\end{code}

This time, the input and output are not as arbitrary as the previous
example, but the type of the elements of the input and output lists
are generic.  This is because when appending two lists together the
implementation does not need to actually know what kind of elements
are in the list.

One thing to remember is to try and make functions as polymorphic as
possible, because it facilitates the notion of writing one
implementation that can be used in many different situations.

The polymorphism in Haskell is very powerful, and it can also steer
what the implementation must be.  For example, say we have just the
type `f : a -> a`, then what possible implementations could `f` have?
In languages like C# it could have many, because one could use side
effects to do just about anything, but in Haskell we have no side
effects.  Thus, `f` can really only do one thing:

\begin{code}
f : a -> a
f x = x
\end{code}

We don't know what `x` is, because it has a generic type, and thus, we
cannot perform any operations on it, hence the only thing `f` could
possibly do is return `x` as is.

Recall composition from above:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
(.) :: (b -> c) -> (a -> b) -> (a -> c)
(g . f) a = g (f a)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We can see that this function also only has one implementation,
because the type is so generic it forces us to implement as we did.

However, when the type is more specific the number of implementations
increase.  Consider append:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.(haskell)
append :: [a] -> [a] -> [a]
append [] l2 = l2
append l1 [] = l1
append (x:xs) l2 = x : append xs l2
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The number of implementations for this is quite a lot, but our
specification of what append must do kicks in and we are able to write
it, but the type of `x` is generic, and hence, we cannot alter `x` in
the implementation.

The lesson is that the more general a functions type the less number
of implementations it will have, but the more specific the type the
more implementations.