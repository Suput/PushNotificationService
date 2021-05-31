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
    
    private let errorChannel: RedisChannelName = "errorInfo"
    private let pushChannel: RedisChannelName = "pushInfo"
    
    let websocket: WebSocketController
    let config: ConfigurationService
    
    var publishRedis: RedisConnection?
    
    init(_ app: Application, websocket: WebSocketController, config: ConfigurationService) throws {
        
        self.websocket = websocket
        self.config = config
        self.publishRedis = try redisConnected(app)
        
        let redis = try redisConnected(app)
        
        redis.subscribe(to: pushChannel) { channel, message in
            switch channel {
            case "pushInfo" :
                app.logger.info("redis: Message is received")
                if let mess = message.string?.data(using: .utf8) {
                    do {
                        let result = try JSONDecoder().decode(RedisPushModel.self, from: mess)
                        
                        try self.pushToUsers(app, model: result).whenSuccess {}
                        
                    } catch {
                        app.logger.error("redis: Incorrect message")
                        
                        self.errorRedis(message: .incorrectMessage)
                    }
                }
            default: break
            }
        }.whenComplete { result in
            switch result {
            case .success():
                app.logger.info("Redis subscribe")
            case .failure(let error):
                app.logger.error("redis: \(error.localizedDescription)")
            }
        }
    }
    
    func redisConnected(_ app: Application) throws -> RedisConnection {
        let eventLoop = app.eventLoopGroup.next()
        
        return try RedisConnection.make(configuration: config.redisConfig(app),
                                 boundEventLoop: eventLoop)
            .flatMapErrorThrowing { error in
                app.logger.error("Not redis connection: \(error.localizedDescription)")
                throw ServerError.noRedisConnection
            }.wait()
    }
    
    func errorRedis(message: RedisError) {
        if let redis = self.publishRedis,
           let error = message.getJson() {
            redis.publish(error, to: self.errorChannel)
        }
    }
    
    func pushToUsers(_ app: Application, model: RedisPushModel) throws -> EventLoopFuture<Void> {
        
        DeviceInfo.query(on: app.db).group(.or) { group in
            model.users.forEach {group.filter(\.$user.$id == $0)}
        }.all().flatMap { devices -> EventLoopFuture<Void> in
            self.assemblyDevice(app, devices: devices, message: model.message).flatten(on: app.eventLoopGroup.next())
        }.map {
            self.assemblyWebSocket(usersId: model.users, message: model.message)
        }
    }
    
    func assemblyDevice(_ app: Application, devices: [DeviceInfo], message: RedisPushMessageModel)
    -> [EventLoopFuture<Void>] {
        var task: [EventLoopFuture<Void>] = []
        
        devices.forEach { device in
            
            switch device.type {
            case .ios:
                task.append(assemblyIOSDevice(app, device: device, message: message))
                
            case .android:
                task.append(assemblyAndroidDevice(app, device: device, message: message))
                
            }
            
        }
        
        return task
    }
    
    func assemblyIOSDevice(_ app: Application, device: DeviceInfo, message: RedisPushMessageModel)
    -> EventLoopFuture<Void> {
        let alert = APNSwiftAlert(title: message.title, body: message.body)
        return app.apns.send(.init(alert: alert,
                                   badge: 0,
                                   sound: .normal("cow.wav")),
                             to: device.deviceID)
            .flatMapError { (err) -> EventLoopFuture<Void> in
                if let error = err as? APNSwiftError.ResponseError {
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
    
    func assemblyAndroidDevice(_ app: Application, device: DeviceInfo, message: RedisPushMessageModel)
    -> EventLoopFuture<Void> {
        let notification = FCMNotification(title: message.title, body: message.body)
        let message = FCMMessage(token: device.deviceID, notification: notification)
        
        return app.fcm.send(message).flatMapAlways { (result) in
            switch result {
            case .failure(let err):
                if let error = err as? GoogleError,
                   error.code == 404 || error.code == 410 {
                    app.logger.info("Device \(String(describing: device.id!)) of type Android has been removed from the database")
                    return device.delete(on: app.db)
                }
            case .success(_):
                break
            }
            
            return app.eventLoopGroup.future()
        }
    }
    
    func assemblyWebSocket(usersId: [UUID], message: RedisPushMessageModel) {
        websocket.sockets.filter {usersId.contains($0.userId)}
            .forEach { wSocket in
                if let jsonData = try? JSONEncoder().encode(message) {
                    let jsonString = String(data: jsonData, encoding: .utf8)!
                    wSocket.socket.send(jsonString)
                }
            }
        
        let socketsUsers = websocket.sockets.map {$0.userId}
        let notUsers = usersId.filter { !sockets.contains($0) }
        
        if !notUsers.isEmpty {
            self.errorRedis(message: .noUsersFound(id: notUsers))
        }
    }
}
