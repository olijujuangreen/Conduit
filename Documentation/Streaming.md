# Streaming

`Networking` supports streaming through `NetworkByteStream`. This is useful for
run logs, agent events, progress updates, and other feeds where the server sends
incremental data.

## Raw Bytes

```swift
let response = try await client.stream(
    for: HTTPRequest(
        method: .get,
        path: "v1/runs/123/bytes"
    )
)

for try await byte in response.body.bytes {
    print(byte)
}
```

## Lines

```swift
let stream = try await client.stream(
    for: HTTPRequest(
        method: .get,
        path: "v1/runs/123/logs"
    )
).body

for try await line in stream.lines() {
    print(line)
}
```

## Newline-Delimited JSON

```swift
struct RunEvent: Decodable, Sendable {
    let id: UUID
    let message: String
}

let stream = try await client.stream(
    for: HTTPRequest(
        method: .get,
        path: "v1/runs/123/events",
        headers: [.accept(HTTPMediaType.ndjson)]
    )
).body

for try await event in stream.newlineDelimitedJSON(RunEvent.self) {
    print(event.message)
}
```

## Server-Sent Events

```swift
let stream = try await client.stream(
    for: HTTPRequest(
        method: .get,
        path: "v1/runs/123/events",
        headers: [.accept(HTTPMediaType.eventStream)]
    )
).body

for try await event in stream.serverSentEvents() {
    print(event.event ?? "message", event.data)
}
```

## Cancellation

Streaming iteration participates in Swift task cancellation. Cancelling the
consumer task terminates the underlying stream wrapper.
