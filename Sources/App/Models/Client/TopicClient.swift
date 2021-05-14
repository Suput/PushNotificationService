//
//  TopicClient.swift
//
//
//  Created by Mikhail Ivanov on 02.04.2021.
//

import Vapor

struct TopicClient: Content {
    var name: String
}

struct SubTopic: Content {
    var topicID: UUID
    var userID: UUID
}
