
import Foundation

// Newton 1.0 Connection Protocol / Dante Connection Protocol
//
// Documented by Newton Research http://newtonresearch.org/
//
// Newton communicates with the desktop by exchanging Newton event commands.
// The general command structure looks like this:
//
//   ULong 'newt'    // event header
//   ULong 'dock'    // event header
//   ULong 'aaaa'    // specific command
//   ULong length    // the length in bytes of the following data
//   UChar data[]    // data, if any
//
// NOTE
// • The length associated with each command is the actual length in bytes
//   of the data following the length field.
// • Data is padded with nulls to a 4 byte boundary.
// • Multi-byte values are in big-endian order.
// • Strings are null-terminated 2-byte UniChar strings unless otherwise specified.


public class DockPacketLayer {

    public enum DecodingError: Error {
        case invalidSize
        case invalidHeader
        case invalidCommand
        case invalidLength
    }


    private static let header = "newtdock".data(using: .ascii)!
    // 2 * header + command + length
    private static let minFieldCount = 4
    private static let boundary = 4
    private static let minDataCount = minFieldCount * boundary

    private static let allDockPacketTypes: [DecodableDockPacket.Type] = [
        RequestToDockPacket.self,
        NewtonNamePacket.self,
        NewtonInfoPacket.self,
        ResultPacket.self,
        PasswordPacket.self
    ]

    public init() {}

    private static let commands =
        Dictionary(uniqueKeysWithValues: allDockPacketTypes.map { ($0.command, $0) })

    private var rawData = Data()

    public func read(data additionalData: Data, handler: (DecodableDockPacket) -> Void) throws {

        rawData.append(additionalData)

        while !rawData.isEmpty {

            // check minimum data size
            guard rawData.count >= DockPacketLayer.minDataCount else {
                return
            }

            // check header
            let headerStartIndex = rawData.startIndex
            let headerEndIndex = headerStartIndex.advanced(by: DockPacketLayer.header.count)
            let header = rawData.subdata(in: headerStartIndex..<headerEndIndex)
            guard header == DockPacketLayer.header else {
                throw DecodingError.invalidHeader
            }

            // decode command
            let commandStartIndex = headerEndIndex
            let commandEndIndex = commandStartIndex.advanced(by: DockPacketLayer.boundary)
            let commandData = rawData.subdata(in: commandStartIndex..<commandEndIndex)
            guard
                let commandString = String(data: commandData, encoding: .ascii),
                let command = DockCommand(rawValue: commandString)
            else {
                throw DecodingError.invalidCommand
            }

            // decode data length
            let lengthStartIndex = commandEndIndex
            let lengthEndIndex = lengthStartIndex.advanced(by: DockPacketLayer.boundary)
            let lengthData = rawData.subdata(in: lengthStartIndex..<lengthEndIndex)
            guard
                let length = UInt32(bigEndianData: lengthData)
                    .map({ Int(DockPacketLayer.roundToBoundary(length: $0)) })
            else {
                throw DecodingError.invalidLength
            }

            let totalLength = DockPacketLayer.minDataCount + length
            guard rawData.count >= totalLength else {
                return
            }

            // decode data
            let dataStartIndex = lengthEndIndex
            let dataEndIndex = dataStartIndex.advanced(by: length)
            let packetData = rawData.subdata(in: dataStartIndex..<dataEndIndex)

            // decode
            if let dockPacket = try DockPacketLayer.decode(command: command, data: packetData) {
                handler(dockPacket)
            }

            // keep remaining data for next packet
            rawData = Data(rawData.subdata(in: dataEndIndex..<rawData.endIndex))
        }
    }

    private static func decode(command: DockCommand, data: Data) throws -> DecodableDockPacket? {
        return try commands[command]?.init(data: data)
    }

    private static func roundToBoundary(length: UInt32) -> UInt32 {
        let boundary = UInt32(DockPacketLayer.boundary)
        let remainder = length % boundary
        let padding = boundary - remainder
        return length + (remainder != 0 ? padding : 0)
    }

    public func write(packet: EncodableDockPacket) throws -> Data {
        var result = Data()
        result.append(DockPacketLayer.header)
        result.append(type(of: packet).command.rawValue.data(using: .ascii)!)

        if let data = packet.encode() {
            let length = UInt32(data.count)
            let roundedLength = DockPacketLayer.roundToBoundary(length: length)
            result.append(UInt32(roundedLength).bigEndianData)
            result.append(data)
            let padding = Int(roundedLength - length)
            if padding != 0 {
                result.append(Data(repeating: 0, count: padding))
            }
        }

        return result
    }
}
