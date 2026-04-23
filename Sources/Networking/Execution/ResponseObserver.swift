//
//  ResponseObserver.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Observes completed transport calls without changing their result.
///
/// This is suitable for logging, metrics, and tracing. Observers deliberately do
/// not receive product-specific state from the networking layer.
public protocol ResponseObserver: Sendable {
    func observe(_ result: Result<NetworkResponse<Data>, NetworkError>, for request: URLRequest) async
}
