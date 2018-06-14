{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Tonatona.Db
  -- ( run
  -- , Config(..)
  -- , Shared(..)
  -- , Tonatona.Db.init
  -- , TonaDbM
  -- , TonaDbConfig(..)
  -- , TonaDbShared(..)
  -- , runMigrate
  -- ) where
  where

import Control.Monad.Reader (ReaderT, reader)
import Data.ByteString (ByteString)
import Data.String (IsString)
import System.Envy (FromEnv(..), Var, (.!=), envMaybe)
import Tonatona (TonaM)
import UnliftIO (MonadUnliftIO)

type TonaDbM backend conf shared
  = ReaderT backend (TonaM conf shared)

{-| Main function.
 -}
run :: (TonaDbShared backend shared) => TonaDbM backend conf shared a -> TonaM conf shared a
run query = do
  f <- reader (runDb . shared . snd)
  f query

-- Config

newtype DbConnStr = DbConnStr
  { unDbConnStr :: ByteString
  } deriving newtype (Eq, IsString, Read, Show, Var)

newtype DbConnNum = DbConnNum { unDbConnNum :: Int }
  deriving newtype (Eq, Num, Read, Show, Var)

data Config = Config
  { dbConnString :: DbConnStr
  , dbConnNum :: DbConnNum
  }
  deriving (Show)

instance FromEnv Config where
  fromEnv =
    Config
      <$> envMaybe "TONA_DB_CONN_STRING" .!= "postgresql://myuser:mypass@localhost:5432/mydb"
      <*> envMaybe "TONA_DB_CONN_NUM" .!= 10

class TonaDbConfig config where
  config :: config -> Config

-- Shared

class TonaDbShared backend shared | shared -> backend where
  shared :: shared -> Shared backend

data Shared backend = Shared
  { runDb :: forall m a. MonadUnliftIO m => ReaderT backend m a -> m a
  }
