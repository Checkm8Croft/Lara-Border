import os, osproc, parseopt, strutils

proc printHelp() =
  echo "Tomb Raider Custom Level Launcher"
  echo "Usage:"
  echo "  launcher.exe -g:<path_to_tomb4.exe> [-s:<path_to_file.sdb>]"
  echo ""
  echo "Options:"
  echo "  -g, --game: Path to the tomb4.exe file (Required)"
  echo "  -s, --sdb: Path to the .sdb fix file (Optional, defaults to TR-borderless.sdb)"
  echo "  -h, --help: Displays this help message"

proc launchGame(exePath: string, customSdbPath: string) =
  # 1. Validate game executable path
  if not fileExists(exePath):
    echo "[Error] Game executable not found at: ", exePath
    quit(1)

  # 2. Extract the working directory of the game
  let gameDir = parentDir(exePath)

  # 3. Determine the SDB file path
  var sdbPath = customSdbPath
  
  # If no custom SDB was passed via CLI, look for "TR-borderless.sdb" next to the launcher
  if sdbPath.len == 0:
    let defaultSdb = joinPath(getAppDir(), "TR-borderless.sdb")
    if fileExists(defaultSdb):
      sdbPath = defaultSdb

  # 4. Apply SDB compatibility fix if found
  if sdbPath.len > 0:
    if fileExists(sdbPath):
      echo "[Info] Applying SDB compatibility database: ", sdbPath
      let sdbCmd = "sdbinst.exe -q \"" & sdbPath & "\""
      let sdbResult = execShellCmd(sdbCmd)
      
      if sdbResult == 0:
        echo "[Success] SDB fix applied successfully."
      else:
        echo "[Warning] Failed to apply SDB fix. Ensure you are running with Administrator privileges."
    else:
      echo "[Warning] SDB file not found at: ", sdbPath

  # 5. Change current working directory to the game folder (critical for TR4 / TRNG assets)
  echo "[Info] Setting working directory to: ", gameDir
  setCurrentDir(gameDir)

  # 6. Launch the game executable
  echo "[Info] Launching game..."
  let process = startProcess(exePath, workingDir = gameDir)
  
  discard waitForExit(process)
  echo "[Info] Game session ended."

when isMainModule:
  var gamePath = ""
  var sdbPath = ""

  var p = initOptParser()
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      case p.key.toLowerAscii()
      of "g", "game": gamePath = p.val
      of "s", "sdb": sdbPath = p.val
      of "h", "help":
        printHelp()
        quit(0)
    of cmdArgument:
      if gamePath.len == 0:
        gamePath = p.key

  if gamePath.len == 0:
    echo "[Error] No game executable specified.\n"
    printHelp()
    quit(1)

  launchGame(gamePath, sdbPath)