import Vapor

func routes(_ app: Application) throws {

    app.get { _ -> String in
        return "I'm push service"
    }
    
    let socket = WebSocketController(app)

    _ = UserController(app)

    _ = PushController(app, websocket: socket)

    _ = try RedisController(app, websocket: socket)
}
