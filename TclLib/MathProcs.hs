{-# LANGUAGE BangPatterns #-}
module TclLib.MathProcs (mathCmds, 
        plus, 
        minus,
        times,
        divide,
        equals,
        notEquals,
        lessThan,
        lessThanEq,
        greaterThan,
        greaterThanEq,
	mathTests ) where

import Common
import qualified TclObj as T
import Control.Monad
import System.Random
import Test.HUnit

mathCmds = makeCmdList $
   [("+", many plus 0), ("*", many times 1), ("-", m2 minus), ("pow", m2 pow), 
    ("sin", onearg sin), ("cos", onearg cos), ("abs", m1 absfun), ("double", onearg id),
    ("eq", procEq), ("ne", procNe), ("sqrt", m1 squarert), 
    ("==", procEql), ("!=", procNotEql), 
    ("/", m2 divide), ("<", lessThanProc),(">", greaterThanProc),
    mkcmd ">=" greaterThanEq, ("<=",lessThanEqProc), 
    ("rand", procRand), ("srand", procSrand),
    ("!", procNot)]

mkcmd n f = (n,inner)
 where inner args = case args of
                     [a,b] -> return $! f a b
                     _     -> argErr n

procSrand args = case args of
 [v] -> mathSrand v
 []  -> tclErr "too few arguments to math function"
 _   -> tclErr "too many arguments to math function"

mathSrand v = do
 i <- T.asInt v 
 io (setStdGen (mkStdGen i))
 ret

procRand _ = mathRand

mathRand = io randomIO >>= return . T.fromDouble

onearg f = m1 inner
 where inner x = do
            d <- T.asDouble x
	    return (T.fromDouble (f d))
{-# INLINE onearg #-}

absfun x = case T.asInt x of
            Nothing -> do d <- T.asDouble x
                          return (T.fromDouble (abs d))
            Just i  -> return (T.fromInt (abs i))

m1 f args = case args of
  [a] -> f a
  _     -> if length args > 1 then tclErr "too many arguments to math function" 
                              else tclErr "too few arguments to math function"
{-# INLINE m1 #-}

many !f !i args = case args of
  [a,b] -> f a b
  _ -> foldM f (T.fromInt i) args
{-# INLINE many #-}

m2 f args = case args of
  [a,b] -> f a b
  _     -> if length args > 2 then tclErr "too many arguments to math function" 
                              else tclErr "too few arguments to math function"
{-# INLINE m2 #-}

procNot args = case args of
  [x] -> return $! T.fromBool . not . T.asBool $ x
  _   -> argErr "!"

squarert x = do
    case T.asInt x of
      Just i -> return $! T.fromDouble (sqrt (fromIntegral i))
      Nothing -> do
        d1 <- T.asDouble x
	return $! T.fromDouble (sqrt d1)

data NPair = Ints !Int !Int | Doubles !Double !Double deriving (Eq,Show)

-- TODO: Inline getNumerics manually and get rid of NPair?
getNumerics :: (T.ITObj t) => t -> t -> Maybe NPair
getNumerics !x !y =
   case (T.asInt x, T.asInt y) of
       (Just i1, Just i2) -> return $! Ints i1 i2
       _ -> case (T.asDouble x, T.asDouble y) of
               (Just d1, Just d2) -> return $! Doubles d1 d2
               _ -> fail $ "expected numeric"
{-# INLINE getNumerics #-}

numop name iop dop !x !y = 
   case getNumerics x y of
       Just (Ints i1 i2)  -> return $! (T.fromInt (i1 `iop` i2))
       Just (Doubles d1 d2) -> return $! T.fromDouble (d1 `dop` d2)
       _ -> fail $ "can't use non-numeric string as operand of " ++ show name
{-# INLINE numop #-}

plus, minus, times, divide :: (Monad m, T.ITObj t) => t -> t -> m t
plus = numop "+" (+) (+) 
minus = numop "-" (-) (-)
times = numop "*" (*) (*)
divide = numop "/" div (/)


pow x y = do
   case (T.asInt x, T.asInt y) of
       (Just i1, Just i2) -> return $! (T.fromInt (i1^i2))
       _ -> do 
           d1 <- T.asDouble x
           d2 <- T.asDouble y
	   return $! T.fromDouble (d1 ** d2)


lessThan a b = T.fromBool $! (tclCompare a b == LT)

lessThanProc args = case args of
   [a,b] -> return $! lessThan a b
   _     -> argErr "<"

lessThanEq a b = T.fromBool $! (tclCompare a b /= GT)

lessThanEqProc args = case args of
   [a,b] -> return $! (lessThanEq a b)
   _     -> argErr "<="

greaterThan a b = T.fromBool $! (tclCompare a b == GT)

greaterThanProc args = case args of
   [a,b] -> return $! greaterThan a b
   _     -> argErr ">"

greaterThanEq a b = T.fromBool $! (tclCompare a b  /= LT)

equals a b = T.fromBool $! (tclCompare a b == EQ)

procEql args = case args of
   [a,b] -> return $! (equals a b)
   _     -> argErr "=="

notEquals a b = T.fromBool $! (tclCompare a b /= EQ)

procNotEql args = case args of
      [a,b] -> case (T.asInt a, T.asInt b) of
                  (Just ia, Just ib) -> return $! T.fromBool (ia /= ib)
                  _                  -> procNe [a,b]
      _     -> argErr "!="

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

-- # TESTS # --


testProcEq = TestList [
      "1 eq 1 -> t" ~:          (procEq [int 1, int 1]) `is` True
      ,"1 == 1 -> t" ~:         (procEql [int 1, int 1]) `is` True
      ,"' 1 ' == 1 -> t" ~:     procEql [str " 1 ", int 1] `is` True
      ,"' 1 ' eq 1 -> f" ~:     procEq [str " 1 ", int 1] `is` False
      ,"' 1 ' eq ' 1 ' -> t" ~: procEq [str " 1 ", str " 1 "] `is` True
      ,"' 1 ' ne '1' -> t" ~: procNe [str " 1 ", str "1"] `is` True
      ,"'cats' eq 'cats' -> t" ~: procEq [str "cats", str "cats"] `is` True
      ,"'cats' eq 'caps' -> f" ~: procEq [str "cats", str "caps"] `is` False
      ,"'cats' ne 'cats' -> t" ~: procNe [str "cats", str "cats"] `is` False
      ,"'cats' ne 'caps' -> f" ~: procNe [str "cats", str "caps"] `is` True
   ]
 where (?=?) a b = assert (runCheckResult b (Right a))
       is c b = (T.fromBool b) ?=? c
       int :: Int -> T.TclObj
       int i = T.fromInt i
       str s = T.mkTclStr s

mathTests = TestList [ testProcEq ]

-- # ENDTESTS # --
