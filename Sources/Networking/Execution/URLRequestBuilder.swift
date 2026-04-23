//
//  URLRequestBuilder.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Builds `URLRequest` values from transport-neutral `HTTPRequest` descriptions.
public struct URLRequestBuilder: Sendable {
    public var baseURL: URL?
    public var defaultHeaders: HTTPHeaders
    public var defaultTimeout: TimeInterval?
    public var defaultCachePolicy: URLRequest.CachePolicy

    public init(
        baseURL: URL? = nil,
        defaultHeaders: HTTPHeaders = HTTPHeaders(),
        defaultTimeout: TimeInterval? = nil,
        defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.defaultTimeout = defaultTimeout
        self.defaultCachePolicy = defaultCachePolicy
    }

    public func build(_ request: HTTPRequest) throws -> URLRequest {
        let url = try resolveURL(for: request)
        var urlRequest = URLRequest(
            url: url,
            cachePolicy: request.cachePolicy ?? defaultCachePolicy,
            timeoutInterval: request.timeout ?? defaultTimeout ?? URLRequestBuilderDefaults.timeout
        )

        urlRequest.httpMethod = request.method.name

        for header in defaultHeaders.merging(request.headers) {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
        }

        if let body = request.body {
            urlRequest.httpBody = body.data
            if let contentType = body.contentType, urlRequest.value(forHTTPHeaderField: HTTPHeaderName.contentType) == nil {
                urlRequest.setValue(contentType, forHTTPHeaderField: HTTPHeaderName.contentType)
            }
        }

        return urlRequest
    }

    private func resolveURL(for request: HTTPRequest) throws -> URL {
        let baseURL = request.baseURL ?? baseURL
        let path = request.path

        let url: URL
        if let absoluteURL = URL(string: path), absoluteURL.scheme != nil, absoluteURL.host != nil {
            url = absoluteURL
        } else {
            guard let baseURL else {
                throw NetworkError.invalidRequest(.missingBaseURL(path: path))
            }

            guard let relativeURL = URL(string: normalizedRelativePath(path), relativeTo: normalizedBaseURL(baseURL))?.absoluteURL else {
                throw NetworkError.invalidRequest(.invalidURL(path))
            }
            url = relativeURL
        }

        return try appendQueryItems(request.queryItems, to: url)
    }

    private func appendQueryItems(_ queryItems: [URLQueryItem], to url: URL) throws -> URL {
        guard !queryItems.isEmpty else {
            return url
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidRequest(.invalidURL(url.absoluteString))
        }

        components.queryItems = (components.queryItems ?? []) + queryItems

        guard let resolvedURL = components.url else {
            throw NetworkError.invalidRequest(.invalidURL(url.absoluteString))
        }

        return resolvedURL
    }

    private func normalizedBaseURL(_ url: URL) -> URL {
        guard !url.absoluteString.hasSuffix("/") else {
            return url
        }

        return URL(string: url.absoluteString + "/") ?? url
    }

    private func normalizedRelativePath(_ path: String) -> String {
        path.hasPrefix("/") ? String(path.dropFirst()) : path
    }
}

private enum URLRequestBuilderDefaults {
    static let timeout: TimeInterval = 60
}
