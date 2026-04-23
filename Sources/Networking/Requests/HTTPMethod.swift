//
//  HTTPMethod.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// HTTP methods used by transport-neutral requests.
public enum HTTPMethod: Hashable, Sendable {
    case get
    case post
    case put
    case patch
    case delete
    case head
    case options
    case trace
    case custom(String)

    public var name: String {
        switch self {
        case .get: "GET"
        case .post: "POST"
        case .put: "PUT"
        case .patch: "PATCH"
        case .delete: "DELETE"
        case .head: "HEAD"
        case .options: "OPTIONS"
        case .trace: "TRACE"
        case .custom(let value): value.uppercased()
        }
    }
}
