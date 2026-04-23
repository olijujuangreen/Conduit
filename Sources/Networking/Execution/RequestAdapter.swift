//
//  RequestAdapter.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Modifies a `URLRequest` immediately before execution.
///
/// Use adapters for generic cross-cutting transport behavior such as header
/// injection, tracing identifiers, or request signing. Adapters should not own
/// app-specific token storage or UI behavior.
public protocol RequestAdapter: Sendable {
    func adapt(_ request: URLRequest) async throws -> URLRequest
}

/// Supplies headers for a request without dictating where those values come from.
public protocol HTTPHeaderProvider: Sendable {
    func headers(for request: URLRequest) async throws -> HTTPHeaders
}

/// Adds headers returned by a provider, replacing existing values with the same name.
public struct HeaderInjectionAdapter<Provider: HTTPHeaderProvider>: RequestAdapter {
    private let provider: Provider

    public init(provider: Provider) {
        self.provider = provider
    }

    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        for header in try await provider.headers(for: request) {
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        return request
    }
}

/// Static header provider useful for tests and simple integrations.
public struct StaticHeaderProvider: HTTPHeaderProvider {
    private let headers: HTTPHeaders

    public init(_ headers: HTTPHeaders) {
        self.headers = headers
    }

    public func headers(for request: URLRequest) async throws -> HTTPHeaders {
        headers
    }
}
