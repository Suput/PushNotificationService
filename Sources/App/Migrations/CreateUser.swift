//
//  CreateUser.swift
//  
//
//  Created by Mikhail Ivanov on 24.03.2021.
//

import Fluent

struct CreateUser: Migration {
    // Prepares the database for storing Galaxy models.
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("user")
            .id()
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("user").delete()
    }
}
