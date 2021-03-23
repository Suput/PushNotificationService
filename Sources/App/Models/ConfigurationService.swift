//
//  File.swift
//  
//
//  Created by Mikhail Ivanov on 22.03.2021.
//

import Vapor

struct ConfigurationService: Content {
    
    let apns: APNsKey
    
    let testDevice: String
    
    let database: DatabasesSetting
   
    public static func loadSettings() -> ConfigurationService? {
        let decoder = JSONDecoder()
        
        let directory = DirectoryConfiguration.detect()
                let fileURL = URL(fileURLWithPath: directory.workingDirectory)
                    .appendingPathComponent("Private/json", isDirectory: true)
                    .appendingPathComponent("settings.json", isDirectory: false)
        
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
}
