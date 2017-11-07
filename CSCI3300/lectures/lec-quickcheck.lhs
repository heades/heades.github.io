---
title: QuickCheck':' Type-directed Property Testing
---

> module Testing where 
> import Test.QuickCheck hiding ((===))
> import Data.List

This note was originally authored by [Ranjit Jhala][12], but modified
by [Harley Eades][13].

In this lecture, we will look at [QuickCheck][1], a technique that
cleverly delivers a powerful automatic testing methodology.

Quickcheck was developed by [Koen Claessen][0] and [John Hughes][11] more
than ten years ago, and has since been ported to other languages and
is currently used, among other things to find subtle [concurrency bugs][3]
in [telecommunications code][4].

The key idea on which QuickCheck is founded, is *property-based
testing*.  That is, instead of writing individual test cases (eg unit
tests corresponding to input-output pairs for particular functions)
one should write *properties* that are desired of the functions, and
then *automatically* generate *random* tests which can be run to
verify (or rather, falsify) the property.

By emphasizing the importance of specifications, QuickCheck yields 
several benefits:

1. The developer is forced to think about what the code *should do*,

2. The tool finds corner-cases where the specification is violated, 
   which leads to either the code or the specification getting fixed,

3. The specifications live on as rich, machine-checkable documentation
   about how the code should behave.

Properties
==========

A QuickCheck property is essentially a function whose output is a boolean.
The standard "hello-world" QC property is

> prop_revapp :: [Int] -> [Int] -> Bool
> prop_revapp xs ys = reverse (xs ++ ys) == reverse xs ++ reverse ys


That is, a property looks a bit like a mathematical theorem that the
programmer believes is true. A QC convention is to use the prefix `"prop_"`
for QC properties. Note that the type signature for the property is not the 
usual polymorphic signature; we have given the concrete type `Int` for the
elements of the list. This is because QC uses the types to generate random
inputs, and hence is restricted to monomorphic properties (that don't
contain type variables.)

To *check* a property, we simply invoke the function

~~~~~{.haskell}
quickCheck :: (Testable prop) => prop -> IO ()
  	-- Defined in Test.QuickCheck.Test
~~~~~

lets try it on our example property above

~~~~~{.haskell}
ghci> quickCheck prop_revapp 
*** Failed! Falsifiable (after 2 tests and 1 shrink):     
[0]
[1]
~~~~~

Whats that ?! Well, lets run the *property* function on the two inputs

~~~~~{.haskell}
ghci> prop_revapp [0] [1] 
False
~~~~~

QC has found a sample input for which the property function *fails* ie,
returns `False`. Of course, those of you who are paying attention will
realize there was a bug in our property, namely it should be

> prop_revapp_ok :: [Int] -> [Int] -> Bool
> prop_revapp_ok xs ys = reverse (xs ++ ys) == reverse ys ++ reverse xs

because `reverse` will flip the order of the two parts `xs` and `ys` of 
`xs ++ ys`. Now, when we run 

~~~~~{.haskell}
*Main> quickCheck prop_revapp_ok
+++ OK, passed 100 tests.
~~~~~

That is, Haskell generated 100 test inputs and for all of those, the
property held. You can up the stakes a bit by changing the number of
tests you want to run

> quickCheckN   :: (Testable p) => Int -> p -> IO () 
> quickCheckN n = quickCheckWith $ stdArgs { maxSuccess = n }

and then do

~~~~~{.haskell}
*Main> quickCheckN 10000 prop_revapp_ok
+++ OK, passed 10000 tests.
~~~~~

QuickCheck QuickSort
--------------------

Lets look at a slightly more interesting example. Here is the canonical 
implementation of *quicksort* in Haskell.

> qsort        :: (Ord a) => [a] -> [a]
> qsort []     = []
> qsort (x:xs) = qsort lhs ++ [x] ++ qsort rhs
>   where lhs  = [y | y <- xs, y < x]
>         rhs  = [z | z <- xs, z > x]

