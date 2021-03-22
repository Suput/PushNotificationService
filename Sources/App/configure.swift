import Vapor
import JWTKit
import APNS

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    if let config = APNsConfiguration.loadSettings() {
        app.apns.configuration = try .init(
            authenticationMethod: .jwt(
                key: .private(filePath: "Resources/APNs.p8"),
                keyIdentifier: JWKIdentifier(string: config.apns.keyIdentifier),
                teamIdentifier: config.apns.teamIdentifier
            ),
            topic: "test",
            environment: .sandbox
        )
    }
    // register routes
    try routes(app)
}

struct APNsConfiguration: Content {
    
    let apns: APNsKey
    
    struct APNsKey: Content {
        let keyIdentifier: String
        let teamIdentifier: String
    }
    
    public static func loadSettings() -> APNsConfiguration? {
        let decoder = JSONDecoder()
        
        let directory = DirectoryConfiguration.detect()
                let fileURL = URL(fileURLWithPath: directory.workingDirectory)
                    .appendingPathComponent("Resources/json", isDirectory: true)
                    .appendingPathComponent("settings.json", isDirectory: false)
        
        guard
            let data = try? Data(contentsOf: fileURL),
            let persone = try? decoder.decode(APNsConfiguration.self, from: data)
        else {
            return nil
        }

        return persone
    }
}
