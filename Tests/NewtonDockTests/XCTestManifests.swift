#if !canImport(ObjectiveC)
import XCTest

extension NewtonDockTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__NewtonDockTests = [
        ("testDES", testDES),
        ("testDockLayerReadPartial", testDockLayerReadPartial),
        ("testDockLayerReadRequestToDockPacket", testDockLayerReadRequestToDockPacket),
        ("testDockLayerReadResultPacket", testDockLayerReadResultPacket),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(NewtonDockTests.__allTests__NewtonDockTests),
    ]
}
#endif
