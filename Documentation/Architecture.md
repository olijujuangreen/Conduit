# Architecture

The package is built around a small set of transport primitives. Each layer has
one job.

```text
App/API Service
    depends on
Endpoint / HTTPRequest
    built by
URLRequestBuilder
    executed by
NetworkClient
    backed by
URLSessionNetworkClient or MockNetworkClient
```

## App Services

App services define product behavior. They own names like `UserService`,
`RunService`, or `ProjectService`. They should depend on `any NetworkClient`.

```swift
struct RunService {
    private let client: any NetworkClient

    init(client: any NetworkClient) {
        self.client = client
    }

    func run(id: UUID) async throws -> Run {
        try await client.execute(GetRunEndpoint(id: id)).body
    }
}
```

## Endpoints

`Endpoint` is the typed bridge between app API semantics and the generic
transport layer.

```swift
struct GetRunEndpoint: Endpoint {
    typealias Response = Run

    let id: UUID

    func makeRequest() throws -> HTTPRequest {
        HTTPRequest(
            method: .get,
            path: "v1/runs/\(id)"
        )
    }
}
```

Endpoints stay ergonomic but explicit. They describe method, path, query,
headers, body, timeout, cache policy, and accepted status codes.

## HTTPRequest

`HTTPRequest` is transport-neutral. It does not execute anything and does not
require `URLSession`.

```swift
let request = HTTPRequest(
    method: .get,
    path: "v1/runs",
    queryItems: [
        URLQueryItem(name: "limit", value: "20")
    ]
)
```

## URLRequestBuilder

`URLRequestBuilder` converts `HTTPRequest` into `URLRequest`. Keeping this
separate makes request construction testable without making real network calls.

```swift
let builder = URLRequestBuilder(
    baseURL: URL(string: "https://api.example.com")!,
    defaultHeaders: [.accept(HTTPMediaType.json)],
    defaultTimeout: 30
)

let urlRequest = try builder.build(request)
```

## NetworkClient

`NetworkClient` is the main abstraction app code depends on. It supports decoded
JSON, raw data, empty responses, streaming, and typed endpoints.

```swift
public protocol NetworkClient: Sendable {
    func data(for request: HTTPRequest) async throws -> NetworkResponse<Data>
    func decoded<Response: Decodable & Sendable>(
        _ responseType: Response.Type,
        for request: HTTPRequest
    ) async throws -> NetworkResponse<Response>
    func empty(for request: HTTPRequest) async throws -> NetworkResponse<Void>
    func stream(for request: HTTPRequest) async throws -> NetworkResponse<NetworkByteStream>
    func execute<EndpointType: Endpoint>(
        _ endpoint: EndpointType
    ) async throws -> NetworkResponse<EndpointType.Response>
}
```

## URLSessionNetworkClient

`URLSessionNetworkClient` is the production implementation. It receives its
`URLSession`, JSON coders, defaults, adapters, and observers through
initialization.

```swift
let client = URLSessionNetworkClient(
    baseURL: URL(string: "https://api.example.com")!,
    configuration: .ephemeral,
    defaultHeaders: [.accept(HTTPMediaType.json)],
    defaultTimeout: 30
)
```

## Adapters And Observers

Adapters mutate outgoing `URLRequest` values before execution. Use them for
generic cross-cutting concerns like auth header injection or trace IDs.

Observers receive completed results. Use them for logging, metrics, and debug
tracing.

Neither adapters nor observers should own product UI behavior.
