//
//  File.swift
//  
//
//  Created by Mikhail Ivanov on 25.03.2021.
//

import Vapor

struct PushToUserClient: Content {
    let userID: UUID
    let push: PushMessage
}

struct PushToTopicClient: Content {
    let topicID: UUID
    let push: PushMessage
}

struct PushMessage: Content {
    let title: String
    let message: String
}
