{-# LANGUAGE BangPatterns #-}
module TclLib.MathProcs (mathProcs, plus, 
              minus,
	      times,
	      divide,
              procEql, procEq, procNe) where
import Common
import qualified TclObj as T
import Control.Monad
import System.Random

mathProcs = makeProcMap $
   [("+", many plus 0), ("*", many times 1), ("-", m2 minus), ("pow", m2 pow), 
    ("sin", onearg sin), ("cos", onearg cos), ("abs", onearg abs),
    ("eq", procEq), ("ne", procNe), ("sqrt", m1 squarert),
    ("/", m2 divide), ("<", lessThan),(">", greaterThan),("<=",lessThanEq), ("rand", procRand),
    ("srand", procSrand)]

procSrand args = case args of
 [v] -> mathSrand v
 []  -> tclErr "too few arguments to math function"
 _   -> tclErr "too many arguments to math function"

mathSrand v = do
 i <- T.asInt v 
 io (setStdGen (mkStdGen i))
 ret

procRand _ = mathRand

mathRand = io randomIO >>= return . T.mkTclDouble

onearg f = m1 inner
 where inner x = do
            d <- T.asDouble x
	    return (T.mkTclDouble (f d))
{-# INLINE onearg #-}

m1 f args = case args of
  [a] -> f a
  _     -> if length args > 1 then tclErr "too many arguments to math function" 
                              else tclErr "too few arguments to math function"
{-# INLINE m1 #-}

many !f !i args = case args of
  [a,b] -> f a b
  _ -> foldM f (T.mkTclInt i) args
{-# INLINE many #-}

m2 f args = case args of
  [a,b] -> f a b
  _     -> if length args > 2 then tclErr "too many arguments to math function" 
                              else tclErr "too few arguments to math function"
{-# INLINE m2 #-}

squarert x = do
    case T.asInt x of
      Just i -> return $! T.mkTclDouble (sqrt (fromIntegral i))
      Nothing -> do
        d1 <- T.asDouble x
	return $! T.mkTclDouble (sqrt d1)

plus x y = do
   case (T.asInt x, T.asInt y) of
       (Just i1, Just i2) -> return $! (T.mkTclInt (i1+i2))
       _ -> do 
           d1 <- T.asDouble x
           d2 <- T.asDouble y
	   return $! T.mkTclDouble (d1+d2)

pow x y = do
   case (T.asInt x, T.asInt y) of
       (Just i1, Just i2) -> return $! (T.mkTclInt (i1^i2))
       _ -> do 
           d1 <- T.asDouble x
           d2 <- T.asDouble y
	   return $! T.mkTclDouble (d1 ** d2)

minus x y = do
   case (T.asInt x, T.asInt y) of
       (Just i1, Just i2) -> return $! (T.mkTclInt (i1-i2))
       _ -> do 
           d1 <- T.asDouble x
           d2 <- T.asDouble y
	   return $! T.mkTclDouble (d1-d2)

times !x !y = do
   case (T.asInt x, T.asInt y) of
       (Just i1, Just i2) -> return $! (T.mkTclInt (i1*i2))
       _ -> do 
           d1 <- T.asDouble x
           d2 <- T.asDouble y
	   return $! T.mkTclDouble (d1*d2)

divide x y = do
   case (T.asInt x, T.asInt y) of
       (Just i1, Just i2) -> return $! (T.mkTclInt (i1 `div` i2))
       _ -> do 
           d1 <- T.asDouble x
           d2 <- T.asDouble y
	   return $! T.mkTclDouble (d1 / d2)

lessThan args = case args of
   [a,b] -> case tclCompare a b of
              LT -> return T.tclTrue
	      _  -> return T.tclFalse
   _     -> argErr "<"

lessThanEq args = case args of
   [a,b] -> case tclCompare a b of
	      GT  -> return T.tclFalse
              _   -> return T.tclTrue
   _     -> argErr "<="

greaterThan args = case args of
   [a,b] -> case tclCompare a b of
              GT -> return T.tclTrue
	      _  -> return T.tclFalse
   _     -> argErr ">"

procEql args = case args of
   [a,b] -> case tclCompare a b of
             EQ -> return T.tclTrue
	     _  -> return T.tclFalse
   _     -> argErr "=="

procEq args = case args of
   [a,b] -> return . T.fromBool $! (T.strEq a b)
   _     -> argErr "eq"

procNe args = case args of
   [a,b] -> return . T.fromBool $! (T.strNe a b)
   _     -> argErr "ne"

tclCompare a b =
  case (T.asInt a, T.asInt b) of
     (Just i1, Just i2) -> compare i1 i2
     _  -> case (T.asDouble a, T.asDouble b) of
                  (Just d1, Just d2) -> compare d1 d2
		  _ -> compare (T.asBStr a) (T.asBStr b)
{-# INLINE tclCompare #-}
