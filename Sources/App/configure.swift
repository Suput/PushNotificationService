import Vapor
import JWTKit
import APNS

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    if let config = APNsConfiguration.loadSettings() {
        app.apns.configuration = try .init(
            authenticationMethod: .jwt(
                key: .private(filePath: "Private/APNs.p8"),
                keyIdentifier: JWKIdentifier(string: config.apns.keyIdentifier),
                teamIdentifier: config.apns.teamIdentifier
            ),
            topic: config.apns.topic,
            environment: .sandbox
        )
    }
    // register routes
    try routes(app)
}
