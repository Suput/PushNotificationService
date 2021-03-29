import Vapor
import JWTKit
import APNS
import JWT

import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) throws {
    
    if let config = ConfigurationService.loadSettings() {
        app.logger.info("Configuration APNs and Database")
        app.apns.configuration = try .init(
            authenticationMethod: .jwt(
                key: .private(filePath: "Private/APNs.p8"),
                keyIdentifier: JWKIdentifier(string: config.apns.keyIdentifier),
                teamIdentifier: config.apns.teamIdentifier
            ),
            topic: config.apns.topic,
            environment: .sandbox
        )
        
        app.databases.use(.postgres(hostname: config.database.hostname, username: config.database.login, password: config.database.password, database: config.database.databaseName), as: .psql)
        
        migration(app)
        
        if let jwkURL = config.jwkURL {
            let jwksData = try Data(
                contentsOf: URL(string: jwkURL)!
            )
            
            // Decode the downloaded JSON.
            let jwks = try JSONDecoder().decode(JWKS.self, from: jwksData)
            
            // Create signers and add JWKS.
            try app.jwt.signers.use(jwks: jwks)
            //        print(jwks)
        }
        
    } else {
        app.logger.critical("Missing config file")
    }
    
    try routes(app)
}


fileprivate func migration(_ app: Application) {
    app.migrations.add(CreateDevice())
    app.migrations.add(CreateUser())
    app.migrations.add(Device_AddParentUser())
}
