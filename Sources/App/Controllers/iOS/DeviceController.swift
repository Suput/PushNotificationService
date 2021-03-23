//
//  Device.swift
//  
//
//  Created by Mikhail Ivanov on 23.03.2021.
//

import Vapor

final class DeviceController {
    init(_ app: Application) {
        app.post("test-push", use: testPush)
    }
    
    func testPush(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let push = try req.content.decode(PushTest.self)
        
        let config = ConfigurationService.loadSettings()
        
        return req.apns.send(
            .init(title: push.title, subtitle: push.message),
            to: config!.testDevice
        ).map { .ok }
    }
}
