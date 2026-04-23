//
//  NetworkClient.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// A transport abstraction used by application-specific API layers.
///
/// The protocol intentionally works with generic request and response primitives
/// only. Product APIs should be layered above this module.
public protocol NetworkClient: Sendable {
    func data(for request: HTTPRequest) async throws -> NetworkResponse<Data>
    func empty(for request: HTTPRequest) async throws -> NetworkResponse<Void>
    func stream(for request: HTTPRequest) async throws -> NetworkResponse<NetworkByteStream>
    func execute<EndpointType: Endpoint>(_ endpoint: EndpointType) async throws -> NetworkResponse<EndpointType.Response>
    func decoded<Response: Decodable & Sendable>(
        _ responseType: Response.Type,
        for request: HTTPRequest
    ) async throws -> NetworkResponse<Response>
}
