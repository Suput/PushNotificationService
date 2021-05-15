//
//  DeviceAddDate.swift
//  
//
//  Created by Mikhail Ivanov on 15.05.2021.
//

import Fluent

final class DeviceAddDate: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("devices")
            .field("init_date", .date)
            .update()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("devices")
            .deleteField("init_date")
            .update()
    }
}
