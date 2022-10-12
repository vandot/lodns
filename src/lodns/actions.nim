import std/[os, strutils]
when defined linux:
  import std/[osproc]
when defined windows:
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
      quit()
    var version = execProcess("systemd --version | head -1 | awk '{ print $2}'")
    version.stripLineEnd
    ip = "169.254.1.1"
    if parseInt(version) <= 245:
      port = 53
  when defined windows:
    port = 53
  return (ip, port)

proc install*(ip: string, port: int, tld: string) =
  when defined linux:
    if port == 53:
      let networkText = "[Match]\nName=lodns0\n[Network]\nAddress=$#/32\nDomains= ~lo.\nDNS=$#\n" % [ip, ip]
      writeFile("/etc/systemd/network/lodns0.network", networkText)
    else:
      let networkText = "[Match]\nName=lodns0\n[Network]\nAddress=$#/32\nDomains= ~lo.\nDNS=$#:$#\n"  % [ip, ip, $port]
      writeFile("/etc/systemd/network/lodns0.network", networkText)
    let netdevText = "[NetDev]\nName=lodns0\nKind=dummy\n"
    writeFile("/etc/systemd/network/lodns0.netdev", netdevText)
    var exitCode = execCmd("systemctl restart systemd-networkd.service")
    if exitCode != 0:
      echo "systemctl restart systemd-networkd.service failed with code " & $exitCode

  when defined macosx:
    if not dirExists("/etc/resolver"):
      createDir("/etc/resolver")
    let text = "nameserver $#\nport $#\n" % [ip, $port]
    writeFile("/etc/resolver/" & tld, text)

  when defined windows:
    var addCommand = "Powershell.exe -Command \"Add-DnsClientNrptRule -Namespace '.$#' -NameServers '$#'\"" % [tld, ip]
    var exitCode = execCmd(addCommand)
    if exitCode != 0:
      echo addCommand & " failed with code " & $exitCode
  quit()

proc uninstall*(tld: string) =
  when defined linux:
    removeFile("/etc/systemd/network/lodns0.network")
    removeFile("/etc/systemd/network/lodns0.netdev")
    var exitCode = execCmd("networkctl delete lodns0")
    if exitCode != 0:
      echo "networkctl delete lodns0 failed with code " & $exitCode
    exitCode = execCmd("systemctl restart systemd-networkd.service")
    if exitCode != 0:
      echo "systemctl restart systemd-networkd.service failed with code " & $exitCode

  when defined macosx:
    removeFile("/etc/resolver/" & tld)

  when defined windows:
    var removeCommand = "Powershell.exe -Command \"Get-DnsClientNrptRule | Where { $_.Namespace " & "-eq '.$#' } | Remove-DnsClientNrptRule -Force\"" % [tld]
    var exitCode = execCmd(removeCommand)
    if exitCode != 0:
      echo removeCommand & " failed with code " & $exitCode
  quit()
