import Foundation
import XCTest
@testable import NewtonKit

extension Data {
    var debugDescription: String {
        return map { String(format: "%x", $0) }
            .joined(separator: ", ")
    }
}

class NewtonKitTests: XCTestCase {

    func testPacketLayerReadRequest() throws {

        let layer = MNPPacketLayer()
        let data = Data(bytes: [
            0x16, 0x10, 0x2,  // start sequence

            // header
            0x26,  // length of header
            0x1,  // type = LR
            0x2,  // constant parameter 1
            0x1, 0x6, 0x1, 0x0, 0x0, 0x0, 0x0, 0xff,  // constant parameter 2
            0x2, 0x1, 0x2,  // framing mode = 0x2
            0x3, 0x1, 0x8,  // max outstanding LT frames = 0x8
            0x4, 0x2, 0x40, 0x0,  // max info length = 64
            0x8, 0x1, 0x3,  // max info length 256 enabled, fixed field LT and LA frames enabled

            // other information
            0x9, 0x1, 0x1, 0xe, 0x4, 0x3, 0x4, 0x0, 0xfa, 0xc5, 0x6, 0x1, 0x4, 0x0, 0x0, 0xe1, 0x0,

            0x10, 0x3, 0xb9, 0xbf  // end sequence with CRC
        ])

        var readPacket: MNPPacket?

        layer.onRead = {
            guard readPacket == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket = $0
        }
        try layer.read(data: data)

        guard let packet = readPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssert(packet is MNPLinkRequestPacket)
    }

    func testPacketLayerReadTransfer() throws {

        let layer = MNPPacketLayer()
        let data = Data(bytes: [
            0x16, 0x10, 0x02, 0x02, 0x04, 0x02, 0x6e, 0x65,
            0x77, 0x74, 0x64, 0x6f, 0x63, 0x6b, 0x6e, 0x61,
            0x6d, 0x65, 0x00, 0x00, 0x00, 0x5a, 0x00, 0x00,
            0x00, 0x38, 0xee, 0xe6, 0x53, 0x96, 0x01, 0x00,
            0x00, 0x00, 0x00, 0x72, 0x63, 0x77, 0x00, 0x02,
            0x00, 0x01, 0x00, 0x00, 0x80, 0x00, 0x00, 0x10,
            0x10, 0x00, 0x00, 0x00, 0x00, 0x01, 0x40, 0x00,
            0x00, 0x00, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x01, 0x1c, 0xe3, 0xa4, 0x1d, 0x00,
            0x00, 0x00, 0x55, 0x00, 0x00, 0x00, 0x55, 0x00,
            0x00, 0x00, 0x01, 0x00, 0x42, 0x00, 0x61, 0x00,
            0x73, 0x00, 0x74, 0x00, 0x69, 0x00, 0x61, 0x00,
            0x6e, 0x00, 0x20, 0x00, 0x4d, 0x00, 0xfc, 0x00,
            0x6c, 0x00, 0x6c, 0x00, 0x65, 0x00, 0x72, 0x00,
            0x00, 0x00, 0x00, 0x10, 0x03, 0xf6, 0xc9
        ])

        var readPacket: MNPPacket?

        layer.onRead = {
            guard readPacket == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket = $0
        }
        try layer.read(data: data)

        guard let packet = readPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssert(packet is MNPLinkTransferPacket)
    }

    func testPacketLayerWrite() {
        let layer = MNPPacketLayer()
        let data = Data(bytes: [0xF0, 0xF1, 0xF2, .DLE, 0xF3, 0xF4])
        let result = layer.write(data: data)
        let expected = Data(bytes: [
            0x16, 0x10, 0x02,  // start sequence
            0xF0, 0xF1, 0xF2, .DLE, .DLE, 0xF3, 0xF4,  // data, with escaped DLE
            0x10, 0x03, 0x2e, 0xc9  // end sequence with CRC
        ])
        XCTAssertEqual(result as NSData, expected as NSData)
    }

