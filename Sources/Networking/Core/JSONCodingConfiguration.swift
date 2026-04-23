//
//  JSONCodingConfiguration.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Provides fresh JSON coders for each operation.
///
/// `JSONEncoder` and `JSONDecoder` are mutable reference types. Factories keep
/// client configuration explicit while avoiding shared mutable global instances.
public struct JSONCodingConfiguration: Sendable {
    public var makeEncoder: @Sendable () -> JSONEncoder
    public var makeDecoder: @Sendable () -> JSONDecoder

    public init(
        makeEncoder: @escaping @Sendable () -> JSONEncoder = { JSONEncoder() },
        makeDecoder: @escaping @Sendable () -> JSONDecoder = { JSONDecoder() }
    ) {
        self.makeEncoder = makeEncoder
        self.makeDecoder = makeDecoder
    }

    public static let standard = JSONCodingConfiguration()
}
