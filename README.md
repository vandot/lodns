# lodns
lodns is a simple DNS server intended for local development.

Obsoletes editing hosts file or manually installing and configuring dnsmasq.

It is designed to respond to DNS queries for all subdomains of `.lo` TLD.

Supports both IPv4 and IPv6, lodns will respond accordingly to DNS queries, to A queries with 127.0.0.1 and to AAAA queries with ::1.

lodns will act only as a secondary DNS server dedicated to `.lo` TLD on every platform. For all other DNS queries still will be used default system DNS.

## Installation
Download correct binary from the latest [release](https://github.com/vandot/lodns/releases) and place it somewhere in the PATH.

Or `nimble install https://github.com/vandot/lodns`

*Note: lodns support for Linux relies on systemd and systemd-resolved*

## Configuration
lodns comes preconfigured for all supported platforms to act as a secondary DNS server quired only for `.lo` domain.

On MacOS and Linux you have to run with `sudo` to be able to configure the system
```
sudo lodns install
```
On Windows run inside elevated command prompt or Powershell
```
lodns.exe install
```

## Start
On Windows and Linux with systemd version <= 245 `lodns` has to run on a well-known port `53` and service has to be started with elevated priviledges.
On MacOS and Linux (systemd > 245)
```
lodns start
```
On Linux (systemd <=245)
```
sudo lodns start
```
On Windows inside elevated command prompt or Powershell
```
lodns.exe start
```

## Test lodns
Using `dig` or `ping` you can test lodns
```
$ dig +short @127.0.0.1 -p 5354 A test.lo
127.0.0.1

$ dig +short @127.0.0.1 -p 5354 AAAA test.lo
::1

$ ping test.lo
PING test.lo (127.0.0.1): 56 data bytes
64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.057 ms
```

## Uninstallation
On MacOS and Linux run 
```
sudo lodns uninstall
```
On Windows run inside elevated command prompt or Powershell
```
lodns.exe uninstall
```
and remove the binary.

## License

BSD 3-Clause License
