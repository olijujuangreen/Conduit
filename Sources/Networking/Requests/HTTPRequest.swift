//
//  HTTPRequest.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Transport-neutral HTTP request description.
public struct HTTPRequest: Equatable, Sendable {
    public var method: HTTPMethod
    public var path: String
    public var baseURL: URL?
    public var queryItems: [URLQueryItem]
    public var headers: HTTPHeaders
    public var body: HTTPBody?
    public var timeout: TimeInterval?
    public var cachePolicy: URLRequest.CachePolicy?
    public var acceptedStatusCodes: HTTPStatusCodes

    public init(
        method: HTTPMethod = .get,
        path: String,
        baseURL: URL? = nil,
        queryItems: [URLQueryItem] = [],
        headers: HTTPHeaders = HTTPHeaders(),
        body: HTTPBody? = nil,
        timeout: TimeInterval? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        acceptedStatusCodes: HTTPStatusCodes = .success
    ) {
        self.method = method
        self.path = path
        self.baseURL = baseURL
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.timeout = timeout
        self.cachePolicy = cachePolicy
        self.acceptedStatusCodes = acceptedStatusCodes
    }
}
