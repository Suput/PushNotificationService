import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }
    
    app.post("test-push") { req -> EventLoopFuture<HTTPStatus> in
        let push = try req.content.decode(PushTest.self)
        
        let config = APNsConfiguration.loadSettings()
        
        return req.apns.send(
            .init(title: push.title, subtitle: push.message),
            to: config!.testDevice
        ).map { .ok }
    }
}
