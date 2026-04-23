# Conduit Networking

`Networking` is a reusable Swift transport package for Apple-platform apps. It
keeps HTTP request construction, execution, decoding, streaming, and test
doubles separate from app-specific API logic.

The package is intended to be composed into app services:

```swift
struct UserService {
    private let client: any NetworkClient

    init(client: any NetworkClient) {
        self.client = client
    }

    func currentUser() async throws -> User {
        try await client.execute(GetCurrentUserEndpoint()).body
    }
}
```

Application-specific services define endpoints and depend on `NetworkClient`.
The transport package does not know about token storage, notification names,
environments, product headers, or app UI.

## Create A Client

```swift
import Foundation
import Networking

let client = URLSessionNetworkClient(
    baseURL: URL(string: "https://api.example.com")!,
    configuration: .ephemeral,
    defaultHeaders: [
        .accept(HTTPMediaType.json)
    ],
    defaultTimeout: 30
)
```

## Decode JSON

```swift
struct User: Codable, Sendable {
    let id: UUID
    let name: String
}

struct GetCurrentUserEndpoint: Endpoint {
    typealias Response = User

    func makeRequest() throws -> HTTPRequest {
        HTTPRequest(
            method: .get,
            path: "v1/users/me"
        )
    }
}

let user = try await client.execute(GetCurrentUserEndpoint()).body
```

## POST JSON

```swift
struct CreateUserRequest: Codable, Sendable {
    let name: String
}

struct CreateUserEndpoint: Endpoint {
    typealias Response = User

    let payload: CreateUserRequest

    func makeRequest() throws -> HTTPRequest {
        HTTPRequest(
            method: .post,
            path: "v1/users",
            body: try .json(payload)
        )
    }
}

let createdUser = try await client.execute(
    CreateUserEndpoint(payload: CreateUserRequest(name: "Ada"))
).body
```

## Inject Auth Headers

Auth belongs in the app or API layer. The networking package only provides the
hook for injecting headers.

```swift
struct BearerTokenProvider: HTTPHeaderProvider {
    let loadToken: @Sendable () async throws -> String?

    func headers(for request: URLRequest) async throws -> HTTPHeaders {
        guard let token = try await loadToken(), !token.isEmpty else {
            return []
        }

        return [.authorization("Bearer \(token)")]
    }
}

let authenticatedClient = URLSessionNetworkClient(
    baseURL: URL(string: "https://api.example.com")!,
    configuration: .ephemeral,
    requestAdapters: [
        HeaderInjectionAdapter(
            provider: BearerTokenProvider {
                "runtime-token-from-the-app-layer"
            }
        )
    ]
)
```

## Raw Data

```swift
let response = try await client.data(
    for: HTTPRequest(method: .get, path: "v1/files/avatar")
)

let bytes = response.body
let statusCode = response.statusCode
let contentType = response.headers["Content-Type"]
```

## Empty Responses

```swift
struct DeleteUserEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let id: UUID

    func makeRequest() throws -> HTTPRequest {
        HTTPRequest(
            method: .delete,
            path: "v1/users/\(id)"
        )
    }
}

try await client.execute(DeleteUserEndpoint(id: user.id))
```

## Streaming Events

```swift
let streamResponse = try await client.stream(
    for: HTTPRequest(
        method: .get,
        path: "v1/runs/123/events",
        headers: [.accept(HTTPMediaType.eventStream)]
    )
)

for try await event in streamResponse.body.serverSentEvents() {
    print(event.event ?? "message", event.data)
}
```

## Mock-Based Tests

```swift
import Networking
import NetworkingTesting
import Testing

@Test func loadsCurrentUser() async throws {
    let mock = try MockNetworkClient(
        response: StubResponse.json(
            User(id: UUID(), name: "Ada")
        )
    )

    let user = try await mock.execute(GetCurrentUserEndpoint()).body

    #expect(user.name == "Ada")
    #expect(await mock.recorder.count() == 1)
    #expect(await mock.recorder.last()?.path == "v1/users/me")
}
```
