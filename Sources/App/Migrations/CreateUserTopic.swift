//
// CreateUserTopic.swift
//  
//
//  Created by Mikhail Ivanov on 02.04.2021.
//

import Fluent

struct CreateUserTopic: Migration {
    // Prepares the database for storing Galaxy models.
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("user+topic")
            .id()
            .field("user", .uuid, .required, .references("users", .id))
            .field("topic", .uuid, .required, .references("topic", .id))
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("user+topic").delete()
    }
}
