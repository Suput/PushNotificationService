//
//  TopicServer.swift
//  
//
//  Created by Mikhail Ivanov on 02.04.2021.
//

import Vapor


struct TopicServer: Content {
    var id: UUID
    var topicName: String
    
    var users: [UserDevicesServer]?
    
    init(id: UUID, topicName: String) {
        self.id = id
        self.topicName = topicName
    }
    
    init(id: UUID, topicName: String, users: [UserDevicesServer]) {
        self.init(id: id, topicName: topicName)
        self.users = users
    }
    
    init(id: UUID, topicName: String, userDB: UserDevices) {
        self.init(id: id, topicName: topicName)
        self.users = [.init(id: userDB.id!)]
    }
}
