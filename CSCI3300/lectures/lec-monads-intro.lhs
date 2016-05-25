---
title: Introduction to Monads
---
<div class="hidden">
\begin{code}

module LectMonads where

import System.Random
\end{code}
</div>
Why no side effects?
====================

I have said many times during this semester that side effects can
hinder reasoning about programs.  For example, suppose we have a
method in C#, say `foo`, whose input type in an `Int` and whose output
type is an `Int`.  Then try and describe all that `foo 2` could do.
It could do a lot of things like call out to the network, read from
state, write to state, print to the screen, read from the keyboard,
throw an exception, catch an exception, and the list goes on and on.
However, contrast this with a function, `foo :: Int -> Int` written in
Haskell.  Now `foo 2` can only do so much.  It can only apply
operations with *no* side effects to `2`, and then eventually return
an integer.  That is it.  This tells us that in a pure setting we get
a lot of assurances right from the type.  

So that is the Ivory tower elevator pitch for purity in programming
languages.  The software engineer is now wondering how we actually get
anything done.  No side effects means no communication from the world,
but what good are any programs that do not access the outside world.
Again, I have another Ivory Tower pitch for the interesting things
about pure programs, but from software engineering perspective no side
effects means that the programs we write will not be very practically
interesting.

Luckily, Haskell does have a means of using side effects.  The cool
part about this is that we get side effects, but we also get strong
assurances from our types.  

Side Effects: A High-level Explanation
======================================

First, let us consider how to do some simple IO.  Consider the
following hello world example:

\begin{code}
hello :: IO ()
hello = do
  putStrLn "Hello World!!"
\end{code}

When we load and run this in GHCi we obtain the following:

~~~~~~~~~~~~~~~~~~~~.{haskell}
Hello World!
~~~~~~~~~~~~~~~~~~~~

Note that the response is not surrounded by double quotes, because
GHCi is not returning a `String`, but is actually showing us the
result printed to STDOUT.

Consider a second example:

\begin{code}
helloPizza :: IO ()
helloPizza = do
  putStrLn "Hello World!!"
  putStrLn "Bring me pizza!"
\end{code}

The next function gets input from the user, and then returns a boolean
indicating if the input was even or odd:

\begin{code}
evenOdd :: IO Bool
evenOdd = do
  putStr "Enter a number: "
  s <- getLine
  let d = read s :: Integer
   in if (d `mod` 2 == 0) then
        return True
      else
        return False
\end{code}

The type `IO Bool` tells us that the function `evenOdd` uses IO, but
then it will eventually return a boolean.  Thus, a function with the
type `IO ()` only does IO and never returns a value.  A function with
a type of the form `IO a` says that the function will do IO, but will
eventually return something of type `a`.

Suppose we want to prompt the user to enter a string, and then output
the strings reverse, but does not stop prompting until the user enters
`done`.  The following function gets the job done:

\begin{code}
reversal :: IO ()
reversal = do
  putStr "String? "
  s <- getLine
  if s == "done" then
      return ()
  else
      do putStrLn.reverse $ s
         reversal
\end{code}

This function is a little more complex.  When we test to see if `s ==
"done"` then we must define the `then` and the `else` parts of the
`if`-expression which both have type `IO ()`, and thus, in the second
we are forced to use a nested do-block to first output the reverse of
the input, and then loop back.  The expression `return ()` indicates
that we are ready to exit the function, but return nothing.  For our
purposes we can think of `()` as void or null.

Now we look at a different use of IO which is to generate random
numbers using a random number generator.  The following example
requires that we import the System.Random library.  To do this place
the following import expression at the top of the file you are working
in:

~~~~~~~~~~~~~~~~~~~~.{haskell}
import System.Random
~~~~~~~~~~~~~~~~~~~~

