//
//  JWT.swift
//
//
//  Created by Mikhail Ivanov on 29.03.2021.
//

import Vapor
import JWT

struct ITLabPayload: JWTPayload {
    // Maps the longer Swift property names to the
    // shortened keys used in the JWT payload.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case role = "role"
        case scope = "scope"
    }

    // The "sub" (subject) claim identifies the principal that is the
    // subject of the JWT.
    var subject: SubjectClaim

    var expiration: ExpirationClaim

    var role: [String]

    var scope: [String]

    // Run any additional verification logic beyond
    // signature verification here.
    // Since we have an ExpirationClaim, we will
    // call its verify method.
    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}

extension ITLabPayload {
    static func checkJWT(_ req: Request) throws -> UUID {
        let jwt = try req.jwt.verify(as: ITLabPayload.self)
        
        guard let userID = UUID(uuidString: jwt.subject.value)
        else {
            req.logger.error("Invalid user id")
            throw Abort(.unauthorized)
        }
        
        return userID
    }
    
    static func checkJWT(_ req: Request) throws -> ITLabPayload {
        return try req.jwt.verify(as: ITLabPayload.self)
    }
}
