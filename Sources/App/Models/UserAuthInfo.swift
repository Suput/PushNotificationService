//
//  UserAuthInfo.swift
//
//
//  Created by Mikhail Ivanov on 13.05.2021.
//

import Vapor

struct UserAuthInfo: Authenticatable {
    var id: UUID
    var role: [String]
}
