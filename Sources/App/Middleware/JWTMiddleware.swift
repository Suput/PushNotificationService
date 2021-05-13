//
//  JWTMiddleware.swift
//
//
//  Created by Mikhail Ivanov on 13.05.2021.
//

import Vapor

struct JWTMiddleware: BearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request)
    -> EventLoopFuture<Void> {
        request.jwt.itLab.verify(bearer.token).flatMapAlways {
            switch $0 {
            case .success(let playload):
                if let userID = UUID(uuidString: playload.subject.value) {
                    request.auth.login(UserAuthInfo(id: userID,
                                                    role: playload.role))
                    
                    return request.eventLoop.makeSucceededVoidFuture()
                }
                
                return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
                
            case .failure(_):
                return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
            }
        }
    }
}
