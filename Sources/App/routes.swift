import Vapor

func routes(_ app: Application) throws {
    
    let _ = UserController(app)
    
    let _ = TopicController(app)
    
    let _ = try PushController(app)

}