    func testLinkRequestPacket() throws {

        let initialData = Data(bytes: [
            0x2,  // constant parameter 1
            0x1, 0x6, 0x1, 0x0, 0x0, 0x0, 0x0, 0xff,  // constant parameter 2
            0x2, 0x1, 0x2,  // framing mode = 0x2
            0x3, 0x1, 0x8,  // max outstanding LT frames = 0x8
            0x4, 0x2, 0x40, 0x0,  // max info length = 64
            0x8, 0x1, 0x3,  // max info length 256 enabled, fixed field LT and LA frames enabled
        ])

        let linkRequestPacket = try MNPLinkRequestPacket(data: initialData)

        XCTAssertEqual(linkRequestPacket.maxOutstandingLTFrameCount, 0x8)
        XCTAssertEqual(linkRequestPacket.maxInfoLength, 64)
        XCTAssertTrue(linkRequestPacket.maxInfoLength256)
        XCTAssertTrue(linkRequestPacket.fixedFieldLTAndLAFrames)

        let expectedEncoding = Data(bytes: [
            // header
            0x17, // length of header = 23
            0x1,  // type = LR
            0x2,  // constant parameter 1
            0x1, 0x6, 0x1, 0x0, 0x0, 0x0, 0x0, 0xff,  // constant parameter 2
            0x2, 0x1, 0x2,  // framing mode = 0x2
            0x3, 0x1, 0x8,  // max outstanding LT frames = 0x8
            0x4, 0x2, 0x40, 0x0,  // max info length = 64
            0x8, 0x1, 0x3  // max info length 256 enabled, fixed field LT and LA frames enabled
        ])

        XCTAssertEqual(linkRequestPacket.encode(), expectedEncoding)
    }

    func testCRC() {
        XCTAssertEqual(crc16(input: [UInt8]("123456789".utf8)), 0xbb3d)
        XCTAssertEqual(crc16(input: [UInt8]("ZYX".utf8)), 0xb91b)
        XCTAssertEqual(crc16(input: [
            0x02, 0x04, 0x02, 0x6e, 0x65, 0x77, 0x74, 0x64,
            0x6f, 0x63, 0x6b, 0x6e, 0x61, 0x6d, 0x65, 0x00,
            0x00, 0x00, 0x5a, 0x00, 0x00, 0x00, 0x38, 0xee,
            0xe6, 0x53, 0x96, 0x01, 0x00, 0x00, 0x00, 0x00,
            0x72, 0x63, 0x77, 0x00, 0x02, 0x00, 0x01, 0x00,
            0x00, 0x80, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00,
            0x00, 0x01, 0x40, 0x00, 0x00, 0x00, 0xf0, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x1c,
            0xe3, 0xa4, 0x1d, 0x00, 0x00, 0x00, 0x55, 0x00,
            0x00, 0x00, 0x55, 0x00, 0x00, 0x00, 0x01, 0x00,
            0x42, 0x00, 0x61, 0x00, 0x73, 0x00, 0x74, 0x00,
            0x69, 0x00, 0x61, 0x00, 0x6e, 0x00, 0x20, 0x00,
            0x4d, 0x00, 0xfc, 0x00, 0x6c, 0x00, 0x6c, 0x00,
            0x65, 0x00, 0x72, 0x00, 0x00, 0x00, 0x00,
            0x03
        ]), 0xC9F6)
    }

    func testDockLayerReadRequestToDockPacket() throws {

        let initialData = Data(bytes: [
            0x6e, 0x65, 0x77, 0x74,
            0x64, 0x6f, 0x63, 0x6b,
            0x72, 0x74, 0x64, 0x6b,
            0x00, 0x00, 0x00, 0x04,
            0x00, 0x00, 0x00, 0x09
        ])

        let layer = DockPacketLayer()

        var readPacket: DecodableDockPacket?

        layer.onRead = {
            guard readPacket == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket = $0
        }
        try layer.read(data: initialData)

        guard let packet = readPacket as? RequestToDockPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssertEqual(packet,
                       RequestToDockPacket(protocolVersion: 9))
        XCTAssertEqual(try layer.write(packet: packet), initialData)
    }

