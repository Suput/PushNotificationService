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
}
