
import Foundation
import XCTest
@testable import NSOF

class NSOFTests: XCTestCase {

    private func dataUnequalMessage(_ lhs: Data, _ rhs: Data) -> String {
        return "\n\(lhs.hexDump)\n\n\(rhs.hexDump)\n\n"
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

        let encoded = NewtonObjectEncoder.encodeRoot(newtonObject: decoded)
        XCTAssertEqual(encoded, data,
                       dataUnequalMessage(encoded, data))
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

        let encoded1 = NewtonObjectEncoder.encodeRoot(newtonObject: decoded)
        XCTAssertEqual(encoded1, data,
                       dataUnequalMessage(encoded1, data))

        let encoded2 = NewtonObjectEncoder.encodeRoot(newtonObject: expected)
        XCTAssertEqual(encoded2, data,
                       dataUnequalMessage(encoded2, data))
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
                NewtonBinary(class: NewtonSymbol(name: "faxPhone"),
                             data: Data(bytes: [
                                // 408-974-9094
                                0x00, 0x34, 0x00, 0x30, 0x00, 0x38, 0x00, 0x2D,
                                0x00, 0x39, 0x00, 0x37, 0x00, 0x34, 0x00, 0x2D,
                                0x00, 0x39, 0x00, 0x30, 0x00, 0x39, 0x00, 0x34,
                                0x00, 0x00
                                ]))
                ] as NewtonPlainArray,
            "nameAgain": walter
        ]

        let encoded1 = NewtonObjectEncoder.encodeRoot(newtonObject: decoded)
        XCTAssertEqual(encoded1, data,
                       dataUnequalMessage(encoded1, data))

        let encoded2 = NewtonObjectEncoder.encodeRoot(newtonObject: expected)
        XCTAssertEqual(encoded2, data,
                       dataUnequalMessage(encoded2, data))
    }

    static var allTests : [(String, (NSOFTests) -> () throws -> Void)] {
        return [
            ("testNSOF1", testNSOF1),
            ("testNSOF2", testNSOF2),
            ("testNSOF3", testNSOF3)
        ]
    }
}
