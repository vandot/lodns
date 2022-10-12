import std/[net, logging, asyncnet, strutils, asyncdispatch]
import pkg/[dnsprotocol]

proc serve*(ip: string, port: int, tld: string) =
    var logger = newConsoleLogger(fmtStr="[$datetime] $levelname ")
    const withSize = 500
    var rr :ResourceRecord
    var socket = newAsyncSocket(sockType = SOCK_DGRAM, protocol = IPPROTO_UDP)

    socket.bindAddr(address = ip, port = Port port)
    logger.log(lvlInfo, "status=listening ip=", ip, " port=", port)
    while true:
        let request = waitfor socket.recvFrom(withSize)
        let message = parseMessage(request.data)
        let domain = message.questions[0].qname
        case message.questions[0].qtype
        of QType.A:
            logger.log(lvlInfo, "type=A domain=", domain)
            rr = initResourceRecord(domain, Type.A, Class.IN, 299'i32, 4'u16,
                                RDataA(address: [127'u8, 0, 0, 1]))
        of QType.AAAA:
            logger.log(lvlInfo, "type=AAAA domain=", domain)
            rr = initResourceRecord(domain, Type.AAAA, Class.IN, 299'i32, 16'u16,
                                RDataAAAA(address: [0'u8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]))
        else:
            logger.log(lvlError, "type=", message.questions[0].qtype, " domain=", domain, " error=unsupported-type")
            rr = initResourceRecord(domain, Type.NULL, Class.IN, 0'i32, 0'u16, RDataNULL())
        if rsplit(domain, ".", maxsplit=2)[1] != tld:
            logger.log(lvlError, "type=", message.questions[0].qtype, " domain=", domain, " error=unsupported-domain")
            rr = initResourceRecord(domain, Type.NULL, Class.IN, 0'i32, 0'u16, RDataNULL())
        let header = initHeader(message.header.id, QR.Response)
        let reply = initMessage(header, message.questions, @[rr])
        let bmsg = toBinMsg(reply)
        waitfor socket.sendTo(request.address, request.port, bmsg)
