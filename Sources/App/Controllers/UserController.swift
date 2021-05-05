//
//  UserController.swift
//  
//
//  Created by Mikhail Ivanov on 02.04.2021.
//

import Vapor
import Fluent

final class UserController {
    init(_ app: Application) {
        app.post(["user", "addDevice"], use: registrateDevice)
        
        app.get(["user", "all"], use: getUsers)
        
        app.post("user", use: getUser)
        
        app.delete("user", "removeDevice", use: removeDevice)
    }
    
    func registrateDevice(_ req: Request) throws -> EventLoopFuture<UserDevicesServer> {
        let user = try req.content.decode(UserDevicesClient.self)
        
        return UserDevices.query(on: req.db).filter(\.$id == user.id).first().flatMap{ u -> EventLoopFuture<UserDevicesServer> in
            if let userDB = u {
                return DeviceInfo.query(on: req.db).filter(\.$user.$id == userDB.id!).all().flatMap { d -> EventLoopFuture<UserDevicesServer> in
                    
                    if d.isEmpty || !(d.contains(where: {$0.deviceID == user.device.deviceID})) {
                        let device = DeviceInfo(type: user.device.type, deviceID: user.device.deviceID, user: userDB)
                        
                        return device.save(on: req.db).map { () -> UserDevicesServer in
                            if d.isEmpty {
                                let deviceResult = DeviceServer(id: device.id!, deviceID: device.deviceID, type: device.type)
                                
                                return UserDevicesServer(id: device.$user.id, device: deviceResult)
                                
                            }
                            
                            var devicesResult: [DeviceServer] = []
                            d.forEach { e in
                                devicesResult.append(DeviceServer(id: e.id!, deviceID: e.deviceID, type: e.type))
                            }
                            
                            devicesResult.append(DeviceServer(id: device.id!, deviceID: device.deviceID, type: device.type))
                            return UserDevicesServer(id: device.$user.id, devices: devicesResult)
                            
                        }
                    }
                    
                    return req.eventLoop.makeSucceededVoidFuture().map { () -> UserDevicesServer in
                        var devicesResult: [DeviceServer] = []
                        
                        for e in d {
                            devicesResult.append(DeviceServer(id: e.id!, deviceID: e.deviceID, type: e.type))
                        }
                        
                        return UserDevicesServer(id: userDB.id!, devices: devicesResult)
                        
                    }
                }
            }
            
            let userDB = UserDevices(id: user.id)
            return userDB.create(on: req.db).flatMap { () -> EventLoopFuture<UserDevicesServer> in
                
                let device = DeviceInfo(type: user.device.type, deviceID: user.device.deviceID)
                
                return userDB.$devices.create(device, on: req.db).map { () -> UserDevicesServer in
                    
                    let deviceResult = DeviceServer(id: device.id!, deviceID: device.deviceID, type: device.type)
                    
                    let result = UserDevicesServer(id: device.$user.id, device: deviceResult)
                    
                    return result
                }
            }
        }
    }
    
    func getUsers(_ req: Request) throws -> EventLoopFuture<[UserDevicesServer]> {
        
        var users: [UserDevicesServer] = []
        
        return UserDevices.query(on: req.db).all().flatMap { (usersDB) -> EventLoopFuture<[UserDevicesServer]> in
            
            var deviceQuery: [EventLoopFuture<Void>] = []
            
            usersDB.forEach { (userDB) in
                deviceQuery.append(userDB.$devices.get(reload: true, on: req.db).and(userDB.$topics.get(reload: true, on: req.db)).map { resultDB in
                    var result = UserDevicesServer(id: userDB.id!)
                    
                    resultDB.0.forEach { (element) in
                        if result.devices == nil {
                            result.devices = []
                        }
                        result.devices?.append(.init(id: element.id!, deviceID: element.deviceID, type: element.type))
                    }
                    
                    resultDB.1.forEach { (element) in
                        if result.topics == nil {
                            result.topics = []
                        }
                        result.topics?.append(.init(id: element.id!, topicName: element.nameTopic))
                    }
                    
                    users.append(result)
                })
            }
            
            return deviceQuery.flatten(on: req.eventLoop).transform(to: users)
        }
    }
    
    func getUser(_ req: Request) throws -> EventLoopFuture<UserDevicesServer> {
        let user = try req.content.decode(UserClient.self)
        
        return UserDevices.query(on: req.db).filter(\.$id == user.id).first().unwrap(or: Abort(.notFound)).flatMap { (u) -> EventLoopFuture<UserDevicesServer> in
            
            return u.$devices.get(reload: true, on: req.db).and(u.$topics.get(reload: true, on: req.db)).map { resultDB -> (UserDevicesServer) in
                var result = UserDevicesServer(id: u.id!)
                
                resultDB.0.forEach { (element) in
                    if result.devices == nil {
                        result.devices = []
                    }
                    result.devices?.append(.init(id: element.id!, deviceID: element.deviceID, type: element.type))
                }
                
                resultDB.1.forEach { (element) in
                    if result.topics == nil {
                        result.topics = []
                    }
                    result.topics?.append(.init(id: element.id!, topicName: element.nameTopic))
                }
                
                return result
            }
        }
    }
    
    func removeDevice(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.content.decode(UserDevicesClient.self)
        
        return DeviceInfo.query(on: req.db).filter(\.$user.$id == user.id).all().flatMap { devices -> EventLoopFuture<HTTPStatus> in
            if let device = devices.first(where: { $0.deviceID == user.device.deviceID }) {
                return device.delete(on: req.db).transform(to: HTTPStatus.ok)
            }
            
            return req.eventLoop.makeSucceededFuture(HTTPStatus.ok)
        }
    }
}
