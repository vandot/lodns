# Package

version       = "0.1.9"
author        = "vandot"
description   = "Simple DNS server for local development"
license       = "MIT"
srcDir        = "src"
bin           = @["lodns"]

binDir = "build"

installExt = @["nim"]

skipDirs = @[
  ".github",
]

# Dependencies
requires "nim >= 1.6.6"
requires "dnsprotocol"
requires "https://github.com/vandot/nim-sudo#head"

# Tasks
proc updateNimbleVersion(ver: string) =
  let fname = currentSourcePath()
  let txt = readFile(fname)
  var lines = txt.split("\n")
  for i, line in lines:
    if line.startsWith("version"): 
      let s = line.find('"')
      let e = line.find('"', s+1)
      lines[i] = line[0..s] & ver & line[e..<line.len]
      break
  writeFile(fname, lines.join("\n"))

task version, "update version":
  # last params as version
  let ver = paramStr( paramCount() )
  if ver == "version": 
    # print current version
    echo version
  else:
    withDir thisDir(): 
      updateNimbleVersion(ver)
