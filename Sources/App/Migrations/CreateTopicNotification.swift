//
//  CreateTopicNotification.swift
//  
//
//  Created by Mikhail Ivanov on 01.04.2021.
//

import Fluent

struct CreateTopicNotification: Migration {
    // Prepares the database for storing Galaxy models.
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("topic")
            .id()
            .field("name_topic", .string)
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("topic").delete()
    }
}
