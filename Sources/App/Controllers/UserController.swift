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
        
        app.group("user") { route in
            route.post(use: getUser)
            
            route.get("all", use: getUsers)
            
            route.post("addDevice", use: registrateDevice)

            route.delete("removeDevice", use: removeDevice)
        }
    }

    func registrateDevice(_ req: Request) throws -> EventLoopFuture<UserDevicesServer> {
        let userDeviceClient = try req.content.decode(UserDevicesClient.self)

        return UserDevices.query(on: req.db).filter(\.$id == userDeviceClient.id).first()
            .flatMap { userDB -> EventLoopFuture<UserDevicesServer> in
            if let user = userDB {
                return DeviceInfo.query(on: req.db).filter(\.$user.$id == user.id!).all()
                    .flatMap { deviceDB -> EventLoopFuture<UserDevicesServer> in

                    if deviceDB.isEmpty ||
                        !(deviceDB.contains(where: {$0.deviceID == userDeviceClient.device.deviceID})) {

                        let device = DeviceInfo(type: userDeviceClient.device.type,
                                                deviceID: userDeviceClient.device.deviceID,
                                                user: user)

                        return device.save(on: req.db).map { () -> UserDevicesServer in
                            if deviceDB.isEmpty {
                                let deviceResult = DeviceServer(id: device.id!,
                                                                deviceID: device.deviceID,
                                                                type: device.type)

                                return UserDevicesServer(id: device.$user.id, device: deviceResult)

                            }

                            var devicesResult: [DeviceServer] = []
                            deviceDB.forEach { element in
                                devicesResult.append(DeviceServer(id: element.id!,
                                                                  deviceID: element.deviceID,
                                                                  type: element.type))
                            }

                            devicesResult.append(DeviceServer(id: device.id!,
                             deviceID: device.deviceID,
                              type: device.type))
                            return UserDevicesServer(id: device.$user.id, devices: devicesResult)

                        }
                    }

                    return req.eventLoop.makeSucceededVoidFuture().map { () -> UserDevicesServer in
                        var devicesResult: [DeviceServer] = []

                        for element in deviceDB {
                            devicesResult.append(DeviceServer(id: element.id!,
                                                              deviceID: element.deviceID,
                                                              type: element.type))
                        }

                        return UserDevicesServer(id: user.id!, devices: devicesResult)

                    }
                }
            }

            let userDB = UserDevices(id: userDeviceClient.id)
            return userDB.create(on: req.db).flatMap { () -> EventLoopFuture<UserDevicesServer> in

                let device = DeviceInfo(type: userDeviceClient.device.type, deviceID: userDeviceClient.device.deviceID)

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
                deviceQuery.append(userDB.$devices.get(reload: true, on: req.db)
                                    .and(userDB.$topics.get(reload: true, on: req.db)).map { resultDB in
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
        let user = try req.content.decode(UserDevicesClient.self)

        return DeviceInfo.query(on: req.db).filter(\.$user.$id == user.id).all()
            .flatMap { devices -> EventLoopFuture<HTTPStatus> in
            if let device = devices.first(where: { $0.deviceID == user.device.deviceID }) {
                return device.delete(on: req.db).transform(to: HTTPStatus.ok)
            }

            return req.eventLoop.makeSucceededFuture(HTTPStatus.ok)
        }
    }
}
