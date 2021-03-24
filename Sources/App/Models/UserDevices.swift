//
//  UserDevices.swift
//  
//
//  Created by Mikhail Ivanov on 24.03.2021.
//

import Vapor
import Fluent

final class UserDevices: Model, Content {
    
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Children(for: \.$user)
    var devices: [DeviceInfo]
    
    init() {}
    
    init(id: UUID?, devices: [DeviceInfo])
    {
        self.id = id
        self.devices = devices
    }
}

struct UserDevicesClient: Content {
    let id: UUID
    let device: DeviceClient
}


