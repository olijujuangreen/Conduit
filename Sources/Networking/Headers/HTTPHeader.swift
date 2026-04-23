//
//  HTTPHeader.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// A single HTTP header field.
public struct HTTPHeader: Hashable, Sendable {
    public var name: String
    public var value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    public static func accept(_ value: String) -> HTTPHeader {
        HTTPHeader(name: HTTPHeaderName.accept, value: value)
    }

    public static func authorization(_ value: String) -> HTTPHeader {
        HTTPHeader(name: HTTPHeaderName.authorization, value: value)
    }

    public static func contentType(_ value: String) -> HTTPHeader {
        HTTPHeader(name: HTTPHeaderName.contentType, value: value)
    }

    public static func userAgent(_ value: String) -> HTTPHeader {
        HTTPHeader(name: HTTPHeaderName.userAgent, value: value)
    }
}

public enum HTTPHeaderName {
    public static let accept = "Accept"
    public static let authorization = "Authorization"
    public static let contentType = "Content-Type"
    public static let userAgent = "User-Agent"
}

public enum HTTPMediaType {
    public static let json = "application/json"
    public static let ndjson = "application/x-ndjson"
    public static let eventStream = "text/event-stream"
    public static let octetStream = "application/octet-stream"
    public static let plainText = "text/plain"
}
