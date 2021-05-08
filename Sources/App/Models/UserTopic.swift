//
//  UserTopic.swift
//
//
//  Created by Mikhail Ivanov on 02.04.2021.
//

import Fluent
import Vapor

final class UserTopic: Model {

    static let schema = "user+topic"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user")
    var user: UserDevices
    @Parent(key: "topic")
    var topic: TopicNotification

    init() {}

    init(id: UUID? = nil, user: UserDevices, topic: TopicNotification) throws {
        self.id = id
        self.$user.id = try user.requireID()
        self.$topic.id = try topic.requireID()
    }
}
