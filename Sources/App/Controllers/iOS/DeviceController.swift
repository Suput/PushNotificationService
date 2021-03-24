//
//  Device.swift
//  
//
//  Created by Mikhail Ivanov on 23.03.2021.
//

import Vapor
import Fluent

final class DeviceController {
    init(_ app: Application) {
        app.post("test-push", use: testPush)
        
        app.post("addDevice", use: registrateDevice)
        
        app.get("users", use: getUsers)
        
        app.delete("dropUsers", use: dropUsers)
    }
    
    func testPush(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let push = try req.content.decode(PushTest.self)
        
        let config = ConfigurationService.loadSettings()
        
        return req.apns.send(
            .init(title: push.title, subtitle: push.message),
            to: config!.testDevice
        ).map { .ok }
    }
    
    func registrateDevice(_ req: Request) throws -> EventLoopFuture<UserDevices> {
        let user = try req.content.decode(UserDevicesClient.self)
        
        let findDevice = UserDevices.query(on: req.db).filter(\.$id == user.id).first()
        return findDevice
            .flatMap { u -> EventLoopFuture<UserDevices> in
                
                if u == nil {
                    let newUser = UserDevices()
                    newUser.id = user.id
                    
                    return newUser.create(on: req.db).flatMap { () -> EventLoopFuture<UserDevices> in
                        let device = DeviceInfo(device: user.device)
                        return newUser.$devices.create(device, on: req.db).map {newUser}
                    }
                }
                return u!.$devices.query(on: req.db).filter(\.$deviceID == user.device.deviceID).first().flatMap {
                    d -> EventLoopFuture<UserDevices> in
                    
                    if d == nil {
                        let device = DeviceInfo(device: user.device)
                        return u!.$devices.create(device, on: req.db).map {u!}
                    }
                    
                    return u!.update(on: req.db).map {u!}
                }
                
            }
    }
    
    func dropUsers(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return UserDevices.query(on: req.db).delete().map{.ok}
    }
    
    func getUsers(_ req: Request) throws -> EventLoopFuture<[UserDevices]> {
        UserDevices.query(on: req.db).all()
    }
}
