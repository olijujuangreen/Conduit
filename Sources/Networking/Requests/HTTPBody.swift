//
//  HTTPBody.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Raw request body plus optional content type metadata.
public struct HTTPBody: Equatable, Sendable {
    public var data: Data
    public var contentType: String?

    public init(data: Data, contentType: String? = nil) {
        self.data = data
        self.contentType = contentType
    }

    public static func data(_ data: Data, contentType: String? = nil) -> HTTPBody {
        HTTPBody(data: data, contentType: contentType)
    }

    public static func string(_ value: String, contentType: String = HTTPMediaType.plainText) -> HTTPBody {
        HTTPBody(data: Data(value.utf8), contentType: contentType)
    }

    public static func json<Payload: Encodable & Sendable>(
        _ payload: Payload,
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> HTTPBody {
        do {
            return HTTPBody(data: try encoder.encode(payload), contentType: HTTPMediaType.json)
        } catch {
            throw NetworkError.encoding(.init(error))
        }
    }
}
