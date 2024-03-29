//
//  File.swift
//  
//
//  Created by Mikhail Ivanov on 22.03.2021.
//

import Vapor
import APNS

struct ConfigurationService: Content {

    let apns: APNsKey

    let testDevice: String?

    let jwkURL: String?

    let database: DatabasesSetting

    let redis: RedisSetting

    public static func loadSettings() -> ConfigurationService? {
        let decoder = JSONDecoder()

        let directory = DirectoryConfiguration.detect()

        var path: String = "Private/json/"

        if let secretPath = Environment.get("PATH_SECRETS") {
            path = secretPath
        }

        let file = "settings.json"
        var fileURL = URL(fileURLWithPath: directory.workingDirectory)

        if Environment.get("PATH_SECRETS") != nil {
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

    public static func loadSettingsFCM() -> String? {
        let directory = DirectoryConfiguration.detect()

        var path: String = "Private/json/"

        if let secretPath = Environment.get("PATH_SECRETS") {
            path = secretPath
        }

        let file = "FCM.json"
        var fileURL = URL(fileURLWithPath: directory.workingDirectory)

        if Environment.get("PATH_SECRETS") != nil {
            fileURL = fileURL.deletingLastPathComponent()
        }

        fileURL = fileURL.appendingPathComponent(path, isDirectory: true)
            .appendingPathComponent(file, isDirectory: false)

        guard
            let data = try? Data(contentsOf: fileURL)
        else {
            return nil
        }

        return String(decoding: data, as: UTF8.self)
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