    func testDockLayerReadResultPacket() throws {

        let initialData = Data(bytes: [
            0x6e, 0x65, 0x77, 0x74,
            0x64, 0x6f, 0x63, 0x6b,
            0x64, 0x72, 0x65, 0x73,
            0x00, 0x00, 0x00, 0x04,
            0x00, 0x00, 0x00, 0x00
        ])

        let layer = DockPacketLayer()

        var readPacket: DecodableDockPacket?

        layer.onRead = {
            guard readPacket == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket = $0
        }
        try layer.read(data: initialData)

        guard let packet = readPacket as? ResultPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssertEqual(packet,
                       ResultPacket(errorCode: 0))
        XCTAssertEqual(try layer.write(packet: packet), initialData)
    }

    func testDockLayerReadPartial() throws {

        let parts: [Data] = [
            Data(bytes: [0x6e, 0x65]),
            Data(bytes: [0x77, 0x74]),
            Data(bytes: [0x64, 0x6f, 0x63]),
            Data(bytes: [0x6b, 0x64, 0x72, 0x65, 0x73, 0x00, 0x00, 0x00]),
            Data(bytes: [0x04, 0x00, 0x00]),
            Data(bytes: [0x00, 0x00, 0x6e, 0x65, 0x77]),
            Data(bytes: [0x74, 0x64, 0x6f, 0x63, 0x6b, 0x64, 0x72]),
            Data(bytes: [0x65, 0x73, 0x00, 0x00, 0x00, 0x04, 0x00]),
            Data(bytes: [0x00, 0x00, 0x01])
        ]

        let layer = DockPacketLayer()

        layer.onRead = { _ in
            XCTFail("Packet was decoded")
        }
        for part in parts[0..<5] {
            try layer.read(data: part)
        }

        var readPacket1: DecodableDockPacket?

        layer.onRead = {
            guard readPacket1 == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket1 = $0
        }
        for part in parts[5..<8] {
            try layer.read(data: part)
        }

        guard let packet1 = readPacket1 as? ResultPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssertEqual(packet1,
                       ResultPacket(errorCode: 0))


        var readPacket2: DecodableDockPacket?

        layer.onRead = {
            guard readPacket2 == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket2 = $0
        }
        try layer.read(data: parts.last!)

        guard let packet2 = readPacket2 as? ResultPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssertEqual(packet2,
                       ResultPacket(errorCode: 1))
    }

    func testDES() throws {
        let cipher = try DES(keyBytes: [0xe4, 0x0f, 0x7e, 0x9f, 0x0a, 0x36, 0x2c, 0xfa])
        XCTAssertEqual(cipher.subkeys, [
            1941816532332429047,
            3187698850721185784,
            14629649794741350207,
            2552379178741254125,
            10907857884915252627,
            925659938082994879,
            5698161420098400218,
            8738098074673864543,
            11752688268146924526,
            15095317179288608183,
            8487308217601440611,
            12601211940932366813,
            9731146212525264767,
            1318866358298834551,
            2127386486980629434,
            13864349024495151355
        ])
        let unencrypted = Data(bytes: [0xff, 0x8d, 0xaa, 0xb8, 0x00, 0x20, 0x41, 0xd5])
        let encrypted = cipher.encrypt(source: unencrypted)
        let expected = Data(bytes: [0xf6, 0xeb, 0xa1, 0x37, 0xf3, 0x69, 0x9e, 0xa5])
        XCTAssertEqual(encrypted, expected)
    }

