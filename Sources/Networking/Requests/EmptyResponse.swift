//
//  EmptyResponse.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Decodable marker for endpoints that deliberately return no response body.
public struct EmptyResponse: Decodable, Equatable, Sendable {
    public init() {}

    public init(from decoder: Decoder) throws {
        self.init()
    }
}
