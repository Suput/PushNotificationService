//
//  TopicNotification.swift
//  
//
//  Created by Mikhail Ivanov on 01.04.2021.
//

import Fluent
import Vapor

final class TopicNotification: Model {
    
    static let schema = "topic"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name_topic")
    var nameTopic: String
    
    @Siblings(through: UserTopic.self, from: \.$topic, to: \.$user)
    public var users: [UserDevices]
    
    init() {}
    
    init(topic name: String) {
        self.nameTopic = name
    }
}
