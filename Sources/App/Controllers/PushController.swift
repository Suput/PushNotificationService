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

    let websocket: WebSocketController

    init(_ app: Application, websocket: WebSocketController) {

        self.websocket = websocket
        
        app.group("push") { route in
            route.post("user", use: pushToUser)

            route.post("topic", use: pushToTopic)
        }
    }

    func pushToUser(_ req: Request) throws -> HTTPStatus {
        let push = try req.content.decode(PushToUserClient.self)

        let task: EventLoopFuture<Void> = DeviceInfo.query(on: req.db)
        .filter(\.$user.$id == push.userID).all()
        .flatMap { (devices) -> EventLoopFuture<Void> in

            self.assemblyDevice(req, devices: devices, message: push.push).flatten(on: req.eventLoop)
                .map {
                    self.assemblyWebSocket(usersId: push.userID, message: push.push)
                }

        }

        task.whenComplete { (_) in
            req.logger.info("Notification requests completed")
        }

        return .ok
    }

    func pushToTopic(_ req: Request) throws -> HTTPStatus {
        let push = try req.content.decode(PushToTopicClient.self)

        let task: EventLoopFuture<Void> = TopicNotification.query(on: req.db)
        .filter(\.$id == push.topicID).first()
        .unwrap(or: Abort(.notFound)).flatMap { (topic) -> EventLoopFuture<Void> in

            topic.$users.get(reload: true, on: req.db).flatMap { (users) -> EventLoopFuture<Void> in

                var topicTask: [EventLoopFuture<Void>] = []

                users.forEach { user in
                    topicTask.append(user.$devices.get(on: req.db).flatMap { (devices) -> EventLoopFuture<Void> in

                        self.assemblyDevice(req, devices: devices, message: push.push).flatten(on: req.eventLoop)
                    })
                }

                return topicTask.flatten(on: req.eventLoop)
                    .map {
                        let usersId = users.map { $0.id! }
                        self.assemblyWebSocket(usersId: usersId, message: push.push)
                    }
            }
        }

        task.whenComplete { (_) in
            req.logger.info("Notification requests completed")
        }

        return .ok
    }

    func assemblyDevice(_ req: Request, devices: [DeviceInfo], message: PushMessage) -> [EventLoopFuture<Void>] {
        var task: [EventLoopFuture<Void>] = []

        devices.forEach { device in
            switch device.type {
            case .ios:
                task.append(assemblyIOSDevice(req, device: device, message: message))

            case .android:
                task.append(assemblyAndroidDevice(req, device: device, message: message))
            }
        }

        return task
    }

    func assemblyIOSDevice(_ req: Request, device: DeviceInfo, message: PushMessage) -> EventLoopFuture<Void> {
        req.apns.send(
            .init(title: message.title, subtitle: nil, body: message.message),
            to: device.deviceID
        ).flatMapError { (err) -> EventLoopFuture<Void> in
            if let error = err as? APNSwiftError.ResponseError {
                switch error {
                case .badRequest(.badDeviceToken):
                    req.logger.info("Device \(String(describing: device.id!)) of type iOS has been removed from the database")
                    return device.delete(on: req.db)
                default:
                    break
                }
            }

            return req.eventLoop.makeSucceededVoidFuture()
        }
    }

    func assemblyAndroidDevice(_ req: Request, device: DeviceInfo, message: PushMessage) -> EventLoopFuture<Void> {
        let notification = FCMNotification(title: message.title, body: message.message)
        let message = FCMMessage(token: device.deviceID, notification: notification)

        return req.fcm.send(message).flatMapAlways { (result) in
            switch result {
            case .failure(let err):
                if let error = err as? GoogleError,
                   error.code == 404 || error.code == 410 {
                    req.logger.info("Device \(String(describing: device.id!)) of type Android has been removed from the database")
                    return device.delete(on: req.db)
                }
            case .success(_):
                break
            }

            return req.eventLoop.makeSucceededVoidFuture()
        }
    }

    func assemblyWebSocket(usersId: [UUID], message: PushMessage) {
        websocket.sockets.filter {usersId.contains($0.user)}
            .forEach { wSocket in
                if let jsonData = try? JSONEncoder().encode(message) {
                    let jsonString = String(data: jsonData, encoding: .utf8)!
                    wSocket.socket.send(jsonString)
                }
            }
    }

    func assemblyWebSocket(usersId: UUID..., message: PushMessage) {
        assemblyWebSocket(usersId: usersId, message: message)
    }
}
