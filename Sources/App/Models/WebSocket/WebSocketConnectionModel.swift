//
//  WebSocketConnectionModel.swift
//  
//
//  Created by Михаил Иванов on 04.05.2021.
//

import Vapor

struct WebSocketConnectionModel {
    var socket: WebSocket
    var user: UUID
}
