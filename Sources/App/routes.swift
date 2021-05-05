import Vapor

func routes(_ app: Application) throws {
    
    let socket = WebSocketController(app)
    
    let _ = UserController(app)
    
    let _ = TopicController(app)
    
    let _ = PushController(app, websocket: socket)
    
    let _ = try RedisController(app, websocket: socket)
}
