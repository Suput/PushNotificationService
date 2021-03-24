import Vapor
import JWTKit
import APNS

import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
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
        
    } else {
        app.logger.error("Missing config file")
    }
    // register routes
    try routes(app)
}


fileprivate func migration(_ app: Application) {
    app.migrations.add(CreateDevice())
    app.migrations.add(CreateUser())
    app.migrations.add(UpdateDevice())
    app.migrations.add(UpdateUser())
}
