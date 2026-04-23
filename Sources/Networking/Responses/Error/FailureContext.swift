//
//  FailureContext.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Sendable summary of an underlying error.
public struct FailureContext: Equatable, Sendable {
    public var message: String
    public var typeName: String

    public init(message: String, typeName: String) {
        self.message = message
        self.typeName = typeName
    }

    public init(_ error: any Error) {
        self.message = String(describing: error)
        self.typeName = String(reflecting: Swift.type(of: error))
    }
}
