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
        
        app.post(["topic", "create"], use: createTopic)
        app.get("topic", use: getTopics)
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
                        topicServer.users?.append(.init(id: user.id!))
                    }
                    
                    topics.append(topicServer)
                })
            }
            
            return usersQuery.flatten(on: req.eventLoop).transform(to: topics)
        }
    }
}
