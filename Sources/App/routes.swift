import Vapor

func routes(_ app: Application) throws {

    let socket = WebSocketController(app)

    _ = UserController(app)

    _ = TopicController(app)

    _ = PushController(app, websocket: socket)

    _ = try RedisController(app, websocket: socket)
}
