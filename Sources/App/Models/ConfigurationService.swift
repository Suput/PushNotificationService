//
//  File.swift
//  
//
//  Created by Mikhail Ivanov on 22.03.2021.
//

import Vapor

struct ConfigurationService: Content {
    
    let apns: APNsKey
    
    let testDevice: String?
    
    let jwkURL: String?
    
    let database: DatabasesSetting
    
    public static func loadSettings(_ app: Application) -> ConfigurationService? {
        let decoder = JSONDecoder()
        
        let directory = DirectoryConfiguration.detect()
        let path: String = app.environment.isRelease ? "run/secrets/" : "Private/json"
        let file = app.environment.isRelease ? "setting" : "settings.json"
        let fileURL = URL(fileURLWithPath: directory.viewsDirectory)
            .appendingPathComponent(path, isDirectory: true)
            .appendingPathComponent(file, isDirectory: false)
        
        print(fileURL)
        
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
        let fileURL = URL(fileURLWithPath: directory.workingDirectory)
            .appendingPathComponent("Private/json", isDirectory: true)
            .appendingPathComponent("FCM.json", isDirectory: false)
        
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
}
