//
//  UserDeviceClient.swift
//
//
//  Created by Mikhail Ivanov on 24.03.2021.
//

import Vapor

struct UserDevicesClient: Content {
    let id: UUID
    let device: DeviceClient
}

struct UserClient: Content {
    let id: UUID
}
