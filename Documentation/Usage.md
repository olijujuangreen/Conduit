# Usage

This page shows the main integration patterns.

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

## Auth Header Injection

Auth belongs in the app or API layer. The networking package provides the hook.

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

## Custom JSON Coders

```swift
let coding = JSONCodingConfiguration(
    makeEncoder: {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    },
    makeDecoder: {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
)

let client = URLSessionNetworkClient(
    baseURL: URL(string: "https://api.example.com")!,
    configuration: .ephemeral,
    coding: coding
)
```

## App Service Composition

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
