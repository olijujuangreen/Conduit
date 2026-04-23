//
//  ServerSentEvent.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Parsed Server-Sent Events message.
public struct ServerSentEvent: Equatable, Sendable {
    public var id: String?
    public var event: String?
    public var data: String
    public var retryMilliseconds: Int?

    public init(
        id: String? = nil,
        event: String? = nil,
        data: String,
        retryMilliseconds: Int? = nil
    ) {
        self.id = id
        self.event = event
        self.data = data
        self.retryMilliseconds = retryMilliseconds
    }
}

struct ServerSentEventParser: Sendable {
    private var id: String?
    private var event: String?
    private var dataLines: [String] = []
    private var retryMilliseconds: Int?

    mutating func consume(_ line: String) -> ServerSentEvent? {
        guard !line.isEmpty else { return flush() }
        guard !line.hasPrefix(":") else { return nil }

        let (field, value) = parseField(line)

        switch field {
        case "id": id = value
        case "event": event = value
        case "data": dataLines.append(value)
        case "retry": retryMilliseconds = Int(value)
        default: break
        }

        return nil
    }

    mutating func finish() -> ServerSentEvent? {
        flush()
    }

    private mutating func flush() -> ServerSentEvent? {
        guard !dataLines.isEmpty || id != nil || event != nil || retryMilliseconds != nil else {
            reset()
            return nil
        }

        let event = ServerSentEvent(
            id: id,
            event: event,
            data: dataLines.joined(separator: "\n"),
            retryMilliseconds: retryMilliseconds
        )
        reset()
        return event
    }

    private mutating func reset() {
        id = nil
        event = nil
        dataLines.removeAll(keepingCapacity: true)
        retryMilliseconds = nil
    }

    private func parseField(_ line: String) -> (String, String) {
        guard let separator = line.firstIndex(of: ":") else {
            return (line, "")
        }

        let field = String(line[..<separator])
        var value = String(line[line.index(after: separator)...])
        if value.first == " " {
            value.removeFirst()
        }
        return (field, value)
    }
}
