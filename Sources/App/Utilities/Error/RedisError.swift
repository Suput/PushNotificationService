//
//  RedisError.swift
//
//
//  Created by Mikhail Ivanov on 31.05.2021.
//

import Foundation

enum RedisError: Error {
    case incorrectMessage
    case noUsersFound(id: [UUID])

}

extension RedisError: LocalizedError {
    public var statusCode: Int {
        switch self {
        case .incorrectMessage:
            return 400
        case .noUsersFound(_):
            return 404
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .incorrectMessage:
            return NSLocalizedString("Incorrect message received",
                                     comment: "Incorrect message")
        case .noUsersFound(let users):
            return NSLocalizedString("No users found: \(users)",
                                     comment: "No users found")
        }
    }
    
    private struct Data: Codable {
        var statusCode: Int
        var message: String
    }
    
    func getJson() -> String? {
        
        let data = Data(statusCode: statusCode, message: localizedDescription)
        let encoder = JSONEncoder()
        
        if let jsonData = try? encoder.encode(data) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        }
        
       return nil
    }
}
