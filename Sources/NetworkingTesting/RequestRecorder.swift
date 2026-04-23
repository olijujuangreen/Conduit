//
//  RequestRecorder.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation
import Networking

/// Actor-backed request spy for deterministic async tests.
public actor RequestRecorder {
    private var requests: [HTTPRequest] = []

    public init() {}

    public func record(_ request: HTTPRequest) {
        requests.append(request)
    }

    public func all() -> [HTTPRequest] {
        requests
    }

    public func last() -> HTTPRequest? {
        requests.last
    }

    public func count() -> Int {
        requests.count
    }

    public func reset() {
        requests.removeAll()
    }
}
