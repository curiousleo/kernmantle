{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE DerivingVia #-}

module Control.Arrow.Twine
  ( Product(..)
  , Tannen(..)
  , Twine(..)
  , TightTwine, LooseTwine
  , Strand, NamedStrand, TwineRec
  , StrandRunner(..)
  , tightenTwine, loosenTwine
  , type (~>)
  )
where

import Control.Category
import Control.Arrow

import Control.Monad.Reader
import Data.Bifunctor
import Data.Bifunctor.Tannen
import Data.Bifunctor.Product
import Data.Profunctor
import Data.Profunctor.Cayley
import Data.Functor.Identity  -- Needed by the deriving via machinery
import Data.Typeable
import Data.Vinyl hiding ((<+>))
import GHC.Exts
import GHC.TypeLits

import Prelude hiding (id, (.))


-- | The kind for all effects of arity 2
type Strand = * -> * -> *

-- | The kind for a type-level effect list
type NamedStrand = (Symbol, Strand)

-- | The kind for records that will contain 'StrandRunner's
type TwineRec = (NamedStrand -> *) -> [NamedStrand] -> *

type family Fst t where
  Fst '(a,b) = a
type family Snd t where
  Snd '(a,b) = b

-- | A natural transformation on type constructors of two arguments.
type f ~> g = forall x y. f x y -> g x y

-- | Runs one strand (* -> * -> * effect) in another
newtype StrandRunner (sup::Strand) (strand::NamedStrand) = StrandRunner
  { runStrand :: Snd strand ~> sup }

-- | 'Twine_' is a free arrow built out of _several_ arity 2 effects
-- (ie. effects with kind * -> * -> *). These effects are called 'Strand's, and
-- they can be interlaced "on top" of an existing arrow @sup@ (for "support").
--
-- Note that if @sup@ is maintained universally quantified, then this
-- corresponds to the final encoding of the free arrow construction.
newtype Twine (record::TwineRec) (strands::[NamedStrand]) (sup::Strand) a b =
  Twine { runTwine :: record (StrandRunner sup) strands -> sup a b }
  deriving (Category, Arrow, ArrowChoice, ArrowLoop, ArrowZero, ArrowPlus
           ,Bifunctor)
    via Reader (record (StrandRunner sup) strands) `Tannen` sup
  deriving (Profunctor, Strong, Choice)
    via Reader (record (StrandRunner sup) strands) `Cayley` sup
 
-- | A 'Twine' that is "tight", meaning you cannot add new 'Strand's to it
type TightTwine = Twine ARec

-- | A 'Twine' that is "loose", meaning that you can add new 'Strand's to it
type LooseTwine = Twine Rec

-- | Tells whether @strand@ is in a 'Twine'
type IsInTwine (record::TwineRec) (strands::[NamedStrand]) (sup::Strand) (strand::NamedStrand) =
  ( HasField record (Fst strand) strands strands (Snd strand) (Snd strand)
  , RecElemFCtx record (StrandRunner sup) )

tightenTwine :: LooseTwine s sup a b -> TightTwine s sup a b
tightenTwine = undefined

loosenTwine :: TightTwine s sup a b -> LooseTwine s sup a b
loosenTwine = undefined
