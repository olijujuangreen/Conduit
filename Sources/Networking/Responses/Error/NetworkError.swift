//
//  NetworkError.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Strongly typed transport error surface.
public enum NetworkError: Error, Equatable, Sendable {
    case invalidRequest(InvalidRequestReason)
    case transport(FailureContext)
    case invalidResponse(String)
    case httpStatus(statusCode: Int, body: Data, headers: HTTPHeaders)
    case decoding(FailureContext)
    case encoding(FailureContext)
    case cancelled
    case unsupportedResponseShape(String)

    public static func map(_ error: any Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }

        if error is CancellationError {
            return .cancelled
        }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            return .cancelled
        }

        return .transport(.init(error))
    }
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidRequest(let reason): "Invalid request: \(reason)"
        case .transport(let context): "Transport failure: \(context.message)"
        case .invalidResponse(let message): "Invalid response: \(message)"
        case .httpStatus(let statusCode, _, _): "HTTP request failed with status code \(statusCode)."
        case .decoding(let context): "Decoding failure: \(context.message)"
        case .encoding(let context): "Encoding failure: \(context.message)"
        case .cancelled: "The request was cancelled."
        case .unsupportedResponseShape(let message): "Unsupported response shape: \(message)"
        }
    }
}
