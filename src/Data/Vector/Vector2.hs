{-# OPTIONS -Wall -O2 #-}

module Data.Vector.Vector2
    (Vector2(..)
    ,vector2
    ,first,second,(***),both,zip
    ,fst,snd,swap
    ,curry,uncurry
    ,prop_range)
where

import           Prelude             hiding (fst, snd, curry, uncurry, zip)
import qualified Prelude
import           Control.Applicative (Applicative(..), liftA2, liftA3)
import           Control.Monad       (join, liftM2)
import           Data.Array          (Ix(..))
import           Data.Binary         (Binary(..))
-- import Test.QuickCheck.Arbitrary(Arbitrary(..))

data Vector2 a = Vector2 {-# UNPACK #-} !a {-# UNPACK #-} !a
  -- Note the Ord instance is obviously not a mathematical one
  -- (Vectors aren't ordinals!). Useful to have in a binary search
  -- tree though.
  deriving (Eq, Ord, Show, Read)

instance Binary a => Binary (Vector2 a) where
  get = liftM2 Vector2 get get
  put (Vector2 x y) = put x >> put y

-- Taken almost verbatim from QuickCheck's instance for (a, b)
-- instance Arbitrary a => Arbitrary (Vector2 a) where
--   arbitrary = liftA2 Vector2 arbitrary arbitrary
--   shrink (Vector2 x y) = [ Vector2 x' y | x' <- shrink x ] ++
--                          [ Vector2 x y' | y' <- shrink y ]

instance Ix a => Ix (Vector2 a) where
  range (start, stop) = uncurry (liftA2 Vector2) $ liftA2 (Prelude.curry range) start stop
  inRange (start, stop) = uncurry (&&) . liftA3 (Prelude.curry inRange) start stop
  index (Vector2 l t, Vector2 r b) (Vector2 x y) = (x' - l') * (b' + 1 - t') + y' - t'
    where
      (x', y', l', t', b') = (indexw x, indexh y, indexw l, indexh t, indexh b)
      indexw = index (l, r)
      indexh = index (t, b)

-- TODO: QuickCheck this:
prop_range :: Ix a => (Vector2 a, Vector2 a) -> Bool
prop_range r = map (index r) vectors == [0..length vectors-1]
  where
    vectors = range r

fst :: Vector2 a -> a
fst (Vector2 x _) = x

snd :: Vector2 a -> a
snd (Vector2 _ y) = y

swap :: Vector2 a -> Vector2 a
swap (Vector2 x y) = Vector2 y x

type Endo a = a -> a

first :: Endo a -> Endo (Vector2 a)
first f (Vector2 x y) = Vector2 (f x) y

second :: Endo a -> Endo (Vector2 a)
second f (Vector2 x y) = Vector2 x (f y)

infixr 3 ***
(***) :: (a -> b) -> (a -> b) -> Vector2 a -> Vector2 b
(f *** g) (Vector2 x y) = Vector2 (f x) (g y)

vector2 :: (a -> a -> b) -> Vector2 a -> b
vector2 f (Vector2 x y) = f x y

both :: (a -> b) -> Vector2 a -> Vector2 b
both = join (***)

zip :: [a] -> [a] -> [Vector2 a]
zip = zipWith Vector2

curry :: (Vector2 a -> b) -> a -> a -> b
curry f x y = f (Vector2 x y)

uncurry :: (a -> a -> b) -> Vector2 a -> b
uncurry f (Vector2 x y) = f x y

instance Functor Vector2 where
  fmap = both
instance Applicative Vector2 where
  pure x = Vector2 x x
  Vector2 f g <*> Vector2 x y = Vector2 (f x) (g y)

-- An improper Num instance, for convenience
instance (Eq a, Show a, Num a) => Num (Vector2 a) where
  (+) = liftA2 (+)
  (-) = liftA2 (-)
  (*) = liftA2 (*)
  abs = fmap abs
  negate = fmap negate
  signum = fmap signum
  fromInteger = pure . fromInteger
