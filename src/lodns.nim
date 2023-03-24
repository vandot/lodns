import std/[os, parseopt]
# Internal imports
import ./lodnspkg/[actions, server]

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
  var
    ip :string
    port :int

  for kind, key, value in getOpt():
    case kind
    of cmdArgument:
      case key
      of "install":
        (ip, port) = systemProbe()
        install(ip, port, tld)
      of "start":
        (ip, port) = systemProbe()
        serve(ip, port, tld)
      of "uninstall":
        uninstall(tld)
      else:
        echo "unknown argument: ", key
        writeHelp()
    of cmdLongOption, cmdShortOption:
      case key
      of "v", "version":
        writeVersion()
      of "h", "help":
        writeHelp()
      else:
        echo "unknown option: ", key
        writeHelp()
    of cmdEnd:
      discard

when isMainModule:
  main()
