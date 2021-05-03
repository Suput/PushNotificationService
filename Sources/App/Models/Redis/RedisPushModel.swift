//
//  RedisPushModel.swift
//  
//
//  Created by Михаил Иванов on 04.05.2021.
//

import Foundation


struct RedisPushModel: Codable {
    var message: RedisPushMessageModel
    var users: [UUID]
}

struct RedisPushMessageModel: Codable {
    var title: String
    var body: String
    var date: String?
}
