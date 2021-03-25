//
//  File.swift
//  
//
//  Created by Mikhail Ivanov on 25.03.2021.
//

import Vapor


struct PushClient: Content {
    let userId: UUID
    let push: PushMessage
}

struct PushMessage: Content {
    let title: String
    let message: String
}
