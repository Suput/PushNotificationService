//
//  DeviceServer.swift
//  
//
//  Created by Mikhail Ivanov on 24.03.2021.
//

import Vapor

struct DeviceServer: Content {
    var id: UUID
    var deviceID: String
    var type: DeviceInfo.DeviceType
}
