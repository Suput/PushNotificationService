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
    
    func registrateDevice(_ req: Request) throws -> EventLoopFuture<UserDevicesServer> {
        let user = try req.content.decode(UserDevicesClient.self)
        
        return UserDevices.query(on: req.db).filter(\.$id == user.id).first().flatMap{ u -> EventLoopFuture<UserDevicesServer> in
            if let uuid = u?.id {
                return DeviceInfo.query(on: req.db).filter(\.$user.$id == uuid).all().flatMap { d -> EventLoopFuture<UserDevicesServer> in
                    
                    if d.isEmpty || !(d.contains(where: {$0.deviceID == user.device.deviceID})) {
                        let device = DeviceInfo(type: user.device.type, deviceID: user.device.deviceID, user: u!)
                        
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
                        
                        return UserDevicesServer(id: uuid, devices: devicesResult, device: nil)
                        
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
    
    func dropUsers(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return UserDevices.query(on: req.db).delete().map{.ok}
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
}
