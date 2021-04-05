import Vapor
import JWTKit
import APNS
import FCM
import JWT

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) throws {
    
    if let config = ConfigurationService.loadSettings() {
        app.logger.info("Configuration APNs and Database")
        
        app.apns.configuration = try .init(
            authenticationMethod: .jwt(
                key: .private(),
                keyIdentifier: JWKIdentifier(string: config.apns.keyIdentifier),
                teamIdentifier: config.apns.teamIdentifier
            ),
            topic: config.apns.topic,
            environment: .sandbox
        )
        app.apns.configuration?.timeout = .minutes(1)
        
        if let fcm = ConfigurationService.loadSettingsFCM() {
            app.fcm.configuration = .init(fromJSON: fcm)
        }
        
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
        throw ServerError.missingConfiguration
    }
    
    try routes(app)
}


fileprivate func migration(_ app: Application) {
    app.migrations.add(CreateDevice())
    app.migrations.add(CreateUser())
    app.migrations.add(Device_AddParentUser())
    app.migrations.add(CreateTopicNotification())
    app.migrations.add(CreateUserTopic())
}

extension ECDSAKey {
    
    public static func `private`() throws -> JWTKit.ECDSAKey {
        let directory = DirectoryConfiguration.detect()
        
        var path: String = "Private/"
        
        if let p = Environment.get("PATH_SECRETS") {
            path = p
        }
        
        let file = "APNs.p8"
        var fileURL = URL(fileURLWithPath: directory.workingDirectory)
        
        if Environment.get("PATH_SECRETS") != nil {
            fileURL = fileURL.deletingLastPathComponent()
        }
        
        fileURL = fileURL.appendingPathComponent(path, isDirectory: true)
            .appendingPathComponent(file, isDirectory: false)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            throw APNSwiftError.SigningError.certificateFileDoesNotExist
        }
        return try .private(pem: data)
    }
}

enum ServerError: Error {
    case missingConfiguration
}

extension ServerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return NSLocalizedString("There is no settings.json file, in which the main server configuration is written", comment: "Config file missing")
        }
    }
}
