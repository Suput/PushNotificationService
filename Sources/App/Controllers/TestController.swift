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
    }
    
    func initPage(_ req: Request) throws -> String {
        return "It works!"
    }
}
