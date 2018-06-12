{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Tonatona.Sample
  ( app
  ) where

import Data.Semigroup ((<>))
import System.Envy (FromEnv(..))
import Servant
import Tonatona (Plug(..), TonaM)
import qualified Tonatona as Tona
import qualified Tonatona.IO as TonaIO
import Tonatona.Db (TonaDbConfig(..), TonaDbShared(..))
import qualified Tonatona.Db as TonaDb
import Tonatona.Environment (TonaEnvConfig(..))
import qualified Tonatona.Environment as TonaEnv
import qualified Tonatona.Servant as TonaServant
import Tonatona.Servant (TonaServantConfig(..))



type API =
  "foo" :> Get '[JSON] Int :<|>
  "bar" :> Get '[JSON] String

server :: ServerT API (TonaM Config Shared)
server = getFoo :<|> getBar

getFoo :: TonaM Config Shared Int
getFoo = pure 1

getBar :: TonaM Config Shared String
getBar = pure "bar"

app :: IO ()
app = TonaServant.run @Config @Shared @API server
  -- undefined
  -- TonaDb.run $
  --   TonaDb.migrate
  -- TonaIO.run $ \_conf shared' ->
  --   putStrLn $ "dbPool (" <> TonaDb.dbPool (TonaDb.shared shared') <> ") is shared"
  -- TonaDb.run $
  --   TonaDb.migrate


-- Config

data Config = Config
  { tonaDb :: TonaDb.Config
  , tonaEnv :: TonaEnv.Config
  , tonaServant :: TonaServant.Config
  }
  deriving (Show)

instance FromEnv Config where
  fromEnv = Config
    <$> fromEnv
    <*> fromEnv
    <*> fromEnv

instance TonaDbConfig Config where
  config = tonaDb

instance TonaEnvConfig Config where
  config = tonaEnv

instance TonaServantConfig Config where
  config = tonaServant


-- Shared


data Shared = Shared
  { tonaDb :: TonaDb.Shared
  }
  deriving (Show)

instance Plug Config Shared where
  init conf = Shared
    <$> TonaDb.init conf

instance TonaDbShared Shared where
  shared = tonaDb
