//
//  InvalidRequestReason.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

public enum InvalidRequestReason: Equatable, Sendable {
    case missingBaseURL(path: String)
    case invalidURL(String)
}
