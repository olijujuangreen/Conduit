//
//  NetworkByteStream.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation

/// Async byte stream returned by streaming requests.
public struct NetworkByteStream: @unchecked Sendable {
    public let bytes: AsyncThrowingStream<UInt8, any Error>

    public init(bytes: AsyncThrowingStream<UInt8, any Error>) {
        self.bytes = bytes
    }

    init(bytes: URLSession.AsyncBytes, errorMapper: @escaping @Sendable (any Error) -> any Error) {
        self.bytes = AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await byte in bytes {
                        continuation.yield(byte)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: errorMapper(error))
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    public func lines() -> AsyncThrowingStream<String, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                var buffer = Data()

                do {
                    for try await byte in bytes {
                        if byte == UInt8(ascii: "\n") {
                            continuation.yield(Self.decodeLine(buffer))
                            buffer.removeAll(keepingCapacity: true)
                        } else {
                            buffer.append(byte)
                        }
                    }

                    if !buffer.isEmpty {
                        continuation.yield(Self.decodeLine(buffer))
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    public func newlineDelimitedJSON<Value: Decodable & Sendable>(
        _ valueType: Value.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AsyncThrowingStream<Value, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await line in lines() {
                        guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            continue
                        }
                        let value = try decoder.decode(Value.self, from: Data(line.utf8))
                        continuation.yield(value)
                    }
                    continuation.finish()
                } catch {
                    if let networkError = error as? NetworkError {
                        continuation.finish(throwing: networkError)
                    } else {
                        continuation.finish(throwing: NetworkError.decoding(.init(error)))
                    }
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    public func serverSentEvents() -> AsyncThrowingStream<ServerSentEvent, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                var parser = ServerSentEventParser()

                do {
                    for try await line in lines() {
                        if let event = parser.consume(line) {
                            continuation.yield(event)
                        }
                    }

                    if let event = parser.finish() {
                        continuation.yield(event)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    private static func decodeLine(_ data: Data) -> String {
        var lineData = data
        if lineData.last == UInt8(ascii: "\r") { lineData.removeLast() }
        return String(decoding: lineData, as: UTF8.self)
    }
}
