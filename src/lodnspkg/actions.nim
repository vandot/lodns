import std/[strutils]
when defined windows:
  import std/[osproc]
else:
  import std/[os, tempfiles]
  import pkg/[sudo]
when defined linux:
  import std/[osproc]

proc systemProbe*(): (string, int) =
  var ip = "127.0.0.1"
  var port = 5354
  when defined linux:
    var systemd = execProcess("ps --no-headers -o comm 1")
    var active = execProcess("systemctl is-active systemd-resolved.service")
    systemd.stripLineEnd
    active.stripLineEnd
    if systemd != "systemd" or active != "active":
      echo "linux initialization is supported only for systemd using systemd-resolved"
      quit(1)
    var version = execProcess("systemd --version | head -1 | awk '{ print $2}'")
    version.stripLineEnd
    # IPv4 dummy address (RFC7600)
    ip = "192.0.0.8"
    if parseInt(version) <= 245:
      port = 53
  when defined windows:
    port = 53
  return (ip, port)

proc install*(ip: string, port: int, tld: string) =
  when defined linux:
    let network = createTempFile("lodns_", "")
    var networkText: string
    if port == 53:
      networkText = "[Match]\nName=lodns0\n[Network]\nAddress=$#/32\nDomains= ~lo.\nDNS=$#\n" % [ip, ip]
    else:
      networkText = "[Match]\nName=lodns0\n[Network]\nAddress=$#/32\nDomains= ~lo.\nDNS=$#:$#\n"  % [ip, ip, $port]
    network.cfile.write networkText
    close(network.cfile)
    var exitCode = sudoCmd("install -m 644 " & network.path & " /etc/systemd/network/lodns0.network")
    if exitCode != 0:
      echo "creating file inside /etc/systemd/network dir failed with code " &
          $exitCode
      quit(1)
    removeFile(network.path)
    let netdev = createTempFile("lodns_", "")
    let netdevText = "[NetDev]\nName=lodns0\nKind=dummy\n"
    netdev.cfile.write netdevText
    close(netdev.cfile)
    exitCode = sudoCmd("install -m 644 " & netdev.path & " /etc/systemd/network/lodns0.netdev")
    if exitCode != 0:
      echo "creating file inside /etc/systemd/network dir failed with code " &
          $exitCode
      quit(1)
    removeFile(netdev.path)
    exitCode = sudoCmd("systemctl restart systemd-networkd.service")
    if exitCode != 0:
      echo "systemctl restart systemd-networkd.service failed with code " & $exitCode
      quit(1)

  when defined macosx:
    if not dirExists("/etc/resolver"):
      let exitCode = sudoCmd("mkdir -p /etc/resolver")
      if exitCode != 0:
        echo "creating /etc/resolver dir failed with code " &
            $exitCode
        quit(1)
    let text = "nameserver $#\nport $#\n" % [ip, $port]
    let resolver = createTempFile("lodns_", "")
    resolver.cfile.write text
    close(resolver.cfile)
    let exitCode = sudoCmd("mv " & resolver.path & " /etc/resolver/" & tld)
    if exitCode != 0:
      echo "creating file inside /etc/resolver dir failed with code " &
          $exitCode
      quit(1)

  when defined windows:
    let addCommand = "Powershell.exe -Command \"Add-DnsClientNrptRule -Namespace '.$#' -NameServers '$#'\"" % [tld, ip]
    let exitCode = execCmd(addCommand)
    if exitCode != 0:
      echo addCommand & " failed with code " & $exitCode
      quit(1)

proc uninstall*(tld: string) =
  when defined linux:
    var exitCode = sudoCmd("rm /etc/systemd/network/lodns0.network")
    if exitCode != 0:
      echo "removing /etc/systemd/network/lodns0.network failed with code " & $exitCode
      quit(1)
    exitCode = sudoCmd("rm /etc/systemd/network/lodns0.netdev")
    if exitCode != 0:
      echo "removing /etc/systemd/network/lodns0.netdev failed with code " & $exitCode
      quit(1)
    exitCode = sudoCmd("networkctl delete lodns0")
    if exitCode != 0:
      echo "networkctl delete lodns0 failed with code " & $exitCode
      quit(1)
    exitCode = sudoCmd("systemctl restart systemd-networkd.service")
    if exitCode != 0:
      echo "systemctl restart systemd-networkd.service failed with code " & $exitCode
      quit(1)

  when defined macosx:
    let exitCode = sudoCmd("rm -f /etc/resolver/" & tld)
    if exitCode != 0:
      echo "removing /etc/resolver/" & tld & " failed with code " & $exitCode
      quit(1)


  when defined windows:
    let removeCommand = "Powershell.exe -Command \"Get-DnsClientNrptRule | Where { $_.Namespace " & "-eq '.$#' } | Remove-DnsClientNrptRule -Force\"" % [tld]
    let exitCode = execCmd(removeCommand)
    if exitCode != 0:
      echo removeCommand & " failed with code " & $exitCode
      quit(1)
