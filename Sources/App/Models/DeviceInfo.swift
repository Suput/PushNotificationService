//
//  File.swift
//  
//
//  Created by Mikhail Ivanov on 22.03.2021.
//

import Vapor
import Fluent

struct PushTest: Content {
    let title: String
    let message: String
}


final class DeviceInfo: Content, Model {
    
    enum DeviceType: String, Codable {
        case andorid, ios
    }
    
    static let schema = "devices"
    
    @ID(key: .id)
    var id: UUID?
    
    @OptionalParent(key: "user_id")
    var user: UserDevices?
    
    @Enum(key: "type")
    var type: DeviceType
    
    @Field(key: "deviceID")
    var deviceID: String
    
    init() {}
    
    init(id: UUID?, type: DeviceType, deviceID: String) {
        self.id = id
        self.type = type
        self.deviceID = deviceID
    }
}
