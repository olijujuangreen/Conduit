//
//  NetworkingTests.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import Foundation
import Networking
import NetworkingTesting
import Testing

@Test func urlRequestBuilderBuildsExpectedRequest() throws {
    let body = try HTTPBody.json(CreateWidgetRequest(name: "desk"))
    let request = HTTPRequest(
        method: .post,
        path: "v1/widgets",
        queryItems: [URLQueryItem(name: "include", value: "owner")],
        headers: [.accept(HTTPMediaType.json), .contentType("application/custom+json")],
        body: body,
        timeout: 12,
        cachePolicy: .reloadIgnoringLocalCacheData
    )

    let builder = URLRequestBuilder(
        baseURL: URL(string: "https://api.example.test/root")!,
        defaultHeaders: [.userAgent("NetworkingTests")]
    )

    let urlRequest = try builder.build(request)

    #expect(urlRequest.httpMethod == "POST")
    #expect(urlRequest.url?.absoluteString == "https://api.example.test/root/v1/widgets?include=owner")
    #expect(urlRequest.timeoutInterval == 12)
    #expect(urlRequest.cachePolicy == .reloadIgnoringLocalCacheData)
    #expect(urlRequest.value(forHTTPHeaderField: "Accept") == HTTPMediaType.json)
    #expect(urlRequest.value(forHTTPHeaderField: "User-Agent") == "NetworkingTests")
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/custom+json")
    #expect(urlRequest.httpBody == body.data)
}

@Test func urlSessionClientDecodesSuccessfulJSONResponse() async throws {
    let session = URLSession.stubbed(host: "decode.example.test") { request in
        #expect(request.value(forHTTPHeaderField: "X-Test") == "1")
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": HTTPMediaType.json]
        )!
        let body = try JSONEncoder().encode(Widget(id: 42, name: "desk"))
        return (response, body)
    }

    let client = URLSessionNetworkClient(
        baseURL: URL(string: "https://decode.example.test")!,
        session: session,
        requestAdapters: [HeaderInjectionAdapter(provider: StaticHeaderProvider([.init(name: "X-Test", value: "1")]))]
    )

    let response = try await client.decoded(Widget.self, for: HTTPRequest(path: "widgets/42"))

    #expect(response.statusCode == 200)
    #expect(response.body == Widget(id: 42, name: "desk"))
    #expect(response.headers["Content-Type"] == HTTPMediaType.json)
}

@Test func urlSessionClientSurfacesHTTPStatusFailureWithBody() async throws {
    let session = URLSession.stubbed(host: "status.example.test") { request in
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 422,
            httpVersion: nil,
            headerFields: ["Content-Type": HTTPMediaType.json]
        )!
        return (response, Data(#"{"error":"invalid"}"#.utf8))
    }

    let client = URLSessionNetworkClient(
        baseURL: URL(string: "https://status.example.test")!,
        session: session
    )

    do {
        _ = try await client.data(for: HTTPRequest(path: "widgets"))
        Issue.record("Expected request to fail.")
    } catch let error as NetworkError {
        guard case .httpStatus(let statusCode, let body, let headers) = error else {
            Issue.record("Expected HTTP status error, got \(error).")
            return
        }
        #expect(statusCode == 422)
        #expect(String(decoding: body, as: UTF8.self) == #"{"error":"invalid"}"#)
        #expect(headers["Content-Type"] == HTTPMediaType.json)
    }
}

@Test func mockNetworkClientRecordsRequestsAndDecodesJSON() async throws {
    let mock = try MockNetworkClient(
        response: StubResponse.json(Widget(id: 7, name: "lamp"))
    )

    let response = try await mock.decoded(
        Widget.self,
        for: HTTPRequest(method: .get, path: "widgets/7")
    )

    #expect(response.body == Widget(id: 7, name: "lamp"))
    #expect(await mock.recorder.count() == 1)
    #expect(await mock.recorder.last()?.path == "widgets/7")
}

@Test func byteStreamParsesLinesNDJSONAndServerSentEvents() async throws {
    let stream = StubResponse.stream(
        """
        {"id":1}
        {"id":2}
        event: log
        data: first
        data: second

        """
    ).body

    var values: [StreamValue] = []
    for try await value in stream.newlineDelimitedJSON(StreamValue.self) {
        values.append(value)
        if values.count == 2 {
            break
        }
    }

    #expect(values == [StreamValue(id: 1), StreamValue(id: 2)])

    let sseStream = StubResponse.stream("event: log\ndata: first\ndata: second\n\n").body
    var events: [ServerSentEvent] = []
    for try await event in sseStream.serverSentEvents() {
        events.append(event)
    }

    #expect(events == [ServerSentEvent(event: "log", data: "first\nsecond")])
}

@Test func endpointExecutionUsesTypedRequest() async throws {
    let mock = try MockNetworkClient(response: StubResponse.json(Widget(id: 3, name: "chair")))
    let response = try await mock.execute(GetWidgetEndpoint(id: 3))

    #expect(response.body == Widget(id: 3, name: "chair"))
    #expect(await mock.recorder.last()?.path == "widgets/3")
}

@Test func typedEmptyResponseEndpointsDecodeEmptyBodies() async throws {
    let mock = MockNetworkClient(response: StubResponse.empty())
    let response = try await mock.execute(DeleteWidgetEndpoint(id: 3))

    #expect(response.body == EmptyResponse())
    #expect(response.statusCode == 204)
    #expect(await mock.recorder.last()?.path == "widgets/3")
}

private struct Widget: Codable, Equatable, Sendable {
    var id: Int
    var name: String
}

private struct CreateWidgetRequest: Codable, Sendable {
    var name: String
}

private struct StreamValue: Codable, Equatable, Sendable {
    var id: Int
}

private struct GetWidgetEndpoint: Endpoint {
    typealias Response = Widget

    var id: Int

    func makeRequest() throws -> HTTPRequest {
        HTTPRequest(path: "widgets/\(id)")
    }
}

private struct DeleteWidgetEndpoint: Endpoint {
    typealias Response = EmptyResponse

    var id: Int

    func makeRequest() throws -> HTTPRequest {
        HTTPRequest(method: .delete, path: "widgets/\(id)")
    }
}

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) async throws -> (HTTPURLResponse, Data)

    nonisolated(unsafe) private static var handlers: [String: Handler] = [:]
    private static let lock = NSLock()

    static func setHandler(_ handler: @escaping Handler, forHost host: String) {
        lock.withLock {
            handlers[host] = handler
        }
    }

    static func handler(for request: URLRequest) -> Handler? {
        guard let host = request.url?.host else {
            return nil
        }

        return lock.withLock {
            handlers[host]
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler(for: request) else {
            client?.urlProtocol(self, didFailWithError: NetworkError.invalidResponse("Missing URLProtocolStub handler."))
            return
        }

        Task {
            do {
                let (response, data) = try await handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {}
}

private extension URLSession {
    static func stubbed(
        host: String,
        handler: @escaping @Sendable (URLRequest) async throws -> (HTTPURLResponse, Data)
    ) -> URLSession {
        URLProtocolStub.setHandler(handler, forHost: host)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }
}
