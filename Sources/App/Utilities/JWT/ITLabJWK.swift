//
//  ITLabJWK.swift
//
//
//  Created by Mikhail Ivanov on 13.05.2021.
//

import Vapor
import JWTKit

// swiftlint:disable nesting
extension Request.JWT {
    public var itLab: ITLab {
        .init(jwt: self)
    }

    public struct ITLab {
        public let jwt: Request.JWT

        public func verify() -> EventLoopFuture<ITLabPayload> {
            guard let token = self.jwt._request.headers.bearerAuthorization?.token else {
                self.jwt._request.logger.error("Request is missing JWT bearer header.")
                return self.jwt._request.eventLoop.makeFailedFuture(Abort(.unauthorized))
            }
            return self.verify(token)
        }

        public func verify(_ message: String) -> EventLoopFuture<ITLabPayload> {
            self.verify([UInt8](message.utf8))
        }

        public func verify<Message>(_ message: Message) -> EventLoopFuture<ITLabPayload>
            where Message: DataProtocol {
            self.jwt._request.application.jwt.itLab.signers(
                on: self.jwt._request
            ).flatMapThrowing { signers in
                let token = try signers.verify(message, as: ITLabPayload.self)
                return token
            }
        }
    }
}

extension Application.JWT {
    
    public var itLab: ITLab {
        .init(jwt: self)
    }
    
    public struct ITLab {
        public let jwt: Application.JWT
        
        public var url: URL? {
            get {
                return self.storage.url
            }
            nonmutating set {
                self.storage.url = newValue
                if let url = newValue {
                self.storage.jwks = .init(uri: URI(string: url.absoluteString))
                }
            }
        }
        
        private final class Storage {
            var jwks: EndpointCache<JWKS> = .init(uri: URI())
            var url: URL?
        }
        
        public var jwks: EndpointCache<JWKS> {
            self.storage.jwks
        }
        
        private struct Key: StorageKey, LockKey {
            typealias Value = Storage
        }
        
        public func signers(on request: Request) -> EventLoopFuture<JWTSigners> {
            self.jwks.get(on: request).flatMapThrowing {
                let signers = JWTSigners()
                try signers.use(jwks: $0)
                return signers
            }
        }
        
        private var storage: Storage {
            if let existing = self.jwt._application.storage[Key.self] {
                return existing
            } else {
                let lock = self.jwt._application.locks.lock(for: Key.self)
                lock.lock()
                defer { lock.unlock() }
                if let existing = self.jwt._application.storage[Key.self] {
                    return existing
                }
                let new = Storage()
                self.jwt._application.storage[Key.self] = new
                return new
            }
        }
    }
}

// swiftlint:enable nesting
