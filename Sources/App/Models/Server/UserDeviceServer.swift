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
    var device: DeviceServer?

    var topics: [TopicServer]?

    init(id: UUID, devices: [DeviceServer]) {
        self.init(id: id)

        self.devices = devices
    }

    init(id: UUID, device: DeviceServer) {
        self.init(id: id)

        self.device = device
    }

    init(id: UUID) {
        self.id = id
    }
}