    func testNSOF1() throws {

        let data = Data(bytes: [
            0x02, 0x06, 0x02, 0x07, 0x08, 0x50, 0x61, 0x63,
            0x6b, 0x61, 0x67, 0x65, 0x73, 0x07, 0x06, 0x73,
            0x74, 0x6f, 0x72, 0x65, 0x73, 0x0a, 0x05, 0x01,
            0x06, 0x0c, 0x07, 0x04, 0x6e, 0x61, 0x6d, 0x65,
            0x07, 0x09, 0x73, 0x69, 0x67, 0x6e, 0x61, 0x74,
            0x75, 0x72, 0x65, 0x07, 0x09, 0x54, 0x6f, 0x74,
            0x61, 0x6c, 0x53, 0x69, 0x7a, 0x65, 0x07, 0x08,
            0x55, 0x73, 0x65, 0x64, 0x53, 0x69, 0x7a, 0x65,
            0x07, 0x04, 0x6b, 0x69, 0x6e, 0x64, 0x07, 0x04,
            0x69, 0x6e, 0x66, 0x6f, 0x07, 0x08, 0x72, 0x65,
            0x61, 0x64, 0x4f, 0x6e, 0x6c, 0x79, 0x07, 0x0d,
            0x73, 0x74, 0x6f, 0x72, 0x65, 0x70, 0x61, 0x73,
            0x73, 0x77, 0x6f, 0x72, 0x64, 0x07, 0x0c, 0x64,
            0x65, 0x66, 0x61, 0x75, 0x6c, 0x74, 0x53, 0x74,
            0x6f, 0x72, 0x65, 0x07, 0x0c, 0x73, 0x74, 0x6f,
            0x72, 0x65, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6f,
            0x6e, 0x07, 0x05, 0x73, 0x6f, 0x75, 0x70, 0x73,
            0x07, 0x0a, 0x73, 0x69, 0x67, 0x6e, 0x61, 0x74,
            0x75, 0x72, 0x65, 0x73, 0x08, 0x12, 0x00, 0x49,
            0x00, 0x6e, 0x00, 0x74, 0x00, 0x65, 0x00, 0x72,
            0x00, 0x6e, 0x00, 0x61, 0x00, 0x6c, 0x00, 0x00,
            0x00, 0xff, 0x73, 0x8e, 0x90, 0x74, 0x00, 0xff,
            0x00, 0x55, 0x1a, 0x00, 0x00, 0xff, 0x00, 0x4c,
            0xa5, 0x80, 0x08, 0x12, 0x00, 0x49, 0x00, 0x6e,
            0x00, 0x74, 0x00, 0x65, 0x00, 0x72, 0x00, 0x6e,
            0x00, 0x61, 0x00, 0x6c, 0x00, 0x00, 0x0a, 0x0a,
            0x0a, 0x00, 0x1a, 0x00, 0x10, 0x05, 0x06, 0x08,
            0x12, 0x00, 0x43, 0x00, 0x61, 0x00, 0x6c, 0x00,
            0x65, 0x00, 0x6e, 0x00, 0x64, 0x00, 0x61, 0x00,
            0x72, 0x00, 0x00, 0x08, 0x1e, 0x00, 0x43, 0x00,
            0x61, 0x00, 0x6c, 0x00, 0x65, 0x00, 0x6e, 0x00,
            0x64, 0x00, 0x61, 0x00, 0x72, 0x00, 0x20, 0x00,
            0x4e, 0x00, 0x6f, 0x00, 0x74, 0x00, 0x65, 0x00,
            0x73, 0x00, 0x00, 0x08, 0x20, 0x00, 0x52, 0x00,
            0x65, 0x00, 0x70, 0x00, 0x65, 0x00, 0x61, 0x00,
            0x74, 0x00, 0x20, 0x00, 0x4d, 0x00, 0x65, 0x00,
            0x65, 0x00, 0x74, 0x00, 0x69, 0x00, 0x6e, 0x00,
            0x67, 0x00, 0x73, 0x00, 0x00, 0x08, 0x1a, 0x00,
            0x52, 0x00, 0x65, 0x00, 0x70, 0x00, 0x65, 0x00,
            0x61, 0x00, 0x74, 0x00, 0x20, 0x00, 0x4e, 0x00,
            0x6f, 0x00, 0x74, 0x00, 0x65, 0x00, 0x73, 0x00,
            0x00, 0x08, 0x0c, 0x00, 0x54, 0x00, 0x6f, 0x00,
            0x20, 0x00, 0x64, 0x00, 0x6f, 0x00, 0x00, 0x08,
            0x16, 0x00, 0x54, 0x00, 0x6f, 0x00, 0x20, 0x00,
            0x44, 0x00, 0x6f, 0x00, 0x20, 0x00, 0x4c, 0x00,
            0x69, 0x00, 0x73, 0x00, 0x74, 0x00, 0x00, 0x05,
            0x06, 0x00, 0xff, 0x94, 0xad, 0xea, 0xf0, 0x00,
            0xff, 0x26, 0x1b, 0x7e, 0xd0, 0x00, 0xff, 0xde,
            0x75, 0xdf, 0xb8, 0x00, 0xff, 0x0c, 0xb3, 0x9e,
            0x70, 0x00, 0xff, 0xbe, 0x5d, 0x7d, 0xb4, 0x00,
            0xff, 0xeb, 0xe8, 0x99, 0x5c
        ])

        guard case let (decoded?, readCount) =
            try NewtonObjectDecoder.decodeRoot(data: data)
        else {
            XCTFail("Failed to decode frame")
            return
        }

        XCTAssertEqual(readCount, data.count)

        XCTAssertEqual(NewtonObjectEncoder.encodeRoot(newtonObject: decoded), data)
    }