Really doesn't need much explanation! Lets run it "by hand" on a few inputs

~~~~~{.haskell}
ghci> [10,9..1]
[10,9,8,7,6,5,4,3,2,1]
ghci> qsort [10,9..1]
[1,2,3,4,5,6,7,8,9,10]

ghci> [2,4..20] ++ [1,3..11]
[2,4,6,8,10,12,14,16,18,20,1,3,5,7,9,11]
ghci> qsort $ [2,4..20] ++ [1,3..11]
[1,2,3,4,5,6,7,8,9,10,11,12,14,16,18,20]
~~~~~

Looks good -- lets try to test that the output is in 
fact sorted. We need a function that checks that a 
list is ordered

> isOrdered ::         (Ord a) => [a] -> Bool
> isOrdered (x1:x2:xs) = x1 <= x2 && isOrdered (x2:xs)
> isOrdered _          = True

and then we can use the above to write a property

> prop_qsort_isOrdered :: [Int] -> Bool
> prop_qsort_isOrdered = isOrdered . qsort

Lets test it!

~~~~~{.haskell}
ghci> quickCheckN 10000 prop_qsort_isOrdered 
+++ OK, passed 10000 tests.
~~~~~

Conditional Properties
----------------------

Here are several other properties that we 
might want. First, repeated `qsorting` should not
change the list. That is, 

> prop_qsort_idemp ::  [Int] -> Bool 
> prop_qsort_idemp xs = qsort (qsort xs) == qsort xs


Second, the head of the result is the minimum element
of the input

> prop_qsort_min :: [Int] -> Bool
> prop_qsort_min xs = head (qsort xs) == minimum xs

However, when we run this, we run into a glitch


~~~~~{.haskell}
ghci> quickCheck prop_qsort_min 
*** Failed! Exception: 'Prelude.head: empty list' (after 1 test):  
[]
~~~~~

But of course! The earlier properties held *for all inputs*
while this property makes no sense if the input list is empty! 
This is why thinking about specifications and properties has the 
benefit of clarifying the *preconditions* under which a given 
piece of code is supposed to work. 

In this case we want a *conditional properties* where we only want 
the output to satisfy to satisfy the spec *if* the input meets the
precondition that it is non-empty.

> prop_qsort_nn_min    :: [Int] -> Property
> prop_qsort_nn_min xs = 
>   not (null xs) ==> head (qsort xs) == minimum xs
>
> prop_qsort_nn_max    :: [Int] -> Property
> prop_qsort_nn_max xs = 
>   not (null xs) ==> head (reverse (qsort xs)) == maximum xs

We can write a similar property for the maximum element too. This time
around, both the properties hold

~~~~~{.haskell}
ghci> quickCheckN 1000 prop_qsort_nn_min
+++ OK, passed 1000 tests.

ghci> quickCheckN 1000 prop_qsort_nn_max
+++ OK, passed 1000 tests.
~~~~~

Note that now, instead of just being a `Bool` the output
of the function is a `Property` a special type built into 
the QC library. Similarly the *implies* combinator `==>` 
is on of many QC combinators that allow the construction 
of rich properties.


Testing Against a Model Implementation
--------------------------------------

We could keep writing different properties that capture 
various aspects of the desired functionality of `qsort`. 
Another approach for validation is to test that our `qsort` 
is *behaviourally* identical to a trusted *reference 
implementation* which itself may be too inefficient or 
otherwise unsuitable for deployment. In this case, lets 
use the standard library's `sort` function

> prop_qsort_sort    :: [Int] -> Bool
> prop_qsort_sort xs =  qsort xs == sort xs

which we can put to the test

~~~~~{.haskell}
ghci> quickCheckN 1000 prop_qsort_sort
*** Failed! Falsifiable (after 4 tests and 1 shrink):     
[-1,-1]
~~~~~

Say, what?!

~~~~~{.haskell}
ghci> qsort [-1,-1]
[-1]
~~~~~

Ugh! So close, and yet ... Can you spot the bug in our code?

