//
//  PushController.swift
//  
//
//  Created by Mikhail Ivanov on 23.03.2021.
//

import Vapor
import Fluent
import FCM
import APNS
import JWT
import Redis

final class PushController {
    
    init(_ app: Application) throws {
        app.post(["push", "user"], use: pushToUser)
        
        app.post(["push", "topic"], use: pushToTopic)
        
        try app.boot() // TODO: We have to wait for the Redis package update
        
        app.redis.subscribe(to: "chanal1") { channel, message in
            switch channel {
            case "chanal1" :
                print(message)
                break
            default: break
            }
        }.whenComplete { result in
            print("redis")
        }
        
    }
    
    func pushToUser(_ req: Request) throws -> HTTPStatus {
        let push = try req.content.decode(PushToUserClient.self)
        
        let task: EventLoopFuture<Void> = DeviceInfo.query(on: req.db).filter(\.$user.$id == push.userID).all().flatMap { (devices) -> EventLoopFuture<Void> in
            
            return self.assemblyDevice(req, devices: devices, message: push.push).flatten(on: req.eventLoop)
            
        }
        
        task.whenComplete { (result) in
            req.logger.info("Notification requests completed")
        }
        
        return .ok
    }
    
    func pushToTopic(_ req: Request) throws -> HTTPStatus {
        let push = try req.content.decode(PushToTopicClient.self)
        
        let task: EventLoopFuture<Void> = TopicNotification.query(on: req.db).filter(\.$id == push.topicID).first().unwrap(or: Abort(.notFound)).flatMap { (topic) -> EventLoopFuture<Void> in
            
            return topic.$users.get(reload: true, on: req.db).flatMap { (users) -> EventLoopFuture<Void> in
                
                var topicTask: [EventLoopFuture<Void>] = []
                
                users.forEach { user in
                    topicTask.append(user.$devices.get(on: req.db).flatMap { (devices) -> EventLoopFuture<Void> in
                        
                        return self.assemblyDevice(req, devices: devices, message: push.push).flatten(on: req.eventLoop)
                    })
                }
                
                return topicTask.flatten(on: req.eventLoop)
            }
        }
        
        task.whenComplete { (result) in
            req.logger.info("Notification requests completed")
        }
        
        return .ok
    }
    
    func assemblyDevice(_ req: Request, devices: [DeviceInfo], message: PushMessage) -> [EventLoopFuture<Void>] {
        var task: [EventLoopFuture<Void>] = []
        
        devices.forEach { device in
            switch device.type {
            case .ios:
                task.append(
                    req.apns.send(
                        .init(title: message.title, subtitle: nil, body: message.message),
                        to: device.deviceID
                    ).flatMapError{ (e) -> EventLoopFuture<Void> in
                        if let error = e as? APNSwiftError.ResponseError {
                            switch error {
                            case .badRequest(.badDeviceToken):
                                req.logger.info("Device \(String(describing: device.id!)) of type iOS has been removed from the database")
                                return device.delete(on: req.db)
                            default:
                                break
                            }
                        }
                        
                        return req.eventLoop.makeSucceededVoidFuture()
                    })
                break
                
            case .android:
                let notification = FCMNotification(title: message.title, body: message.message)
                let message = FCMMessage(token: device.deviceID, notification: notification)
                
                task.append(req.fcm.send(message).flatMapAlways{ (result) in
                    switch result {
                    case .failure(let e):
                        if let error = e as? GoogleError,
                           error.code == 404 || error.code == 410 {
                            req.logger.info("Device \(String(describing: device.id!)) of type Android has been removed from the database")
                            return device.delete(on: req.db)
                        }
                        break
                    case .success(_):
                        break
                    }
                    return req.eventLoop.makeSucceededVoidFuture()
                })
                break
            }
            
        }
        
        return task
    }
}
