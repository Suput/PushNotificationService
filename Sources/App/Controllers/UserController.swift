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
        
        app.grouped(JWTMiddleware()).group("user") { route in
            route.post(use: getUser)
            
            route.get("all", use: getUsers)
            
            route.post("addDevice", use: registrateDevice)
            
            route.delete("removeDevice", use: removeDevice)
        }
    }
    
    func registrateDevice(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userID = try req.auth.require(UserAuthInfo.self).id
        
        let deviceClient = try req.content.decode(DeviceClient.self)
        
        return DeviceInfo.query(on: req.db).filter(\.$deviceID == deviceClient.deviceID)
            .first().flatMap { deviceDB in
                if let device = deviceDB {
                    return device.$user.get(on: req.db).flatMap { userDB -> EventLoopFuture<HTTPStatus> in
                        if userDB.id == userID {
                            return req.eventLoop.makeSucceededFuture(HTTPStatus.ok)
                        }
                        
                        return UserDevices.query(on: req.db).filter(\.$id == userID)
                            .first().flatMap { findUser -> EventLoopFuture<HTTPStatus> in
                                if let user = findUser {
                                    device.$user.id = user.id!
                                    
                                    return device.update(on: req.db).map {.ok}
                                }
                                
                                let newUser = UserDevices(id: userID)
                                
                                return newUser.create(on: req.db).flatMap {
                                    device.$user.id = newUser.id!
                                    
                                    return device.update(on: req.db).map {.ok}
                                }
                            }
                    }
                }
                
                return UserDevices.query(on: req.db).filter(\.$id == userID)
                    .first().flatMap { userDB in
                        if let user = userDB {
                            let device = DeviceInfo(device: deviceClient, user: user)
                            
                            return device.create(on: req.db).map {.ok}
                        }
                        
                        let user = UserDevices(id: userID)
                        
                        return user.create(on: req.db).flatMap {
                            let device = DeviceInfo(device: deviceClient, user: user)
                            
                            return device.create(on: req.db).map {.ok}
                        }
                    }
            }
    }
    
    func getUsers(_ req: Request) throws -> EventLoopFuture<[UserDevicesServer]> {
        
        var users: [UserDevicesServer] = []
        
        return UserDevices.query(on: req.db).all().flatMap { (usersDB) -> EventLoopFuture<[UserDevicesServer]> in
            
            var deviceQuery: [EventLoopFuture<Void>] = []
            
            usersDB.forEach { (userDB) in
                deviceQuery.append(userDB.$devices.get(reload: true, on: req.db)
                                    .and(userDB.$topics.get(reload: true, on: req.db)).map { resultDB in
                                        var result = UserDevicesServer(id: userDB.id!)
                                        
                                        resultDB.0.forEach { (element) in
                                            if result.devices == nil {
                                                result.devices = []
                                            }
                                            result.devices?.append(.init(id: element.id!,
                                                                         deviceID: element.deviceID,
                                                                         type: element.type))
                                        }
                                        
                                        resultDB.1.forEach { (element) in
                                            if result.topics == nil {
                                                result.topics = []
                                            }
                                            result.topics?.append(.init(id: element.id!,
                                                                        topicName: element.nameTopic))
                                        }
                                        
                                        users.append(result)
                                    })
            }
            
            return deviceQuery.flatten(on: req.eventLoop).transform(to: users)
        }
    }
    
    func getUser(_ req: Request) throws -> EventLoopFuture<UserDevicesServer> {
        
        let userClient = try req.content.decode(UserClient.self)
        
        return UserDevices.query(on: req.db).filter(\.$id == userClient.id).first()
            .unwrap(or: Abort(.notFound)).flatMap { (userDB) -> EventLoopFuture<UserDevicesServer> in
                
                return userDB.$devices.get(reload: true, on: req.db)
                    .and(userDB.$topics.get(reload: true, on: req.db)).map { resultDB -> (UserDevicesServer) in
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
                        
                        return result
                    }
            }
    }
    
    func removeDevice(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userID = try req.auth.require(UserAuthInfo.self).id
        
        let device = try req.content.decode(DeviceClient.self)
        
        return DeviceInfo.query(on: req.db).filter(\.$user.$id == userID).all()
            .flatMap { devices -> EventLoopFuture<HTTPStatus> in
                if let device = devices.first(where: { $0.deviceID == device.deviceID }) {
                    return device.delete(on: req.db).transform(to: HTTPStatus.ok)
                }
                
                return req.eventLoop.makeSucceededFuture(HTTPStatus.ok)
            }
    }
}
