//
//  URLSessionNetworkClient.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// `NetworkClient` implementation backed by an injected `URLSession`.
public final class URLSessionNetworkClient: NetworkClient, @unchecked Sendable {
    private let session: URLSession
    private let builder: URLRequestBuilder
    private let coding: JSONCodingConfiguration
    private let requestAdapters: [any RequestAdapter]
    private let responseObservers: [any ResponseObserver]

    public init(
        baseURL: URL? = nil,
        session: URLSession,
        coding: JSONCodingConfiguration = .standard,
        defaultHeaders: HTTPHeaders = HTTPHeaders(),
        defaultTimeout: TimeInterval? = nil,
        defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        requestAdapters: [any RequestAdapter] = [],
        responseObservers: [any ResponseObserver] = []
    ) {
        self.session = session
        self.builder = URLRequestBuilder(
            baseURL: baseURL,
            defaultHeaders: defaultHeaders,
            defaultTimeout: defaultTimeout,
            defaultCachePolicy: defaultCachePolicy
        )
        self.coding = coding
        self.requestAdapters = requestAdapters
        self.responseObservers = responseObservers
    }

    public convenience init(
        baseURL: URL? = nil,
        configuration: URLSessionConfiguration = .ephemeral,
        coding: JSONCodingConfiguration = .standard,
        defaultHeaders: HTTPHeaders = HTTPHeaders(),
        defaultTimeout: TimeInterval? = nil,
        defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        requestAdapters: [any RequestAdapter] = [],
        responseObservers: [any ResponseObserver] = []
    ) {
        self.init(
            baseURL: baseURL,
            session: URLSession(configuration: configuration),
            coding: coding,
            defaultHeaders: defaultHeaders,
            defaultTimeout: defaultTimeout,
            defaultCachePolicy: defaultCachePolicy,
            requestAdapters: requestAdapters,
            responseObservers: responseObservers
        )
    }

    public func data(for request: HTTPRequest) async throws -> NetworkResponse<Data> {
        let urlRequest = try await prepareURLRequest(from: request)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            let networkResponse = try makeDataResponse(
                data: data,
                response: response,
                acceptedStatusCodes: request.acceptedStatusCodes
            )
            await notifyObservers(.success(networkResponse), request: urlRequest)
            return networkResponse
        } catch {
            let networkError = NetworkError.map(error)
            await notifyObservers(.failure(networkError), request: urlRequest)
            throw networkError
        }
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
            let decodedBody = try coding.makeDecoder().decode(Response.self, from: response.body)
            return response.mapBody { _ in decodedBody }
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
        let urlRequest = try await prepareURLRequest(from: request)

        do {
            let (bytes, response) = try await session.bytes(for: urlRequest)
            let metadata = try NetworkResponseMetadata(
                response: response,
                acceptedStatusCodes: request.acceptedStatusCodes,
                body: Data()
            )
            let stream = NetworkByteStream(bytes: bytes) { NetworkError.map($0) }
            let networkResponse = NetworkResponse(body: stream, metadata: metadata)
            await notifyObservers(.success(NetworkResponse(body: Data(), metadata: metadata)), request: urlRequest)
            return networkResponse
        } catch {
            let networkError = NetworkError.map(error)
            await notifyObservers(.failure(networkError), request: urlRequest)
            throw networkError
        }
    }

    public func execute<EndpointType: Endpoint>(
        _ endpoint: EndpointType
    ) async throws -> NetworkResponse<EndpointType.Response> {
        try await decoded(EndpointType.Response.self, for: endpoint.makeRequest())
    }

    private func prepareURLRequest(from request: HTTPRequest) async throws -> URLRequest {
        do {
            var urlRequest = try builder.build(request)
            for adapter in requestAdapters {
                urlRequest = try await adapter.adapt(urlRequest)
            }
            return urlRequest
        } catch {
            throw NetworkError.map(error)
        }
    }

    private func makeDataResponse(
        data: Data,
        response: URLResponse,
        acceptedStatusCodes: HTTPStatusCodes
    ) throws -> NetworkResponse<Data> {
        let metadata = try NetworkResponseMetadata(
            response: response,
            acceptedStatusCodes: acceptedStatusCodes,
            body: data
        )
        return NetworkResponse(body: data, metadata: metadata)
    }

    private func notifyObservers(
        _ result: Result<NetworkResponse<Data>, NetworkError>,
        request: URLRequest
    ) async {
        guard !responseObservers.isEmpty else {
            return
        }

        for observer in responseObservers {
            await observer.observe(result, for: request)
        }
    }
}

private extension UInt8 {
    var isASCIIWhitespace: Bool {
        self == 9 || self == 10 || self == 13 || self == 32
    }
}
