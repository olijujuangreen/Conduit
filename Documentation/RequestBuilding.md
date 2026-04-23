# Request Building

Request construction is intentionally separate from execution. This keeps
request behavior easy to test and prevents `URLSession` concerns from leaking
into endpoint definitions.

## HTTPRequest

`HTTPRequest` describes a request in transport-neutral terms.

```swift
let request = HTTPRequest(
    method: .post,
    path: "v1/messages",
    queryItems: [
        URLQueryItem(name: "stream", value: "true")
    ],
    headers: [
        .accept(HTTPMediaType.json)
    ],
    body: try .json(CreateMessageBody(text: "Hello")),
    timeout: 20,
    cachePolicy: .reloadIgnoringLocalCacheData
)
```

## Base URL Resolution

Relative paths are resolved against the client's `baseURL`.

```swift
let builder = URLRequestBuilder(
    baseURL: URL(string: "https://api.example.com")!
)

let urlRequest = try builder.build(
    HTTPRequest(path: "v1/users/me")
)
```

Absolute request paths are also supported.

```swift
let request = HTTPRequest(
    method: .get,
    path: "https://cdn.example.com/avatar.png"
)
```

## Default Headers

Default headers are applied first. Request-specific headers with the same name
replace defaults.

```swift
let builder = URLRequestBuilder(
    baseURL: URL(string: "https://api.example.com")!,
    defaultHeaders: [
        .accept(HTTPMediaType.json)
    ]
)

let request = HTTPRequest(
    path: "v1/events",
    headers: [
        .accept(HTTPMediaType.eventStream)
    ]
)
```

The built `URLRequest` will use `Accept: text/event-stream`.

## Body Content Type

`HTTPBody.json` sets `Content-Type: application/json` unless the request already
has a `Content-Type` header.

```swift
let request = try HTTPRequest(
    method: .post,
    path: "v1/users",
    body: .json(CreateUserRequest(name: "Ada"))
)
```

## Accepted Status Codes

By default, responses in `200...299` are accepted. You can override that per
request.

```swift
let request = HTTPRequest(
    method: .post,
    path: "v1/jobs",
    acceptedStatusCodes: HTTPStatusCodes([200...202])
)
```