Our objective is to write a function `rollDie` that models rolling an
`n :: Integer` sided die `r :: Int` times.  We will return the `r`
rolls as a list of `Integer`s.  System.Random provides a function
`newStdGen :: IO StdGen` that returns a new psuedo random number
generator that uses the system.  Once we have a generator we can use
`randomRs :: RandomGen g => (a, a) -> g -> [a]` The first argument is
a pair `(lo,hi)`, which repesents the range of the random values, and
the second argument is a random generator which we will obtain from
`newStdGen`.  Finally, `randomRs` returns an infinite list of random
values between `hi` and `lo`.  The final function is defined as
follows:

\begin{code}
rollDie :: Integer -> Int -> IO [Integer]
rollDie n r = do
  gtr <- newStdGen
  return $ take r (randomRs (1,n) gtr)
\end{code}

One thing to note about this example is that we actually return
something while doing IO.  Thus, the return type is `IO [Integer]`,
and the definition explicitly uses `return`.

The protypical example of a monad is `IO`, but this is not the only
example.  There are lots and lots of monads.  Perhaps the simpliest
example is that of partial functions.  If a function does not return a
value, then we can think of that as a side effect.  It is the side
effect of being undefined.

Every function in Haskell is a total function.  That is, it is one
function that is defined for every possible value of the input type.
Thus, to be able to define a partial function we need a way to
indicate that for a particular input there is no defined output.  We
capture this by the following parameterized datatype:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.{haskell}
data Maybe a = Nothing | Just a
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This datatype is used as the return type to partial functions.  The
construct `Nothing` indicates that the function is undefined, and the
constructor `Just x` indicates that the function is defined and the
output is `x`.  This as it turns out is a monad, and in fact, we
define functions on it in the same way that we do for `IO`:

\begin{code}
myLookUp :: Eq a => [(a,b)] -> a -> Maybe b
myLookUp l x = do
   r <- lookup x l
   return $ r
\end{code}

At this point it is time to take a peak under the hood of monads.

Side Effects: A Peak Under the Hood
===================================

We can now give a full definition of monads:

--------------------------
A **monad** is a parameterized datatype `m a` such that the following
functions can be defined:
- (Return) `return :: a -> m a`
- (Bind) `bind :: m a -> (a -> m b) -> m b`
- where `return` and `bind` are subject to several laws, but they are
not important for our purposes.  However, if one defines a new monad,
then they must make sure the laws hold.
--------------------------

In Haskell the there is a built `bind` whose name is `(>>=)` which is
an infix binary operator.  As for `return` the bultin name is
`return`.  Throughout our examples below we use the naming scheme `ri`
and `bi` for some natural number `i`.  The former will stand for
`return` and the later will stand for `bind`.

The type `m a` should be thought of as the type of **computations** of
type `a`.  Computations allow for all the crazy stuff we love while
programming like IO, continuations, generating random number, being
partial, and lot of other handy notions of computation.  However, the
type `a` should be considered the type of **pure** values that do not
allow for any funny business.  

By and large Haskell is pure, but monads give us a means of working
with computations.  The function `return :: a -> m a` allows one to
take a pure value and call it a computation.  Thus, we can move
everything we do in Haskell into any monad.  This is important because
we want to separate our computations from our values.  Doing as much
work as possible using values is much safer.  Another prespective is
that values are pure computations, and thus, `return` allows us to
make this explicit.

So if something of type `m a` is a computation that eventually returns
a value of type `a`, then we need a way to define a means of composing
monad together to compute complex computations.  This is the purpose
of `bind :: m a -> (a -> m b) -> m b`.  The type of `bind` requires
that we have two computations each of type `m a` and `m b`
respectively.  The computation of type `m b` depends on a value of
type `a`, and hence, we can repsesent this by a function `a -> m b`.
What `bind` allows us to do is to run the computation of `m a` until
it eventually reaches a value of type `a`, and then it pipes that
value into the computation of type `m b` and continues evaluating
until we reach a computation of type `m b`.

To help solidify our understanding of the definition of a monad we
will prove that some datatypes are monads.  The following two
functions prove that `Maybe a` is indeed a monad.

\begin{code}
r1 :: a -> Maybe a
r1 x = Just x

b1 :: Maybe a -> (a -> Maybe b) -> Maybe b
b1 Nothing f = Nothing
b1 (Just x) f = f x
\end{code}