~~~~~{.haskell}
qsort []     = []
qsort (x:xs) = qsort lhs ++ [x] ++ qsort rhs
  where lhs  = [y | y <- xs, y < x]
        rhs  = [z | z <- xs, z > x]
~~~~~

We're assuming that the *only* occurrence of (the value) `x` 
is itself! That is, if there are any *copies* of `x` in the 
tail, they will not appear in either `lhs` or `rhs` and hence
they get thrown out of the output. 


Is this a bug in the code? What *is* a bug anyway? Perhaps the
fact that all duplicates are eliminated is a *feature*! At any 
rate there is an inconsistency between our mental model of how 
the code *should* behave as articulated in `prop_qsort_sort` 
and the actual behavior of the code itself.

We can rectify matters by stipulating that the `qsort` produces
lists of distinct elements

> isDistinct ::(Eq a) => [a] -> Bool
> isDistinct (x:xs) = not (x `elem` xs) && isDistinct xs
> isDistinct _      = True
>
> prop_qsort_distinct :: [Int] -> Bool 
> prop_qsort_distinct = isDistinct . qsort  

and then, weakening the equivalence to only hold on inputs that 
are duplicate-free 

> prop_qsort_distinct_sort :: [Int] -> Property 
> prop_qsort_distinct_sort xs = 
>   (isDistinct xs) ==> (qsort xs == sort xs)

QuickCheck happily checks the modified properties

~~~~~{.haskell}
ghci> quickCheck prop_qsort_distinct
+++ OK, passed 100 tests.

ghci> quickCheck prop_qsort_distinct_sort 
+++ OK, passed 100 tests.
~~~~~


The Perils of Conditional Testing
---------------------------------

Well, we managed to *fix* the `qsort` property, but beware! Adding
preconditions leads one down a slippery slope. In fact, if we paid
closer attention to the above runs, we would notice something

~~~~~{.haskell}
ghci> quickCheckN 10000 prop_qsort_distinct_sort 
...
(5012 tests; 248 discarded)
...
+++ OK, passed 10000 tests.
~~~~~

The bit about some tests being *discarded* is ominous. In effect, 
when the property is constructed with the `==>` combinator, QC 
discards the randomly generated tests on which the precondition 
is false. In the above case QC grinds away on the remainder until 
it can meet its target of `10000` valid tests. This is because 
the probability of a randomly generated list meeting the precondition 
(having distinct elements) is high enough. This may not always be the case.

The following code is (a simplified version of) the `insert` function 
from the standard library 

~~~~~{.haskell}
insert x []                 = [x]
insert x (y:ys) | x < y     = x : y : ys
                | otherwise = y : insert x ys
~~~~~

Given an element `x` and a list `xs`, the function walks along `xs` 
till it finds the first element greater than `x` and it places `x` 
to the left of that element. Thus

~~~~~{.haskell}
ghci> insert 8 ([1..3] ++ [10..13])
[1,2,3,8,10,11,12,13]
~~~~~

Indeed, the following is the well known [insertion-sort][5] algorithm

> isort :: (Ord a) => [a] -> [a]
> isort = foldr insert []

We could write our own tests, but why do something a machine can do better?!

> prop_isort_sort    :: [Int] -> Bool
> prop_isort_sort xs = isort xs == sort xs

~~~~~{.haskell}
ghci> quickCheckN 10000 prop_isort_sort 
+++ OK, passed 10000 tests.
~~~~~

Now, the reason that the above works is that the `insert` 
routine *preserves* sorted-ness. That is while of course 
the property 

> prop_insert_ordered'      :: Int -> [Int] -> Bool
> prop_insert_ordered' x xs = isOrdered (insert x xs)

is bogus

~~~~~{.haskell}
ghci> quickCheckN 10000 prop_insert_ordered' 
*** Failed! Falsifiable (after 4 tests and 1 shrink):     
0
[0,-1]

ghci> insert 0 [0, -1]
[0, 0, -1]
~~~~~

