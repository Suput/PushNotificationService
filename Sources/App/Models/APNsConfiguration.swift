//
//  File.swift
//  
//
//  Created by Mikhail Ivanov on 22.03.2021.
//

import Vapor

struct APNsConfiguration: Content {
    
    let apns: APNsKey
    
    let testDevice: String
    
    struct APNsKey: Content {
        let keyIdentifier: String
        let teamIdentifier: String
        let topic: String
    }
    
    public static func loadSettings() -> APNsConfiguration? {
        let decoder = JSONDecoder()
        
        let directory = DirectoryConfiguration.detect()
                let fileURL = URL(fileURLWithPath: directory.workingDirectory)
                    .appendingPathComponent("Resources/json", isDirectory: true)
                    .appendingPathComponent("settings.json", isDirectory: false)
        
        guard
            let data = try? Data(contentsOf: fileURL),
            let persone = try? decoder.decode(APNsConfiguration.self, from: data)
        else {
            return nil
        }

        return persone
    }
}