The function `r1` defines return for `Maybe a` and the function `b1`
defines bind.  

We motivated `Maybe a` as the return type of partial functions, and so
what if we have two partial functions `f :: a -> Maybe b` and `g : b
-> Maybe c` how do we compose them together to obtain a new function
`a -> Maybe c`?  We can use bind, `b1`, for that.

\begin{code}
comp :: (a -> Maybe b) -> (b -> Maybe c) -> (a -> Maybe c)
comp f g x = (f x) `b1` g
\end{code}

This indeed shows that bind really does just pipe the value of one
computation into another.

It so happens that lists are monads!  We show this as follows:

\begin{code}
r2 :: a -> [a]
r2 x = [x]

b2 :: [a] -> (a -> [b]) -> [b]
b2 [] f = []
b2 (x:xs) f = (f x)++(b2 xs f)
\end{code}

Return for lists is pretty easy, to inject a value of type `a` into
the list monad `[a]` we simply return the singleton list.  Bind is a
little more interesting.  Given a computation of type `l :: [a]` and a
function `f :: a -> [b]` we are supposed to return a computation of
type `[b]`.  To do this we first map `f` across `l` to obtain a
computation of type `[[b]]`, but then we flatten this list using
append.  In fact, all `b2` does is `map` `f` across `l` followed by
`concat :: [[a]] -> a', and so, we can give a much nicer definition of
bind for lists as follows:

\begin{code}
b2' :: [a] -> (a -> [b]) -> [b]
b2' l f = concat $ map f l
\end{code}

Bind for lists is prefect for any situation where you want to take the
generalized union of a list of lists.  In fact, you will try this out
in your homework.

Haskell has return and bind already defined for a number of datatypes.
The names and types are as follows:

~~~~~~~~~~~~~~~~~~~~~~.{haskell}
 return :: a -> m a
 (>>=) :: m a -> (a -> m b) -> m b
~~~~~~~~~~~~~~~~~~~~~~

For example, here are two expressions using them for `Maybe Integer`:

\begin{code}
exp1 = (Just 42) >>= (\x -> return $ x + 5)
exp2 = Nothing >>= (\x -> return $ x + 5)
\end{code}

If you run `exp1` in GHCi it will return `Just 47`, and then `exp2`
will return `Nothing`.  The first definition really makes the piping
behavior of bind.  Run the following expression in GHCi:

\begin{code}
exp3 = (Just 42) >>= (\x -> return x)
\end{code}

Notice that we obtain `Just 42`, and this is because 'x' gets replaced
by `42` in `return x` yielding `return 42`, but the latter is equal by
definition to `Just 42`.  Thus, we really are piping the values from
the Maybe monad into the next computation.  

Consider the following expression:

\begin{code}
exp4 = [[1,2],[3,4],[5,6]] >>= (\l -> return $ (l >>= (\x -> return $ x^2)))
\end{code}

Running this expression will return `[[1,4],[9,16],[25,36]]`, but now
that we understand bind and return for this this is easy to see from
the definition.

A Peak Under the Hood: The do-Notation
======================================

The do-notation that we started with provides a very nice interface to
programming monads. This notation can be used for any monad, but what
does this do-notation really correspond to?

We will incrementally introduce the desugaring of the do-notation.
First, in the simplest example the do-notation provides a means of
imperatively sequencing operations.  There is a monadic bind-like
operator for sequencing operations that we can define in terms of
bind:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.{haskell}
(>>) :: m a -> m b -> m b
c1 >> c2 = c1 >>= (\_ -> c2)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Thus, `c1 >> c2` means first evaluate the computation `c1`, and then
when it is done ignore its return value and continue evaluating the
computation `c2` returning its final value.  

We can now desugar the do-notation for sequencing.  A do-block of the form:

~~~~~~~~~~~~~~~~~~~.{haskell}
do 
  c1
  c2
  ...
  ci
~~~~~~~~~~~~~~~~~~~

Is equivalent to the following:

~~~~~~~~~~~~~~~~~~~~~~~.{haskell}
c1 >> c2 >> ... >> ci
~~~~~~~~~~~~~~~~~~~~~~~

Thus, the final computation returned after evaluating the do-block is
the final computation returned by the last computation in the block.

As an example we can see that:

\begin{code}
exp5 = do
  putStrLn "1"
  putStrLn "2"
  putStrLn "3"
\end{code}

Is equivalent to the following:

\begin{code}
exp6 = (putStrLn "1") >> (putStrLn "2") >> (putStrLn "3")
\end{code}

The do notation allows us to do more than just sequence operations it
allows us to **assign** a return value from a computation, something
of type `m a`, to a variable and use it later in the computation.  A
do-block of the form:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.{haskell}
do 
  x1 <- c1
  ...
  xi <- ci
  c x1...xi
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Is equivalent to the monadic expression:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.{haskell}
c1 >>= (\x1 ->
    c2 >>= (\x2 ->
        c3 >>= (\x3 -> 
            ...
            ci >>= (\xi -> 
                c x1 ... x3)...)))
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Consider the following example:

\begin{code}
exp7 = do
  putStr "Enter a number: "
  x <- getLine
  putStrLn $ "You entered " ++(show x)++"!"
\end{code}

Is equivalent to the following:

\begin{code}
exp8 = (putStr "Enter a number: ") >>= (\_ -> 
         getLine >>= (\x -> 
                  putStrLn $ "You entered " ++(show x)++"!"))
\end{code}

Using the sequencing operator we can rewrite `exp8` as follows:

\begin{code}
exp9 = (putStr "Enter a number: ") >>  
         getLine >>=
           (\x -> putStrLn $ "You entered " ++(show x)++"!")
\end{code}

One thing to make a note of with regards to the desugaring of the
do-notation is that the desugared form reveals that each operation in
a do-block must be of the same type of computation.  That is, they all
must be of the form `m a` for some type of computation `m`, but the
type of the values returned my vary.  For example, in `exp7` we make
use of computations of type `IO ()` and of type `IO String`, but all
computations are from `IO`.  An example of violating this is the
following:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.{haskell}
exp10 = do
  x <- Just 1
  c <- getLine
  return 42
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The program `exp10` tries to mix both the Maybe monad and the IO
monad, but if we desugar this into:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.{haskell}
exp11 = (Just 1) >>= (\x -> 
                  getLine >>= (\y -> 
                           return 42))
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We can see that the type of bind enforces that all of the first
arguments of bind must be from the same monad.  Thus, we will hit a
type error.

<div class="hidden">
\begin{code}
-- data State a =
--   State (Int -> (a, Int))

-- put :: Int -> State ()
-- put n = State $ \_ -> ((), n)

-- get :: State Int 
-- get = State $ \n -> (n,n)

-- r3 :: a -> State a
-- r3 x = State $ \s -> (x, s)

-- b3 :: State a -> (a -> State b) -> State b
-- b3 st f = State $ b3' st f
--   where
--     b3' :: State a -> (a -> State b) -> (Int -> (b,Int))
--     b3' (State f) g s = h s'
--       where
--         (x, s') = f s
--         (State h) = g x

-- instance Functor State where
--   fmap f s = s `b3` (\x -> r3 $ f x)

-- instance Applicative State where
--     pure = r3
--     (<*>) s s' = s `b3` (\f -> s' `b3` (\x -> r3 $ f x))

-- instance Monad State where
--   return = r3
--   (>>=) = b3

-- evens :: [Int] -> State Int
-- evens [] = get
-- evens (n:ns) | n `mod` 2 == 0 =
--                   do m <- get
--                      put (m+1)
--                      evens ns
--               | otherwise = evens ns
                    
-- evens' :: [Int] -> State Int
-- evens' [] = get
-- evens' (n:ns) | n `mod` 2 == 0 =
--                    get
--                  `b3` (\m -> ((
--                    put (m+1)
--                  ) `b3` (\_ ->
--                    evens' ns)
--                  ))
--              | otherwise = evens' ns

-- evalState :: State a -> Int -> a
-- evalState (State t) n = fst $ t n
\end{code}
</div>