//
//  Endpoint.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Typed abstraction over an HTTP request and its decoded response body.
public protocol Endpoint: Sendable {
    associatedtype Response: Decodable & Sendable
    
    func makeRequest() throws -> HTTPRequest
}
