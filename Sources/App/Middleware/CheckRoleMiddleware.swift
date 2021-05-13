//
//  CheckRoleMiddleware.swift
//
//
//  Created by Mikhail Ivanov on 13.05.2021.
//

import Vapor

struct CheckRoleMiddleware: Middleware {
    
    let role: String
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        if let user = request.auth.get(UserAuthInfo.self),
           user.role.contains(role) {
            return next.respond(to: request)
        }
        
        return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
    }
}
