{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Control.Monad.Reader (runReaderT)
import           Control.RateLimit    (RateLimit)
import           Data.Time.Units      (Millisecond)
import           Turtle

import           Checkpoint           (GethId(..))
import           Cluster              (mkLocalEnv)
import           Cluster.Client       (loadLocalNode, spamGeth, perSecond)

cliParser :: Parser (GethId, RateLimit Millisecond)
cliParser = (,) <$> gethIdP <*> rateLimitP
  where
    gethIdP = GethId <$>
      optInt     "geth" 'g' "The Geth ID of the local node to spam"
    rateLimitP = perSecond <$>
      optInteger "rps"  'r' "The number of requests per second"

main :: IO ()
main = do
    (gid, rateLimit) <- options "Local geth spammer" cliParser
    geth <- runReaderT (loadLocalNode gid) (mkLocalEnv maxClusterSize)
    spamGeth geth rateLimit

  where
    -- We don't need the exact cluster size here; just something higher than the
    -- geth ID we want to spam.
    maxClusterSize = 10