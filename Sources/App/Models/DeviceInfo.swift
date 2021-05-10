//
//  File.swift
//
//
//  Created by Mikhail Ivanov on 22.03.2021.
//

import Vapor
import Fluent

final class DeviceInfo: Model {

    enum DeviceType: String, Codable {
        case android, ios
    }

    static let schema = "devices"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: UserDevices

    @Enum(key: "type")
    var type: DeviceType

    @Field(key: "deviceID")
    var deviceID: String

    init() {}

    init(type: DeviceType, deviceID: String, user: UserDevices) {
        self.type = type
        self.deviceID = deviceID
        self.$user.id = user.id!
    }

    init(type: DeviceType, deviceID: String) {
        self.type = type
        self.deviceID = deviceID
    }

    init(device client: DeviceClient) {
        self.type = client.type
        self.deviceID = client.deviceID
    }
    
    init(device client: DeviceClient, user: UserDevices) {
        self.type = client.type
        self.deviceID = client.deviceID
        self.$user.id = user.id!
    }
}
