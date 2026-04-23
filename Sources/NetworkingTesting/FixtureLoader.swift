//
//  FixtureLoader.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Small utility for loading test fixtures from a caller-provided bundle.
public enum FixtureLoader {
    public static func data(
        named name: String,
        extension fileExtension: String? = nil,
        bundle: Bundle
    ) throws -> Data {
        guard let url = bundle.url(forResource: name, withExtension: fileExtension) else {
            throw FixtureLoaderError.missingFixture(name: name, fileExtension: fileExtension)
        }

        return try Data(contentsOf: url)
    }

    public static func decoded<Value: Decodable>(
        _ valueType: Value.Type,
        named name: String,
        extension fileExtension: String? = "json",
        bundle: Bundle,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> Value {
        try decoder.decode(
            Value.self,
            from: data(named: name, extension: fileExtension, bundle: bundle)
        )
    }
}

public enum FixtureLoaderError: Error, Equatable, Sendable {
    case missingFixture(name: String, fileExtension: String?)
}
