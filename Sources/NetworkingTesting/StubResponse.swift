//
//  StubResponse.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation
import Networking

/// Fixture-friendly response helpers for tests.
public enum StubResponse {
    public static func data(
        _ data: Data,
        statusCode: Int = 200,
        headers: HTTPHeaders = HTTPHeaders(),
        url: URL? = nil
    ) -> NetworkResponse<Data> {
        NetworkResponse(body: data, statusCode: statusCode, headers: headers, url: url)
    }

    public static func json<Value: Encodable & Sendable>(
        _ value: Value,
        statusCode: Int = 200,
        headers: HTTPHeaders = [.contentType(HTTPMediaType.json)],
        url: URL? = nil,
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> NetworkResponse<Data> {
        NetworkResponse(
            body: try encoder.encode(value),
            statusCode: statusCode,
            headers: headers,
            url: url
        )
    }

    public static func empty(
        statusCode: Int = 204,
        headers: HTTPHeaders = HTTPHeaders(),
        url: URL? = nil
    ) -> NetworkResponse<Data> {
        NetworkResponse(body: Data(), statusCode: statusCode, headers: headers, url: url)
    }

    public static func stream(
        _ text: String,
        statusCode: Int = 200,
        headers: HTTPHeaders = HTTPHeaders(),
        url: URL? = nil
    ) -> NetworkResponse<NetworkByteStream> {
        let stream = NetworkByteStream(bytes: AsyncThrowingStream { continuation in
            for byte in text.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        })
        return NetworkResponse(body: stream, statusCode: statusCode, headers: headers, url: url)
    }
}
