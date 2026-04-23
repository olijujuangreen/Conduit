# Errors

`NetworkError` is the package's typed error surface. It separates construction,
transport, HTTP, encoding, decoding, cancellation, and response-shape failures.

## Error Cases

```swift
public enum NetworkError: Error, Equatable, Sendable {
    case invalidRequest(InvalidRequestReason)
    case transport(FailureContext)
    case invalidResponse(String)
    case httpStatus(statusCode: Int, body: Data, headers: HTTPHeaders)
    case decoding(FailureContext)
    case encoding(FailureContext)
    case cancelled
    case unsupportedResponseShape(String)
}
```

## HTTP Status Failures

HTTP failures preserve status code, response body, and headers.

```swift
do {
    _ = try await client.data(for: HTTPRequest(path: "v1/users/me"))
} catch let error as NetworkError {
    switch error {
    case .httpStatus(let statusCode, let body, let headers):
        print(statusCode)
        print(headers["Content-Type"] ?? "")
        print(String(decoding: body, as: UTF8.self))
    default:
        throw error
    }
}
```

## Cancellation

`CancellationError` and cancelled `URLError` values are normalized to
`NetworkError.cancelled`.

```swift
do {
    _ = try await client.data(for: HTTPRequest(path: "v1/slow"))
} catch NetworkError.cancelled {
    // Treat as user or task cancellation.
}
```

## App-Specific Error Mapping

Backend-specific error parsing belongs above the networking package.

```swift
struct APIErrorMapper {
    func map(_ error: NetworkError) -> Error {
        switch error {
        case .httpStatus(let statusCode, let body, _):
            return decodeAPIError(statusCode: statusCode, body: body)
        default:
            return error
        }
    }
}
```

This keeps the transport layer reusable and prevents product-specific auth or
logout behavior from being baked into generic networking code.
