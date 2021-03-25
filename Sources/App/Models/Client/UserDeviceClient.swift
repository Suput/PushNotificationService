//
//  UserDeviceClient.swift
//  
//
//  Created by Mikhail Ivanov on 24.03.2021.
//

import Vapor

struct AddUserDevicesClient: Content {
    let id: UUID
    let device: DeviceClient
}
