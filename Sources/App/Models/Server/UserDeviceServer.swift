//
//  UserDeviceServer.swift
//
//
//  Created by Mikhail Ivanov on 24.03.2021.
//

import Vapor

struct UserDevicesServer: Content {
    var id: UUID
    var devices: [DeviceServer]?

    init(id: UUID, devices: [DeviceServer]) {
        self.init(id: id)

        self.devices = devices
    }

    init(id: UUID) {
        self.id = id
    }
}
