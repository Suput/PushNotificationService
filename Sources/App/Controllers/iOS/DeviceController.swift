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
        
        app.post("push", use: push)
        
        app.post("addDevice", use: registrateDevice)
        
        app.get("users", use: getUsers)
        
        app.post("user", use: getUser)
        
        // TODO: test
        if app.environment == .development {
            app.delete("drop", use: dropDB)
        }
    }
    
    func testPush(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let push = try req.content.decode(PushMessage.self)
        
        guard let config = ConfigurationService.loadSettings(),
              let deviceID = config.testDevice else {
            return req.eventLoop.makeFailedFuture(Abort(.custom(code: 404, reasonPhrase: "Not found deviceID")))
        }
        
        return req.apns.send(
            .init(title: push.title, subtitle: push.message),
            to: deviceID
        ).map { .ok }
        
    }
    
    func push(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let push = try req.content.decode(PushClient.self)
        
        return DeviceInfo.query(on: req.db).filter(\.$user.$id == push.userId).all().flatMap { (devices) -> EventLoopFuture<HTTPStatus> in
            if devices.isEmpty {
                return req.eventLoop.makeFailedFuture(Abort(.notFound))
            }
            
            var task: [EventLoopFuture<Void>] = []
            
            devices.forEach { device in
                if device.type == .ios {
                   task.append(
                        req.apns.send(
                            .init(title: push.push.title, subtitle: push.push.message),
                            to: device.deviceID
                        ))
                }
            }
            
            return req.eventLoop.makeSucceededVoidFuture().fold(task) { (t, t1) -> EventLoopFuture<Void> in
                return req.eventLoop.makeSucceededVoidFuture()
            }.transform(to: HTTPStatus.ok)
            
        }
    }
    
    func registrateDevice(_ req: Request) throws -> EventLoopFuture<UserDevicesServer> {
        let user = try req.content.decode(AddUserDevicesClient.self)
        
        return UserDevices.query(on: req.db).filter(\.$id == user.id).first().flatMap{ u -> EventLoopFuture<UserDevicesServer> in
            if let userDB = u {
                return DeviceInfo.query(on: req.db).filter(\.$user.$id == userDB.id!).all().flatMap { d -> EventLoopFuture<UserDevicesServer> in
                    
                    if d.isEmpty || !(d.contains(where: {$0.deviceID == user.device.deviceID})) {
                        let device = DeviceInfo(type: user.device.type, deviceID: user.device.deviceID, user: userDB)
                        
                        return device.save(on: req.db).map { () -> UserDevicesServer in
                            if d.isEmpty {
                                let deviceResult = DeviceServer(id: device.id!, deviceID: device.deviceID, type: device.type)
                                
                                return UserDevicesServer(id: device.$user.id, devices: nil, device: deviceResult)
                                
                            }
                            
                            var devicesResult: [DeviceServer] = []
                            d.forEach { e in
                                devicesResult.append(DeviceServer(id: e.id!, deviceID: e.deviceID, type: e.type))
                            }
                            
                            devicesResult.append(DeviceServer(id: device.id!, deviceID: device.deviceID, type: device.type))
                            return UserDevicesServer(id: device.$user.id, devices: devicesResult, device: nil)
                            
                        }
                    }
                    
                    return req.eventLoop.makeSucceededVoidFuture().map { () -> UserDevicesServer in
                        var devicesResult: [DeviceServer] = []
                        
                        for e in d {
                            devicesResult.append(DeviceServer(id: e.id!, deviceID: e.deviceID, type: e.type))
                        }
                        
                        return UserDevicesServer(id: userDB.id!, devices: devicesResult, device: nil)
                        
                    }
                }
            }
            
            let userDB = UserDevices(id: user.id)
            return userDB.create(on: req.db).flatMap { () -> EventLoopFuture<UserDevicesServer> in
                
                let device = DeviceInfo(type: user.device.type, deviceID: user.device.deviceID, user: userDB)
                
                return device.create(on: req.db).map { () -> UserDevicesServer in
                    
                    let deviceResult = DeviceServer(id: device.id!, deviceID: device.deviceID, type: device.type)
                    
                    let result = UserDevicesServer(id: device.$user.id, devices: nil, device: deviceResult)
                    
                    return result
                }
            }
        }
    }
    
    func dropDB(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return DeviceInfo.query(on: req.db).delete().flatMap {() -> EventLoopFuture<HTTPStatus> in
            return UserDevices.query(on: req.db).delete().map {.ok}
        }
    }
    
    func getUsers(_ req: Request) throws -> EventLoopFuture<[UserDevicesServer]> {
        
        var users: [UserDevicesServer] = []
        
        return DeviceInfo.query(on: req.db).all().map { d -> [UserDevicesServer] in
            
            for element in d {
                
                if let i = users.firstIndex(where: {$0.id == element.$user.id}) {
                    users[i].devices!.append(DeviceServer(id: element.id!, deviceID: element.deviceID, type: element.type))
                } else {
                    users.append(UserDevicesServer(id: element.$user.id, devices: [DeviceServer(id: element.id!, deviceID: element.deviceID, type: element.type)]))
                }
            }
            
            return users
        }
    }
    
    func getUser(_ req: Request) throws -> EventLoopFuture<UserDevicesServer> {
        let user = try req.content.decode(UserClient.self)
        
        return DeviceInfo.query(on: req.db).filter(\.$user.$id == user.id).all().map { d -> UserDevicesServer in
            
            var result = UserDevicesServer(id: user.id, devices: [], device: nil)
            
                d.forEach { (element) in
                    result.devices?.append(DeviceServer(id: element.id!, deviceID: element.deviceID, type: element.type))
                }
            
            
            return result
        }
    }
}
