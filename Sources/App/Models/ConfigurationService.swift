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
    
    public static func loadSettings(_ app: Application) -> ConfigurationService? {
        let decoder = JSONDecoder()
        
        let directory = DirectoryConfiguration.detect()
        
        let path: String = app.environment.isRelease ? "run/secrets/" : "Private/json"
        let file = "settings.json"
        var fileURL = URL(fileURLWithPath: directory.workingDirectory)
        
        if app.environment.isRelease {
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
    
    public static func loadSettingsFCM(_ app: Application) -> String? {        
        let directory = DirectoryConfiguration.detect()
        
        let path: String = app.environment.isRelease ? "run/secrets/" : "Private/json"
        let file = "FCM.json"
        var fileURL = URL(fileURLWithPath: directory.workingDirectory)
        
        if app.environment.isRelease {
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
    
    public static func loadSettingsAPNs(_ app: Application) throws -> Data {
        let directory = DirectoryConfiguration.detect()
        
        let path: String = app.environment.isRelease ? "run/secrets/" : "Private/"
        let file = "APNs.p8"
        var fileURL = URL(fileURLWithPath: directory.workingDirectory)
        
        if app.environment.isRelease {
            fileURL = fileURL.deletingLastPathComponent()
        }
        
        fileURL = fileURL.appendingPathComponent(path, isDirectory: true)
            .appendingPathComponent(file, isDirectory: false)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            throw APNSwiftError.SigningError.certificateFileDoesNotExist
        }
        
        return data
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
}
