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
        
//        app.post("addDevice", use: registrateDevice)
        
        app.get("devices", use: getDevices)
        
        app.delete("dropDevices", use: dropDevice)
    }
    
    func testPush(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let push = try req.content.decode(PushTest.self)
        
        let config = ConfigurationService.loadSettings()
        
        return req.apns.send(
            .init(title: push.title, subtitle: push.message),
            to: config!.testDevice
        ).map { .ok }
    }
    
//    func registrateDevice(_ req: Request) throws -> EventLoopFuture<DeviceInfo> {
//        let device = try req.content.decode(RegistrationDevice.self)
//
//        let findDevice = DeviceInfo.query(on: req.db).filter(\.$id == device.id).first()
//        return findDevice.flatMap { u -> EventLoopFuture<DeviceInfo> in
//            if u == nil {
//                let db = DeviceInfo(device)
//                return db.create(on: req.db).map {db}
//            } else {
//                if u!.deviceID.contains(where: { $0 == device.deviceID }) {
//                    return u!.update(on: req.db).map {u!}
//                }
//                u!.deviceID.append(device.deviceID)
//
//                return u!.update(on: req.db).map {u!}
//            }
//        }
//    }
    
    func dropDevice(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return DeviceInfo.query(on: req.db).delete().map{.ok}
    }
    
    func getDevices(_ req: Request) throws -> EventLoopFuture<[DeviceInfo]> {
        DeviceInfo.query(on: req.db).all()
    }
}
