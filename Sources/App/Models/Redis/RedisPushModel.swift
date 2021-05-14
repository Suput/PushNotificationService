//
//  RedisPushModel.swift
//
//
//  Created by Михаил Иванов on 04.05.2021.
//

import Vapor

struct RedisPushModel: Content {
    var message: RedisPushMessageModel
    var users: [UUID]
}

struct RedisPushMessageModel: Content {
    var title: String
    var body: String
    var date: String?
}
