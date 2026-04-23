//
//  HTTPStatusCodes.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Status-code policy used to validate HTTP responses.
public struct HTTPStatusCodes: Equatable, Sendable {
    private let ranges: [ClosedRange<Int>]

    public init(_ ranges: [ClosedRange<Int>]) {
        self.ranges = ranges
    }

    public init(_ range: ClosedRange<Int>) {
        self.init([range])
    }

    public static let success = HTTPStatusCodes(200...299)

    public func contains(_ statusCode: Int) -> Bool {
        ranges.contains { $0.contains(statusCode) }
    }
}
