//
//  WebSocketController.swift
//  
//
//  Created by Михаил Иванов on 04.05.2021.
//

import Vapor

class WebSocketController {
    
    public var sockets: [WebSocketConnectionModel] = []
    
    init(_ app: Application) {
        
        app.webSocket("push", ":userId") { req, ws in
            
            if let userId = req.parameters.get("userId"), let uuid = UUID(uuidString: userId) {
                ws.send("Connected")
                
                self.sockets.append(.init(socket: ws, user: uuid))
                
                ws.onClose.map {
                    self.sockets.removeAll { $0.user == uuid }
                }.whenComplete {_ in}
                
            } else {
                ws.send("Invalid user id")
                ws.close().whenComplete {_ in}
            }
        }
    }
}
