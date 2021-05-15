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

        app.webSocket("push", ":userId") { req, wSocket in

            if let userId = req.parameters.get("userId"), let uuid = UUID(uuidString: userId) {
                wSocket.send("Connected")

                let idConnection = UUID()
                self.sockets.append(.init(id: idConnection, socket: wSocket, user: uuid))
                
                wSocket.onClose.map {
                    self.sockets.removeAll { $0.id == idConnection }
                }.whenComplete {_ in}

            } else {
                wSocket.send("Invalid user id")
                wSocket.close().whenComplete {_ in}
            }
        }
    }
}