the output *is* ordered if the input was ordered to begin with

> prop_insert_ordered      :: Int -> [Int] -> Property 
> prop_insert_ordered x xs = 
>   isOrdered xs ==> isOrdered (insert x xs)

Notice that now, the precondition is more *complex* -- the property 
requires that the input list be ordered. If we QC the property

~~~~~{.haskell}
ghci> quickCheckN 10000 prop_insert_ordered
*** Gave up! Passed only 35 tests.
~~~~~

Ugh! The ordered lists are so *sparsely* distributed 
among random lists, that QC timed out well before it 
found 10000 valid inputs!

*Aside* the above example also illustrates the benefit of 
writing the property as `p ==> q` instead of using the boolean
operator `||` to write `not p || q`. In the latter case, there is 
a flat predicate, and QC doesn't know what the precondition is,
so a property may hold *vacuously*. For example consider the 
variant

> prop_insert_ordered_vacuous :: Int -> [Int] -> Bool
> prop_insert_ordered_vacuous x xs = 
>   not (isOrdered xs) || isOrdered (insert x xs)

QC will happily check it for us

~~~~~{.haskell}
ghci> quickCheckN 1000 prop_insert_ordered_vacuous
+++ OK, passed 10000 tests.
~~~~~

Unfortunately, in the above, the tests passed *vacuously* 
only because their inputs were *not* ordered, and one 
should use `==>` to avoid the false sense of security 
delivered by vacuity.

QC provides us with some combinators for guarding against 
vacuity by allowing us to investigate the *distribution* 
of test cases

~~~~~{.haskell}
collect  :: Show a => a -> Property -> Property
classify :: Bool -> String -> Property -> Property
~~~~~

We may use these to write a property that looks like

> prop_insert_ordered_vacuous' :: Int -> [Int] -> Property 
> prop_insert_ordered_vacuous' x xs = 
>   -- collect (length xs) $
>   classify (isOrdered xs) "ord" $
>   classify (not (isOrdered xs)) "not-ord" $
>   not (isOrdered xs) || isOrdered (insert x xs)

When we run this, as before we get a detailed breakdown
of the 100 passing tests

~~~~~{.haskell}
ghci> quickCheck prop_insert_ordered_vacuous'
+++ OK, passed 100 tests:
 9% 1, ord
 2% 0, ord
 2% 2, ord
 5% 8, not-ord
 4% 7, not-ord
 4% 5, not-ord
 ...
~~~~~

where a line `P% N, COND` means that `p` percent of the inputs had length
`N` and satisfied the predicate denoted by the string `COND`. Thus, as we
see from the above, a paltry 13% of the tests were ordered and that was
because they were either empty (`2% 0, ord`) or had one (`9% 1, ord`).
or two elements (`2% 2, ord`). The odds of randomly stumbling upon a 
beefy list that is ordered are rather small indeed!

[0]: http://www.cse.chalmers.se/~koen/
[1]: http://www.cse.chalmers.se/~rjmh/QuickCheck/
[2]: http://www.cs.york.ac.uk/fp/smallcheck/
[3]: http://video.google.com/videoplay?docid=4655369445141008672#
[4]: http://www.erlang-factory.com/upload/presentations/55/TestingErlangProgrammesforMulticore.pdf
[5]: http://en.wikipedia.org/wiki/Insertion_sort
[6]: http://hackage.haskell.org/packages/archive/QuickCheck/latest/doc/html/src/Test-QuickCheck-Gen.html#Gen
[7]: http://book.realworldhaskell.org/read/monads.html
[8]: http://book.realworldhaskell.org/read/testing-and-quality-assurance.html
[9]: http://www.haskell.org/haskellwiki/QuickCheck_as_a_test_set_generator
[10]: http://community.moertel.com/~thor/talks/pgh-pm-talk-lectrotest.pdf
[11]: http://www.cse.chalmers.se/~rjmh
[12]: https://ranjitjhala.github.io/
[13]: http://metatheorem.org