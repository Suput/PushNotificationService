//
//  RedisController.swift
//  
//
//  Created by Михаил Иванов on 04.05.2021.
//

import Vapor
import Fluent
import FCM
import APNS
import Redis

class RedisController {

    let websocket: WebSocketController
    
    init(_ app: Application, websocket: WebSocketController) throws {
        
        self.websocket = websocket
        
        try app.boot() // TODO: We have to wait for the Redis package update
        
        app.redis.subscribe(to: "chanal1") { channel, message in
            switch channel {
            case "chanal1" :
                if let m = message.string?.data(using: .utf8) {
                    do {
                        let result = try JSONDecoder().decode(RedisPushModel.self, from: m)
                        
                        try self.pushToUsers(app, model: result).whenSuccess {}
                        
                    } catch {
                        print("FAIL")
                    }
                }
                break
            default: break
            }
        }.whenComplete { result in
            app.logger.info("Redis subscribe")
        }
        
    }
    
    func pushToUsers(_ app: Application, model: RedisPushModel) throws -> EventLoopFuture<Void> {
        
        return DeviceInfo.query(on: app.db).group(.or) { group in
            model.users.forEach {group.filter(\.$user.$id == $0)}
        }.all().flatMap { devices -> EventLoopFuture<Void> in
            self.assemblyDevice(app, devices: devices, message: model.message).flatten(on: app.eventLoopGroup.next())
        }.map {
            self.assemblyWebSocket(usersId: model.users, message: model.message)
        }
    }
    
    func assemblyDevice(_ app: Application, devices: [DeviceInfo], message: RedisPushMessageModel) -> [EventLoopFuture<Void>] {
        var task: [EventLoopFuture<Void>] = []
        
        devices.forEach { device in
            
            switch device.type {
            case .ios:
                task.append(assemblyIOSDevice(app, device: device, message: message))
                break
                
            case .android:
                task.append(assemblyAndroidDevice(app, device: device, message: message))
                break
            }
            
        }
        
        return task
    }
    
    func assemblyIOSDevice(_ app: Application, device: DeviceInfo, message: RedisPushMessageModel) -> EventLoopFuture<Void> {
        app.apns.send(
            .init(title: message.title, subtitle: nil, body: message.body),
            to: device.deviceID
        ).flatMapError{ (e) -> EventLoopFuture<Void> in
            if let error = e as? APNSwiftError.ResponseError {
                switch error {
                case .badRequest(.badDeviceToken):
                    app.logger.info("Device \(String(describing: device.id!)) of type iOS has been removed from the database")
                    return device.delete(on: app.db)
                default:
                    break
                }
            }
            
            return app.eventLoopGroup.future()
        }
    }
    
    func assemblyAndroidDevice(_ app: Application, device: DeviceInfo, message: RedisPushMessageModel) -> EventLoopFuture<Void> {
        let notification = FCMNotification(title: message.title, body: message.body)
        let message = FCMMessage(token: device.deviceID, notification: notification)
        
        return app.fcm.send(message).flatMapAlways{ (result) in
            switch result {
            case .failure(let e):
                if let error = e as? GoogleError,
                   error.code == 404 || error.code == 410 {
                    app.logger.info("Device \(String(describing: device.id!)) of type Android has been removed from the database")
                    return device.delete(on: app.db)
                }
                break
            case .success(_):
                break
            }
            
            return app.eventLoopGroup.future()
        }
    }
    
    func assemblyWebSocket(usersId: [UUID], message: RedisPushMessageModel) {
        websocket.sockets.filter {usersId.contains($0.user)}
            .forEach { ws in
                let jsonData = try! JSONEncoder().encode(message)
                let jsonString = String(data: jsonData, encoding: .utf8)!
                ws.socket.send(jsonString)
            }
    }
}
