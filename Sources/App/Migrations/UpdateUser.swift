//
//  UpdateUser.swift
//  
//
//  Created by Mikhail Ivanov on 24.03.2021.
//

import Fluent

struct UpdateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("user")
            .field("devices_id", .uuid, .references("devices", .id))
            .update()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("user")
            .deleteField("devices_id")
            .update()
    }
}
