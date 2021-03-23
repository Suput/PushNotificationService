import Vapor
import Fluent

func routes(_ app: Application) throws {
    
    let _ = DeviceController(app)
    let _ = TestController(app)
}
