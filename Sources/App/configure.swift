import Vapor

// configures your application
public func configure(_ app: Application) throws {
    
    if let config = ConfigurationService.loadSettings() {
        app.logger.info("Configuration service")
        
        // APNs configuration
        try config.apns(app)
        
        // Firebase configuration
        try config.fcm(app)
        
        // Postgres configuration
        try config.postgres(app)
        
        // JWKs configuration
        try config.jwt(app)
        
        try routes(app, config: config)
        
        try jobs(app)
        
    } else {
        app.logger.critical("Missing config file")
        throw ServerError.missingConfiguration
    }
    
}
