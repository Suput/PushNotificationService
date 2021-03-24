//
//  UserDevices.swift
//  
//
//  Created by Mikhail Ivanov on 24.03.2021.
//

import Vapor
import Fluent

final class UserDevices: Model {
    
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    init() {}
    
    init(id: UUID?)
    {
        self.id = id
    }
}




