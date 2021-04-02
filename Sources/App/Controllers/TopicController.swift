//
//  TopicController.swift
//  
//
//  Created by Mikhail Ivanov on 02.04.2021.
//

import Vapor
import Fluent

final class TopicController {
    
    init(_ app: Application) {
        
        app.get("topic", use: getTopics)
        
        app.post(["topic", "create"], use: createTopic)
        
        app.post(["topic", "subscribe"], use: subscribeTopic)
        
        app.post(["topic", "unsubscribe"], use: unsubscribeTopic)
    }
    
    func createTopic(_ req: Request) throws -> EventLoopFuture<TopicServer> {
        let t = try req.content.decode(TopicClient.self)
        
        return TopicNotification.query(on: req.db).filter(\.$nameTopic == t.name).first().flatMap { (topic) -> EventLoopFuture<TopicServer> in
            guard let topicDB = topic else {
                let topicDB = TopicNotification(topic: t.name)
                return topicDB.create(on: req.db).map { _ -> (TopicServer) in
                    return TopicServer(id: topicDB.id!, topicName: topicDB.nameTopic)
                }
            }
            return req.eventLoop.makeSucceededFuture(TopicServer(id: topicDB.id!, topicName: topicDB.nameTopic))
        }
    }
    
    func getTopics(_ req: Request) throws -> EventLoopFuture<[TopicServer]> {
        
        var topics: [TopicServer] = []
        
        return TopicNotification.query(on: req.db).all().flatMap { (topicsDB) -> EventLoopFuture<[TopicServer]> in
            
            var usersQuery: [EventLoopFuture<Void>] = []
            
            topicsDB.forEach { (topic) in
                usersQuery.append(topic.$users.get(on: req.db).map { users in
                    
                    var topicServer = TopicServer(id: topic.id!, topicName: topic.nameTopic)
                    
                    users.forEach { (user) in
                        if topicServer.users == nil {
                            topicServer.users = []
                        }
                        
                        topicServer.users?.append(.init(id: user.id!))
                    }
                    
                    topics.append(topicServer)
                })
            }
            
            return usersQuery.flatten(on: req.eventLoop).transform(to: topics)
        }
    }
    
    func subscribeTopic(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let topic = try req.content.decode(SubTopic.self)
        
        let getTopicDB = TopicNotification.query(on: req.db).filter(\.$nameTopic == topic.name).first().unwrap(or: Abort(.notFound))
        
        return UserDevices.query(on: req.db).filter(\.$id == topic.userID).first().unwrap(or: Abort(.notFound)).and(getTopicDB).flatMap { (data) -> EventLoopFuture<HTTPStatus> in
            
            return data.0.$topics.isAttached(to: data.1, on: req.db).flatMap { (isAttached) -> EventLoopFuture<HTTPStatus> in
                if isAttached {
                    return req.eventLoop.makeSucceededFuture(HTTPStatus.ok)
                }
                
                return data.0.$topics.attach(data.1, on: req.db).map {.ok}
            }
        }
    }
    
    func unsubscribeTopic(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let topic = try req.content.decode(SubTopic.self)
        
        let getTopicDB = TopicNotification.query(on: req.db).filter(\.$nameTopic == topic.name).first().unwrap(or: Abort(.notFound))
        
        return UserDevices.query(on: req.db).filter(\.$id == topic.userID).first().unwrap(or: Abort(.notFound)).and(getTopicDB).flatMap { (data) -> EventLoopFuture<HTTPStatus> in
            
            return data.0.$topics.isAttached(to: data.1, on: req.db).flatMap { (isAttached) -> EventLoopFuture<HTTPStatus> in
                if isAttached {
                    return data.0.$topics.detach(data.1, on: req.db).map {.ok}
                }
                
                return req.eventLoop.makeSucceededFuture(HTTPStatus.ok)
            }
        }
    }
}
