import std/[os, parseopt]
# Internal imports
import ./lodns/[actions, server]

const tld = "lo"

proc writeVersion() =
  const NimblePkgVersion {.strdefine.} = "dev"
  echo getAppFilename().extractFilename(), "-", NimblePkgVersion

proc writeHelp() =
  writeVersion()
  echo """
  Run local DNS server that returns 127.0.0.1 or ::1
  for every query with lo TLD.

  install       : install system files
  uninstall     : uninstall system files
  start         : start service
  -h, --help    : show help
  -v, --version : show version
  """
  quit()

proc main() =
  var install, start, uninstall = false
  var
    ip :string
    port :int

  for kind, key, value in getOpt():
    case kind
    of cmdArgument:
      case key
      of "install":
        install = true
      of "start":
        start = true
      of "uninstall":
        uninstall = true
      else:
        echo "unknown argument: ", key
    of cmdLongOption, cmdShortOption:
      case key
      of "v", "version":
        writeVersion()
        quit()
      of "h", "help":
        writeHelp()
      else:
        echo "unknown option: ", key
    of cmdEnd:
      discard

  if install or start:
    (ip, port) = systemProbe()
  if install:
    install(ip, port, tld)
  if uninstall:
    uninstall(tld)
  if start:
    serve(ip, port, tld)
  else:
    writeHelp()

when isMainModule:
  main()
