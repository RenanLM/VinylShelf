import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Testing
@testable import VinylShelfCore

@Suite("MusicBrainzClient")
struct MusicBrainzClientTests {
    @Test("Decodes valid release groups and partial dates")
    func decodesValidResponse() async throws {
        let loader = try MockMusicBrainzHTTPDataLoader(
            data: fixture(named: "valid-release-groups"),
            statusCode: 200
        )
        let client = makeClient(dataLoader: loader)

        let results = try await client.searchAlbums(matching: "album")

        #expect(
            results == [
                MusicBrainzAlbumSearchResult(
                    releaseGroupID: "1f3d6d8e-2f8f-4e44-9734-9ad7c0c3f507",
                    title: "Kind of Blue",
                    artist: "Miles Davis",
                    releaseYear: 1959
                ),
                MusicBrainzAlbumSearchResult(
                    releaseGroupID: "c6f6d3be-3f90-4c58-86ba-982fbb09ad04",
                    title: "Clube da Esquina",
                    artist: "Milton Nascimento & Lô Borges",
                    releaseYear: 1972
                ),
            ]
        )
    }

    @Test("Keeps an album result when its year is absent")
    func handlesMissingYear() async throws {
        let loader = try MockMusicBrainzHTTPDataLoader(
            data: fixture(named: "release-group-without-year"),
            statusCode: 200
        )
        let client = makeClient(dataLoader: loader)

        let results = try await client.searchAlbums(matching: "No Date")

        #expect(results.count == 1)
        #expect(results.first?.artist == "Unknown Artist")
        #expect(results.first?.releaseYear == nil)
    }

    @Test("Keeps an album result without optional fields")
    func handlesMissingOptionalFields() async throws {
        let loader = try MockMusicBrainzHTTPDataLoader(
            data: fixture(named: "release-group-without-optionals"),
            statusCode: 200
        )
        let client = makeClient(dataLoader: loader)

        let results = try await client.searchAlbums(matching: "Minimal")

        #expect(results.count == 1)
        #expect(results.first?.title == "Minimal Album")
        #expect(results.first?.artist == nil)
        #expect(results.first?.releaseYear == nil)
    }

    @Test("Returns an empty array when the search has no results")
    func handlesEmptyResults() async throws {
        let loader = try MockMusicBrainzHTTPDataLoader(
            data: fixture(named: "empty-release-groups"),
            statusCode: 200
        )
        let client = makeClient(dataLoader: loader)

        let results = try await client.searchAlbums(matching: "Missing")

        #expect(results.isEmpty)
    }

    @Test("Throws the HTTP status code for an unsuccessful response")
    func handlesHTTPFailure() async throws {
        let loader = MockMusicBrainzHTTPDataLoader(
            data: Data(),
            statusCode: 503
        )
        let client = makeClient(dataLoader: loader)

        await #expect(
            throws: MusicBrainzClientError.httpFailure(statusCode: 503)
        ) {
            try await client.searchAlbums(matching: "Kind of Blue")
        }
    }

    @Test("Throws a decoding error for invalid JSON")
    func handlesInvalidJSON() async throws {
        let loader = try MockMusicBrainzHTTPDataLoader(
            data: fixture(named: "invalid-response"),
            statusCode: 200
        )
        let client = makeClient(dataLoader: loader)

        await #expect(throws: MusicBrainzClientError.decodingFailure) {
            try await client.searchAlbums(matching: "Kind of Blue")
        }
    }

    @Test("Maps transport errors to a network failure")
    func handlesNetworkFailure() async {
        let client = makeClient(
            dataLoader: MockMusicBrainzHTTPDataLoader(
                error: .networkConnectionLost
            )
        )

        await #expect(throws: MusicBrainzClientError.networkFailure) {
            try await client.searchAlbums(matching: "Kind of Blue")
        }
    }

    @Test("Builds the release-group album search request")
    func buildsSearchRequest() async throws {
        let loader = try MockMusicBrainzHTTPDataLoader(
            data: fixture(named: "empty-release-groups"),
            statusCode: 200
        )
        let client = makeClient(dataLoader: loader)

        _ = try await client.searchAlbums(matching: "  Kind of Blue  ")

        let request = try #require(await loader.lastRequest())
        let url = try #require(request.url)
        let components = try #require(
            URLComponents(url: url, resolvingAgainstBaseURL: false)
        )
        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).compactMap {
                item in
                item.value.map { (item.name, $0) }
            }
        )

        #expect(components.scheme == "https")
        #expect(components.host == "musicbrainz.org")
        #expect(components.path == "/ws/2/release-group")
        #expect(
            queryItems["query"] == "Kind of Blue AND primarytype:album"
        )
        #expect(queryItems["fmt"] == "json")
        #expect(queryItems["limit"] == "25")
        #expect(request.httpMethod == "GET")
        #expect(
            request.value(forHTTPHeaderField: "User-Agent")
                == MusicBrainzClient.defaultUserAgent
        )
    }

    private func makeClient(
        dataLoader: any MusicBrainzHTTPDataLoading
    ) -> MusicBrainzClient {
        MusicBrainzClient(
            dataLoader: dataLoader,
            rateLimiter: ImmediateMusicBrainzRequestRateLimiter()
        )
    }

    private func fixture(named name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json")
        )
        return try Data(contentsOf: url)
    }
}

private actor MockMusicBrainzHTTPDataLoader: MusicBrainzHTTPDataLoading {
    private let data: Data
    private let statusCode: Int
    private let error: URLError?
    private var requests: [URLRequest] = []

    init(data: Data, statusCode: Int) {
        self.data = data
        self.statusCode = statusCode
        error = nil
    }

    init(error: URLError.Code) {
        data = Data()
        statusCode = 0
        self.error = URLError(error)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)

        if let error {
            throw error
        }

        let url = try #require(request.url)
        let response = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )
        )
        return (data, response)
    }

    func lastRequest() -> URLRequest? {
        requests.last
    }
}

private struct ImmediateMusicBrainzRequestRateLimiter:
    MusicBrainzRequestRateLimiting {
    func waitForPermission() async throws {}
}
