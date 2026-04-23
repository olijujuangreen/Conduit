# Testing

`NetworkingTesting` provides helpers for app and package tests that should not
hit the network.

## MockNetworkClient

`MockNetworkClient` conforms to `NetworkClient`. It can return fixed responses,
throw fixed errors, or use request-aware handlers.

```swift
let mock = try MockNetworkClient(
    response: StubResponse.json(User(id: UUID(), name: "Ada"))
)

let user = try await mock.execute(GetCurrentUserEndpoint()).body
```

## Request Recording

Every mock request is recorded by an actor-backed `RequestRecorder`.

```swift
#expect(await mock.recorder.count() == 1)
#expect(await mock.recorder.last()?.path == "v1/users/me")
```

## Request-Aware Stubs

Use a handler when the response depends on the request.

```swift
let mock = MockNetworkClient { request in
    if request.path == "v1/users/me" {
        return try StubResponse.json(User(id: UUID(), name: "Ada"))
    }

    throw NetworkError.httpStatus(
        statusCode: 404,
        body: Data(),
        headers: HTTPHeaders()
    )
}
```

## Empty Responses

```swift
let mock = MockNetworkClient(response: StubResponse.empty())

let response = try await mock.execute(DeleteUserEndpoint(id: user.id))

#expect(response.body == EmptyResponse())
```

## Streaming Stubs

```swift
let streamResponse = StubResponse.stream(
    """
    event: log
    data: started

    event: log
    data: finished

    """
)
```

## Fixtures

`FixtureLoader` loads data or decodes JSON from a caller-provided bundle.

```swift
let data = try FixtureLoader.data(
    named: "user",
    extension: "json",
    bundle: .module
)

let user = try FixtureLoader.decoded(
    User.self,
    named: "user",
    bundle: .module
)
```
