import Vapor
import JWTKit
import APNS
import FCM
import JWT
import Redis

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) throws {
    
    if let config = ConfigurationService.loadSettings() {
        app.logger.info("Configuration service")
        
        app.apns.configuration = try .init(
            authenticationMethod: .jwt(
                key: .private(),
                keyIdentifier: JWKIdentifier(string: config.apns.keyIdentifier),
                teamIdentifier: config.apns.teamIdentifier
            ),
            topic: config.apns.topic,
            environment: app.environment.isRelease ? .production : .sandbox
        )
        app.apns.configuration?.timeout = .minutes(1)
        
        if let fcm = ConfigurationService.loadSettingsFCM() {
            app.fcm.configuration = .init(fromJSON: fcm)
        }
        
        if let postgresURL = Environment.get("POSTGRES_URL") {
            try app.databases.use(.postgres(url: postgresURL), as: .psql)
            app.logger.info("Connection postgres")
        } else {
            app.databases.use(
                .postgres(hostname: config.database.hostname,
                          username: config.database.login,
                          password: config.database.password,
                          database: config.database.databaseName),
                as: .psql)
        }
        
        migration(app)
        
        if let redisURL = Environment.get("REDIS_URL") {
            app.redis.configuration = try RedisConfiguration(hostname: redisURL)
        } else {
            app.redis.configuration = try RedisConfiguration(hostname: config.redis.hostname)
        }
        
        if let jwtEnv = Environment.get("JWT_URL"),
           let jwksURL = URL(string: jwtEnv) {
            
            let jwksData = try Data(contentsOf: jwksURL)
            let jwks = try JSONDecoder().decode(JWKS.self, from: jwksData)
            try app.jwt.signers.use(jwks: jwks)
            
        } else if let jwkURL = config.jwkURL,
                  let jwksURL = URL(string: jwkURL) {
            
            let jwksData = try Data(contentsOf: jwksURL)
            let jwks = try JSONDecoder().decode(JWKS.self, from: jwksData)
            try app.jwt.signers.use(jwks: jwks)
        }
        
    } else {
        app.logger.critical("Missing config file")
        throw ServerError.missingConfiguration
    }
    
    try routes(app)
}

private func migration(_ app: Application) {
    app.migrations.add(CreateDevice())
    app.migrations.add(CreateUser())
    app.migrations.add(DeviceAddParentUser())
    app.migrations.add(CreateTopicNotification())
    app.migrations.add(CreateUserTopic())
    
    app.autoMigrate().whenComplete { result in
        switch result {
        case .success():
            app.logger.info("Migration complite")
        case .failure(let error):
            app.logger.error("\(error.localizedDescription)")
        }
        
        
    }
}

enum ServerError: Error {
    case missingConfiguration
}

extension ServerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return NSLocalizedString("There is no settings.json file," +
                                        "in which the main server configuration is written",
                                     comment: "Config file missing")
        }
    }
}