    func testNSOF2() throws {

        let data = Data(bytes: [
            0x02, 0x05, 0x01, 0x06, 0x03, 0x07, 0x02, 0x69,
            0x64, 0x07, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x07,
            0x07, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6f, 0x6e,
            0x00, 0x08, 0x08, 0x38, 0x00, 0x4e, 0x00, 0x65,
            0x00, 0x77, 0x00, 0x74, 0x00, 0x6f, 0x00, 0x6e,
            0x00, 0x20, 0x00, 0x43, 0x00, 0x6f, 0x00, 0x6e,
            0x00, 0x6e, 0x00, 0x65, 0x00, 0x63, 0x00, 0x74,
            0x00, 0x69, 0x00, 0x6f, 0x00, 0x6e, 0x00, 0x20,
            0x00, 0x55, 0x00, 0x74, 0x00, 0x69, 0x00, 0x6c,
            0x00, 0x69, 0x00, 0x74, 0x00, 0x69, 0x00, 0x65,
            0x00, 0x73, 0x00, 0x00, 0x00, 0x04
        ])

        guard case let (decoded?, readCount) =
            try NewtonObjectDecoder.decodeRoot(data: data)
        else {
            XCTFail("Failed to decode NSOF")
            return
        }

        XCTAssertEqual(readCount, data.count)

        let expected: NewtonPlainArray =
            [
                [
                    "id": 2 as NewtonInteger,
                    "name": "Newton Connection Utilities" as NewtonString,
                    "version": 1 as NewtonInteger
                ] as NewtonFrame
            ]

        XCTAssertEqual(NewtonObjectEncoder.encodeRoot(newtonObject: decoded), data)
        XCTAssertEqual(NewtonObjectEncoder.encodeRoot(newtonObject: expected), data)
    }

