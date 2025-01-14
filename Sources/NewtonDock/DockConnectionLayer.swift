
import Foundation
import NSOF

public final class DockConnectionLayer {

    public enum State {
        case disconnected
        case initiatedDocking
        case sentDesktopInfo
        case sentWhichIcons
        case sentSetTimeout
        case connected
        case keyboardPassthrough
        case backingUp
        case loadingPackage
    }

    public enum Error: Swift.Error {
        case sendingWhichIconsFailed
        case missingNewtonKey
        case newtonKeyEnryptionKeyFailed
        case notConnected
        case loadingPackage
    }

    public struct Connection {
        public let newtonInfo: NewtonInfo
        public let newtonName: String
    }

    private static let timeout: UInt32 = 60

    private static let desktopKey =
        Data([0x64, 0x23, 0xef, 0x02, 0xfb, 0xcd, 0xc5, 0xa5])

    private static let desktopApps: NewtonPlainArray =
        [
            ["id": 2 as NewtonInteger,
             "name": "Newton Connection Utilities" as NewtonString,
             "version": 1 as NewtonInteger]
            as NewtonFrame
        ]

    private static let desKey: [UInt8] =
        [0xe4, 0x0f, 0x7e, 0x9f, 0x0a, 0x36, 0x2c, 0xfa]

    public var onStateChange: ((State, State) -> Void)?
    public var onConnect: ((Connection) -> Void)?
    public var onDisconnect: ((Connection) -> Void)?
    public var onWrite: ((EncodableDockPacket) throws -> Void)?
    public var onCallResult: ((NewtonObject) -> Void)?

    public private(set) var state: State = .disconnected {
        didSet {
            onStateChange?(oldValue, state)
        }
    }

    public var isConnected: Bool {
        return state != .disconnected
    }

    private var des: DES
    private var newtonKey: Data?
    public private(set) var connection: Connection?

    public let keyboardPassthroughLayer = DockKeyboardPassthroughLayer()
    public let backupLayer = DockBackupLayer()
    public let packageLayer = DockPackageLayer()

    public init() throws {
        des = try DES(keyBytes: DockConnectionLayer.desKey)
        keyboardPassthroughLayer.connectionLayer = self
        backupLayer.connectionLayer = self
        packageLayer.connectionLayer = self
    }

    public func disconnect() throws {
        guard isConnected else {
            return
        }

        newtonKey = nil
        let connection = self.connection
        self.connection = nil

        keyboardPassthroughLayer.handleDisconnect()
        backupLayer.handleDisconnect()
        packageLayer.handleDisconnect()

        state = .disconnected

        defer {
            if let connection = connection {
                onDisconnect?(connection)
            }
        }

        try write(packet: DisconnectPacket())
    }

    public func read(packet: DecodableDockPacket) throws {

        switch packet {
        case is DisconnectPacket:
            try disconnect()
            return
        default:
            break
        }

        switch state {
        case .disconnected:
            if packet is RequestToDockPacket {
                try write(packet: InitiateDockingPacket(sessionType: .noSession))
                state = .initiatedDocking
            }
        case .initiatedDocking:
            if let newtonNamePacket = packet as? NewtonNamePacket {
                connection = Connection(
                    newtonInfo: newtonNamePacket.newtonInfo,
                    newtonName: newtonNamePacket.name
                )

                let packet =
                    try DesktopInfoPacket(protocolVersion: 10,
                                          desktopType: .macintosh,
                                          encryptedKey: DockConnectionLayer.desktopKey,
                                          sessionType: .settingUpSession,
                                          allowSelectiveSync: false,
                                          desktopApps: DockConnectionLayer.desktopApps)
                try write(packet: packet)
                state = .sentDesktopInfo
            } else {
                try sendError()
            }
        case .sentDesktopInfo:
            if let newtonInfoPacket = packet as? NewtonInfoPacket {
                newtonKey = newtonInfoPacket.encryptedKey
                try write(packet: WhichIconsPacket(iconMask: .all))
                state = .sentWhichIcons
            } else {
                try sendError()
            }
        case .sentWhichIcons:
            if let resultPacket = packet as? ResultPacket {
                guard resultPacket.error == .ok else {
                    throw Error.sendingWhichIconsFailed
                }
                try write(packet: SetTimeoutPacket(timeout: DockConnectionLayer.timeout))
                state = .sentSetTimeout
            } else {
                try sendError()
            }
        case .sentSetTimeout:
            if packet is PasswordPacket {
                guard let newtonKey = newtonKey else {
                    throw Error.missingNewtonKey
                }
                guard let encryptedKey = des.encrypt(source: newtonKey) else {
                    throw Error.newtonKeyEnryptionKeyFailed
                }
                try write(packet: PasswordPacket(encryptedKey: encryptedKey))
                state = .connected
                if let connection = connection {
                    onConnect?(connection)
                }
            } else {
                try sendError()
            }
        case .connected:
            switch packet {
            case is OperationCanceledPacket:
                try write(packet: OperationCanceledAcknowledgementPacket())
                state = .connected
            case is StartKeyboardPassthroughPacket:                
                try keyboardPassthroughLayer.handleRequest()
                state = .keyboardPassthrough
            case is RequestToSyncPacket:
                try backupLayer.handleRequest()
                state = .backingUp
            case let callResultPacket as CallResultPacket:
                onCallResult?(callResultPacket.result)
                try completeOperation()
            default:
                break
            }
        case .loadingPackage:
            try packageLayer.read(packet: packet)
        case .keyboardPassthrough:
            try keyboardPassthroughLayer.read(packet: packet)
        case .backingUp:
            try backupLayer.read(packet: packet)
        }
    }

    internal func write(packet: EncodableDockPacket) throws {
        try onWrite?(packet)
    }

    internal func sendError() throws {
        // TODO: or protocolError?
        try write(packet: ResultPacket(error: .desktopError))
        try disconnect()
    }

    public func startKeyboardPassthrough() throws {
        if state == .keyboardPassthrough {
            return
        }

        guard state == .connected else {
            throw Error.notConnected
        }

        try keyboardPassthroughLayer.start()
        state = .keyboardPassthrough
    }

    public func startBackup() throws {
        if state == .backingUp {
            return
        }

        guard state == .connected else {
            throw Error.notConnected
        }

        try backupLayer.start()
        state = .backingUp
    }

    public func loadPackage(data: Data) throws {
        guard state != .loadingPackage else {
            throw Error.loadingPackage
        }

        guard state == .connected else {
            throw Error.notConnected
        }

        try packageLayer.start(package: data)
        state = .loadingPackage
    }

    internal func startDesktopControl() throws {
        try write(packet: DesktopInControlPacket())
    }

    internal func completeOperation() throws {
        try write(packet: OperationDonePacket())
        state = .connected
    }

    internal func acknowledgeOperationCanceled() throws {
        try write(packet: OperationCanceledAcknowledgementPacket())
        state = .connected
    }

    public func callGlobalFunction(name: String, arguments: [NewtonObject]) throws {
        try write(packet: CallGlobalFunctionPacket(name: NewtonSymbol(name: name),
                                                   arguments: NewtonPlainArray(values: arguments)))
    }

    public func callRootMethod(name: String, arguments: [NewtonObject]) throws {
        try write(packet: CallRootMethodPacket(name: NewtonSymbol(name: name),
                                               arguments: NewtonPlainArray(values: arguments)))
    }
}
