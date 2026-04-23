//
//  MockNetworkClient.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation
import Networking

/// Test double for code that depends on `NetworkClient`.
public final class MockNetworkClient: NetworkClient, @unchecked Sendable {
    public typealias DataHandler = @Sendable (HTTPRequest) async throws -> NetworkResponse<Data>
    public typealias StreamHandler = @Sendable (HTTPRequest) async throws -> NetworkResponse<NetworkByteStream>

    public let recorder: RequestRecorder

    private let coding: JSONCodingConfiguration
    private let dataHandler: DataHandler
    private let streamHandler: StreamHandler?

    public init(
        recorder: RequestRecorder = RequestRecorder(),
        coding: JSONCodingConfiguration = .standard,
        dataHandler: @escaping DataHandler,
        streamHandler: StreamHandler? = nil
    ) {
        self.recorder = recorder
        self.coding = coding
        self.dataHandler = dataHandler
        self.streamHandler = streamHandler
    }

    public convenience init(
        response: NetworkResponse<Data>,
        recorder: RequestRecorder = RequestRecorder(),
        coding: JSONCodingConfiguration = .standard
    ) {
        self.init(recorder: recorder, coding: coding) { _ in response }
    }

    public convenience init(
        error: NetworkError,
        recorder: RequestRecorder = RequestRecorder(),
        coding: JSONCodingConfiguration = .standard
    ) {
        self.init(recorder: recorder, coding: coding) { _ in throw error }
    }

    public func data(for request: HTTPRequest) async throws -> NetworkResponse<Data> {
        await recorder.record(request)
        return try await dataHandler(request)
    }

    public func decoded<Response: Decodable & Sendable>(
        _ responseType: Response.Type,
        for request: HTTPRequest
    ) async throws -> NetworkResponse<Response> {
        let response = try await data(for: request)

        if Response.self == EmptyResponse.self {
            guard response.body.isEmpty || response.body.allSatisfy(\.isASCIIWhitespace) else {
                throw NetworkError.unsupportedResponseShape(
                    "Expected an empty response body but received \(response.body.count) bytes."
                )
            }

            return response.mapBody { _ in EmptyResponse() as! Response }
        }

        do {
            let body = try coding.makeDecoder().decode(Response.self, from: response.body)
            return response.mapBody { _ in body }
        } catch {
            throw NetworkError.decoding(.init(error))
        }
    }

    public func empty(for request: HTTPRequest) async throws -> NetworkResponse<Void> {
        let response = try await data(for: request)
        guard response.body.isEmpty || response.body.allSatisfy(\.isASCIIWhitespace) else {
            throw NetworkError.unsupportedResponseShape(
                "Expected an empty response body but received \(response.body.count) bytes."
            )
        }
        return response.mapBody { _ in () }
    }

    public func stream(for request: HTTPRequest) async throws -> NetworkResponse<NetworkByteStream> {
        await recorder.record(request)

        guard let streamHandler else {
            throw NetworkError.unsupportedResponseShape("No stream handler was configured for MockNetworkClient.")
        }

        return try await streamHandler(request)
    }

    public func execute<EndpointType: Endpoint>(
        _ endpoint: EndpointType
    ) async throws -> NetworkResponse<EndpointType.Response> {
        try await decoded(EndpointType.Response.self, for: endpoint.makeRequest())
    }
}

private extension UInt8 {
    var isASCIIWhitespace: Bool {
        self == 9 || self == 10 || self == 13 || self == 32
    }
}
