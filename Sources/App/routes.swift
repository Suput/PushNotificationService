import Vapor

func routes(_ app: Application) throws {
    
    let _ = DeviceController(app)
    
    let _ = TopicController(app)
}
