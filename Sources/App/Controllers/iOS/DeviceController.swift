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
        
        let userD = UserDevices(id: user.id)
        
        return userD.save(on: req.db).flatMap { () -> EventLoopFuture<UserDevicesServer> in
            return DeviceInfo.query(on: req.db).filter(\.$deviceID == user.device.deviceID).first().flatMap { d -> EventLoopFuture<UserDevicesServer> in
                
                if d != nil {
                    return Abort(.loopDetected) as! EventLoopFuture<UserDevicesServer>
                }
                
                let device = DeviceInfo(type: user.device.type, deviceID:  user.device.deviceID, user: UserDevices(id: user.id))
                
                return device.create(on: req.db).flatMap { () -> EventLoopFuture<UserDevicesServer> in
                    
                    return DeviceInfo.query(on: req.db).filter(\.$deviceID == user.device.deviceID).first().map
                    { d -> UserDevicesServer in
                        
                        return UserDevicesServer(id: user.id, devices: nil, device: DeviceServer(id: d!.id!, deviceID: d!.deviceID, type: d!.type))
                    }
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
                
                if let i = users.firstIndex(where: {$0.id == element.user.id}) {
                    users[i].devices!.append(DeviceServer(id: element.id!, deviceID: element.deviceID, type: element.type))
                } else {
                    users.append(UserDevicesServer(id: element.$user.id, devices: [DeviceServer(id: element.id!, deviceID: element.deviceID, type: element.type)]))
                }
            }
            
            return users
        }
    }
}
