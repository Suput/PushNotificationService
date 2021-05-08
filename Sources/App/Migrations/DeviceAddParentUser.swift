//
//  DeviceAddParentUser.swift
//
//
//  Created by Mikhail Ivanov on 24.03.2021.
//

import Fluent

struct DeviceAddParentUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("devices")
            .field("user_id", .uuid, .required, .references("users", .id))
            .update()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("devices")
            .deleteField("user_id")
            .update()
    }
}
