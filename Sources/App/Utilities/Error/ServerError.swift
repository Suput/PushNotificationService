//
//  ServerError.swift
//  
//
//  Created by Mikhail Ivanov on 31.05.2021.
//

import Foundation

enum ServerError: Error {
    case missingConfiguration, noRedisConnection
}

extension ServerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return NSLocalizedString("There is no settings.json file," +
                                        "in which the main server configuration is written",
                                     comment: "Config file missing")
        case .noRedisConnection:
            return NSLocalizedString("There is no connection to the Redis service",
                                     comment: "No connection to redis")
        }
    }
}
