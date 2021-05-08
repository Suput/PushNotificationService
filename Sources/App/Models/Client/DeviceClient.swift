//
//  DeviceClient.swift
//
//
//  Created by Mikhail Ivanov on 24.03.2021.
//

import Vapor

struct DeviceClient: Content {
    let deviceID: String
    let type: DeviceInfo.DeviceType
}
