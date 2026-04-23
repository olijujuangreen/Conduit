//
//  NetworkResponse.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Response body plus stable HTTP metadata.
public struct NetworkResponse<Body: Sendable>: Sendable {
    public var body: Body
    public var statusCode: Int
    public var headers: HTTPHeaders
    public var url: URL?

    public init(body: Body, statusCode: Int, headers: HTTPHeaders = HTTPHeaders(), url: URL? = nil) {
        self.body = body
        self.statusCode = statusCode
        self.headers = headers
        self.url = url
    }

    init(body: Body, metadata: NetworkResponseMetadata) {
        self.init(
            body: body,
            statusCode: metadata.statusCode,
            headers: metadata.headers,
            url: metadata.url
        )
    }

    public func mapBody<NewBody: Sendable>(
        _ transform: (Body) throws -> NewBody
    ) rethrows -> NetworkResponse<NewBody> {
        NetworkResponse<NewBody>(
            body: try transform(body),
            statusCode: statusCode,
            headers: headers,
            url: url
        )
    }
}

struct NetworkResponseMetadata: Sendable {
    var statusCode: Int
    var headers: HTTPHeaders
    var url: URL?

    init(response: URLResponse, acceptedStatusCodes: HTTPStatusCodes, body: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse("Expected HTTPURLResponse but received \(type(of: response)).")
        }

        let headers = HTTPHeaders(httpResponse.allHeaderFields.map { key, value in
            HTTPHeader(name: String(describing: key), value: String(describing: value))
        })

        guard acceptedStatusCodes.contains(httpResponse.statusCode) else {
            throw NetworkError.httpStatus(statusCode: httpResponse.statusCode, body: body, headers: headers)
        }

        self.statusCode = httpResponse.statusCode
        self.headers = headers
        self.url = httpResponse.url
    }
}
