module Main (main) where
import System.Console.GetOpt
import System.Environment
import System.Exit
import Control.DeepSeq
import Control.Exception
import Control.Concurrent
import System.IO

import HCharselect.Gui
import HCharselect.Parser
import HCharselect.Concurrency
import HCharselect.CommonOptions

data GuiConfig = GuiConf { resizable :: Bool }

defaultGuiConfig = GuiConf True

guiOptions =
  commonOptions ++ [ Option [] ["resizable"] (NoArg (setOther $ setResizable)) "let the window be resizable" ]

setResizable :: GuiConfig -> GuiConfig
setResizable conf = conf {resizable = True}

parseOptsIO :: [String] -> CommonConfig a -> [CommonOptDesc a]
               -> IO (CommonConfig a)
parseOptsIO argv def opts = case parseOpts argv def opts of
    (c, [], [])  -> maybeShowHelp c opts "[OPTIONS]"
    (_, n, [])   -> ioError (userError $ "superfluous args: " ++ concat n)
    (_, _, errs) -> ioError (userError $ concat errs)

main = do
  args <- getArgs
  
  conf <- parseOptsIO args (defaultConfig defaultGuiConfig) guiOptions

  chars <- newEmptyMVar
  forkIO $ parseThread chars (dataFile conf)
  gui chars (resizable $ other conf)
