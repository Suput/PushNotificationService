//
//  File.swift
//
//
//  Created by Mikhail Ivanov on 22.03.2021.
//

import Vapor
import APNS
import FCM
import JWT
import Redis
import Fluent
import FluentPostgresDriver

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct ConfigurationService: Content {

    let apns: APNsKey

    let jwkURL: String?

    let database: DatabasesSetting

    let redis: RedisSetting

    public static func loadSettings() -> ConfigurationService? {
        let decoder = JSONDecoder()

        let directory = DirectoryConfiguration.detect()

        let file = "settings.json"
        var fileURL = URL(fileURLWithPath: directory.workingDirectory)
        
        var path: String = "Private/json/"

        if let secretPath = Environment.get("PATH_SECRETS") {
            path = secretPath
            fileURL = fileURL.deletingLastPathComponent()
        }

        fileURL = fileURL.appendingPathComponent(path, isDirectory: true)
            .appendingPathComponent(file, isDirectory: false)

        guard
            let data = try? Data(contentsOf: fileURL),
            let persone = try? decoder.decode(ConfigurationService.self, from: data)
        else {
            return nil
        }

        return persone
    }
}

extension ConfigurationService {
    struct APNsKey: Content {
        let keyIdentifier: String
        let teamIdentifier: String
        let topic: String
    }

    struct DatabasesSetting: Content {
        let hostname: String
        let login: String
        let password: String
        let databaseName: String
    }
    struct RedisSetting: Content {
        let hostname: String
    }
}

extension ConfigurationService {
    
    func fcm(_ app: Application) throws {
        let directory = DirectoryConfiguration.detect()

        let file = "FCM.json"
        var fileURL = URL(fileURLWithPath: directory.workingDirectory)
        
        var path: String = "Private/json/"

        if let secretPath = Environment.get("PATH_SECRETS") {
            path = secretPath
            fileURL = fileURL.deletingLastPathComponent()
        }

        fileURL = fileURL.appendingPathComponent(path, isDirectory: true)
            .appendingPathComponent(file, isDirectory: false)

        guard
            let data = try? Data(contentsOf: fileURL)
        else {
            return
        }
        
        let fcm = String(decoding: data, as: UTF8.self)
        app.fcm.configuration = .init(fromJSON: fcm)
    }
    
    func apns(_ app: Application) throws {
        app.apns.configuration = try .init(
            authenticationMethod: .jwt(
                key: .private(),
                keyIdentifier: JWKIdentifier(string: apns.keyIdentifier),
                teamIdentifier: apns.teamIdentifier
            ),
            topic: apns.topic,
            environment: app.environment.isRelease ? .production : .sandbox
        )
        app.apns.configuration?.timeout = .minutes(1)
    }
    
    func redis(_ app: Application) throws {
        if let redisURL = Environment.get("REDIS_URL") {
            app.redis.configuration = try RedisConfiguration(url: redisURL)
        } else {
            app.redis.configuration = try RedisConfiguration(hostname: redis.hostname)
        }
    }
    
    func jwt(_ app: Application) throws {
        if let jwtEnv = Environment.get("JWT_URL"),
           let jwksURL = URL(string: jwtEnv) {
            
            let jwksData = try Data(contentsOf: jwksURL)
            let jwks = try JSONDecoder().decode(JWKS.self, from: jwksData)
            try app.jwt.signers.use(jwks: jwks)
            
        } else if let jwkURL = jwkURL,
                  let jwksURL = URL(string: jwkURL) {
            
            let jwksData = try Data(contentsOf: jwksURL)
            let jwks = try JSONDecoder().decode(JWKS.self, from: jwksData)
            try app.jwt.signers.use(jwks: jwks)
        }
    }
    
    func postgres(_ app: Application) throws {
        if let postgresURL = Environment.get("POSTGRES_URL") {
            try app.databases.use(.postgres(url: postgresURL), as: .psql)
        } else {
            app.databases.use(
                .postgres(hostname: database.hostname,
                          username: database.login,
                          password: database.password,
                          database: database.databaseName),
                as: .psql)
        }
        
        migration(app)
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
}

extension ECDSAKey {
    
    public static func `private`() throws -> JWTKit.ECDSAKey {
        let directory = DirectoryConfiguration.detect()
        
        var path: String = "Private/"
        
        if let secretPath = Environment.get("PATH_SECRETS") {
            path = secretPath
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
