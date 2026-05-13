//
//  HTTPHeaders.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Ordered, case-insensitive collection of HTTP headers.
public struct HTTPHeaders: ExpressibleByArrayLiteral, Sequence, Hashable, Sendable {
    public var isEmpty: Bool { storage.isEmpty }
    public var count: Int { storage.count }

    private var storage: [HTTPHeader]

    public init(_ headers: [HTTPHeader] = []) {
        self.storage = []
        for header in headers {
            set(header)
        }
    }

    public init(arrayLiteral elements: HTTPHeader...) {
        self.init(elements)
    }

    public subscript(_ name: String) -> String? {
        value(for: name)
    }

    public func value(for name: String) -> String? {
        storage.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    public mutating func set(_ header: HTTPHeader) {
        if let index = storage.firstIndex(where: { $0.name.caseInsensitiveCompare(header.name) == .orderedSame }) {
            storage[index] = header
        } else {
            storage.append(header)
        }
    }

    public func setting(_ header: HTTPHeader) -> HTTPHeaders {
        var headers = self
        headers.set(header)
        return headers
    }

    public func merging(_ other: HTTPHeaders) -> HTTPHeaders {
        var headers = self
        for header in other {
            headers.set(header)
        }
        return headers
    }

    public func dictionary() -> [String: String] {
        Dictionary(uniqueKeysWithValues: storage.map { ($0.name, $0.value) })
    }

    public func makeIterator() -> Array<HTTPHeader>.Iterator {
        storage.makeIterator()
    }
}
