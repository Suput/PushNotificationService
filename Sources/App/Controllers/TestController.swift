//
//  File.swift
//  
//
//  Created by Mikhail Ivanov on 23.03.2021.
//

import Vapor
import Fluent

final class TestController {
    init(_ app: Application) {
        
        app.get(use: initPage)
        
        app.get("hello") { req -> String in
            return "Hello, world!"
        }
        
        app.post("galaxies") { req -> EventLoopFuture<Galaxy> in
            let galaxy = try req.content.decode(Galaxy.self)
            return galaxy.create(on: req.db)
                .map { galaxy }
        }
        
        app.get("galaxies") { req in
            Galaxy.query(on: req.db).all()
        }
    }
    
    func initPage(_ req: Request) throws -> String {
        return "It works!"
    }
}