    func testNSOF3() throws {

        let data = Data(bytes: [
            0x02, 0x06, 0x06, 0x07, 0x04, 0x6E, 0x61, 0x6D,
            0x65, 0x07, 0x04, 0x63, 0x61, 0x74, 0x73, 0x07,
            0x06, 0x62, 0x6F, 0x75, 0x6E, 0x64, 0x73, 0x07,
            0x05, 0x75, 0x63, 0x68, 0x61, 0x72, 0x07, 0x06,
            0x70, 0x68, 0x6F, 0x6E, 0x65, 0x73, 0x07, 0x09,
            0x6E, 0x61, 0x6D, 0x65, 0x41, 0x67, 0x61, 0x69,
            0x6E, 0x08, 0x1A, 0x00, 0x57, 0x00, 0x61, 0x00,
            0x6C, 0x00, 0x74, 0x00, 0x65, 0x00, 0x72, 0x00,
            0x20, 0x00, 0x53, 0x00, 0x6D, 0x00, 0x69, 0x00,
            0x74, 0x00, 0x68, 0x00, 0x00, 0x00, 0x08, 0x0B,
            0x0E, 0x0A, 0x64, 0x28, 0x02, 0x20, 0x22, 0x05,
            0x02, 0x08, 0x1A, 0x00, 0x34, 0x00, 0x30, 0x00,
            0x38, 0x00, 0x2D, 0x00, 0x39, 0x00, 0x39, 0x00,
            0x36, 0x00, 0x2D, 0x00, 0x31, 0x00, 0x30, 0x00,
            0x31, 0x00, 0x30, 0x00, 0x00, 0x03, 0x1A, 0x07,
            0x08, 0x66, 0x61, 0x78, 0x50, 0x68, 0x6F, 0x6E,
            0x65, 0x00, 0x34, 0x00, 0x30, 0x00, 0x38, 0x00,
            0x2D, 0x00, 0x39, 0x00, 0x37, 0x00, 0x34, 0x00,
            0x2D, 0x00, 0x39, 0x00, 0x30, 0x00, 0x39, 0x00,
            0x34, 0x00, 0x00, 0x09, 0x07
        ])

        guard case let (decoded?, readCount) =
            try NewtonObjectDecoder.decodeRoot(data: data)
        else {
            XCTFail("Failed to decode NSOF")
            return
        }

        XCTAssertEqual(readCount, data.count)

        let walter: NewtonString = "Walter Smith"

        let expected: NewtonFrame = [
            "name": walter,
            "cats": 2 as NewtonInteger,
            "bounds": NewtonSmallRect(top: 14, left: 10, bottom: 100, right: 40),
            "uchar": NewtonUnicodeCharacter(character: 8226),
            "phones": [
                "408-996-1010" as NewtonString,
                NewtonBinary(
                    class: NewtonSymbol(name: "faxPhone"),
                    data: Data(bytes: [
                        // 408-974-9094
                        0x00, 0x34, 0x00, 0x30, 0x00, 0x38, 0x00, 0x2D,
                        0x00, 0x39, 0x00, 0x37, 0x00, 0x34, 0x00, 0x2D,
                        0x00, 0x39, 0x00, 0x30, 0x00, 0x39, 0x00, 0x34,
                        0x00, 0x00
                    ])
                )
            ] as NewtonPlainArray,
            "nameAgain": walter
        ]

        XCTAssertEqual(NewtonObjectEncoder.encodeRoot(newtonObject: decoded), data)
        XCTAssertEqual(NewtonObjectEncoder.encodeRoot(newtonObject: expected), data)

    }

    static var allTests : [(String, (NewtonKitTests) -> () throws -> Void)] {
        return [
            ("testPacketLayerReadRequest", testPacketLayerReadRequest),
            ("testPacketLayerReadTransfer", testPacketLayerReadTransfer),
            ("testPacketLayerWrite", testPacketLayerWrite),
            ("testLinkRequestPacket", testLinkRequestPacket),
            ("testCRC", testCRC),
            ("testDockLayerReadRequestToDockPacket", testDockLayerReadRequestToDockPacket),
            ("testDockLayerReadResultPacket", testDockLayerReadResultPacket),
            ("testDockLayerReadPartial", testDockLayerReadPartial),
            ("testDES", testDES),
            ("testNSOF1", testNSOF1),
            ("testNSOF2", testNSOF2),
            ("testNSOF3", testNSOF3)
        ]
    }
}
