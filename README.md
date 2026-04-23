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

## What Belongs Here

- Generic request descriptions
- URL request construction
- URLSession-backed execution
- JSON encoding and decoding hooks
- Raw data responses
- Empty responses
- HTTP response metadata
- Streaming bytes, lines, NDJSON, and server-sent events
- Request adapters for generic header injection or tracing
- Response observers for logging and metrics
- Mock clients, request recorders, stubs, and fixture helpers

## What Does Not Belong Here

- Product-specific API clients
- Token storage
- User defaults
- UI notifications
- Environment selection policy
- Backend-specific error phrase parsing
- Product-specific headers
- App login/logout behavior

## Documentation Map

- [`Architecture.md`](Architecture.md): how the package is layered
- [`Usage.md`](Usage.md): common request, endpoint, and client examples
- [`RequestBuilding.md`](RequestBuilding.md): how `HTTPRequest` becomes `URLRequest`
- [`Errors.md`](Errors.md): error model and handling guidance
- [`Streaming.md`](Streaming.md): byte streams, NDJSON, and SSE
- [`Testing.md`](Testing.md): mocks, request recording, stubs, and fixtures
- [`MigrationFromEkkos.md`](MigrationFromEkkos.md): differences from the old Ekkos target
