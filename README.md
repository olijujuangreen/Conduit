# Conduit Networking

`Networking` is Conduit's reusable Swift transport package for Apple-platform
apps. It provides generic HTTP request modeling, request building, execution,
decoding, streaming, error handling, and test doubles without embedding
product-specific API behavior.

The package is designed for composition. App-specific services depend on
`NetworkClient`; they do not inherit default networking behavior from a protocol
extension.

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

## Quickstart

Import the package and create a client with a base URL. The client owns generic
transport concerns only.

```swift
import Foundation
import Networking

let client = URLSessionNetworkClient(
    baseURL: URL(string: "https://api.example.com")!,
    configuration: .ephemeral,
    defaultHeaders: [.accept(HTTPMediaType.json)],
    defaultTimeout: 30
)
```

Define response models in the app or API layer.

```swift
struct User: Codable, Sendable {
    let id: UUID
    let name: String
}
```

Describe each API operation as an endpoint.

```swift
struct GetCurrentUserEndpoint: Endpoint {
    typealias Response = User

    func makeRequest() throws -> HTTPRequest {
        HTTPRequest(
            method: .get,
            path: "v1/users/me"
        )
    }
}
```

Compose the client into an app-specific service.

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

Use `NetworkingTesting` in unit tests.

```swift
import NetworkingTesting
import Testing

@Test func loadsCurrentUser() async throws {
    let mock = try MockNetworkClient(
        response: StubResponse.json(
            User(id: UUID(), name: "Ada")
        )
    )

    let service = UserService(client: mock)
    let user = try await service.currentUser()

    #expect(user.name == "Ada")
    #expect(await mock.recorder.last()?.path == "v1/users/me")
}
```

## Documentation Map

- [`Architecture.md`](Architecture.md): how the package is layered
- [`Usage.md`](Usage.md): common request, endpoint, and client examples
- [`RequestBuilding.md`](RequestBuilding.md): how `HTTPRequest` becomes `URLRequest`
- [`Errors.md`](Errors.md): error model and handling guidance
- [`Streaming.md`](Streaming.md): byte streams, NDJSON, and SSE
- [`Testing.md`](Testing.md): mocks, request recording, stubs, and fixtures
- [`MigrationFromEkkos.md`](MigrationFromEkkos.md): differences from the old Ekkos target
