import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum MusicBrainzClientError: Error, Equatable, Sendable {
    case invalidURL
    case invalidResponse
    case httpFailure(statusCode: Int)
    case networkFailure
    case decodingFailure
}

public struct MusicBrainzClient: Sendable {
    public static let defaultUserAgent =
        "VinylShelf/1.0 (https://github.com/RenanLM/VinylShelf)"

    private static let sharedRateLimiter = MusicBrainzRequestRateLimiter()

    private let userAgent: String
    private let dataLoader: any MusicBrainzHTTPDataLoading
    private let rateLimiter: any MusicBrainzRequestRateLimiting

    public init(userAgent: String = Self.defaultUserAgent) {
        self.init(
            userAgent: userAgent,
            dataLoader: URLSessionMusicBrainzHTTPDataLoader(),
            rateLimiter: Self.sharedRateLimiter
        )
    }

    init(
        userAgent: String = Self.defaultUserAgent,
        dataLoader: any MusicBrainzHTTPDataLoading,
        rateLimiter: any MusicBrainzRequestRateLimiting
    ) {
        self.userAgent = userAgent
        self.dataLoader = dataLoader
        self.rateLimiter = rateLimiter
    }

    public func searchAlbums(
        matching searchText: String
    ) async throws -> [MusicBrainzAlbumSearchResult] {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !query.isEmpty else { return [] }

        let request = try makeRequest(query: query)
        try await rateLimiter.waitForPermission()

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await dataLoader.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw MusicBrainzClientError.networkFailure
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MusicBrainzClientError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw MusicBrainzClientError.httpFailure(
                statusCode: httpResponse.statusCode
            )
        }

        let responseModel: MusicBrainzReleaseGroupSearchResponse

        do {
            responseModel = try JSONDecoder().decode(
                MusicBrainzReleaseGroupSearchResponse.self,
                from: data
            )
        } catch {
            throw MusicBrainzClientError.decodingFailure
        }

        return responseModel.releaseGroups.compactMap(\.searchResult)
    }

    private func makeRequest(query: String) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "musicbrainz.org"
        components.path = "/ws/2/release-group"
        components.queryItems = [
            URLQueryItem(
                name: "query",
                value: "\(query) AND primarytype:album"
            ),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: "25"),
        ]

        guard let url = components.url else {
            throw MusicBrainzClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}

protocol MusicBrainzHTTPDataLoading: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

private struct URLSessionMusicBrainzHTTPDataLoader: MusicBrainzHTTPDataLoading {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

protocol MusicBrainzRequestRateLimiting: Sendable {
    func waitForPermission() async throws
}

private actor MusicBrainzRequestRateLimiter: MusicBrainzRequestRateLimiting {
    private let clock = ContinuousClock()
    private let minimumInterval: Duration = .seconds(1)
    private var nextAllowedRequest: ContinuousClock.Instant?

    func waitForPermission() async throws {
        let now = clock.now
        let scheduledRequest = if let nextAllowedRequest,
                                  nextAllowedRequest > now {
            nextAllowedRequest
        } else {
            now
        }

        nextAllowedRequest = scheduledRequest.advanced(by: minimumInterval)

        if scheduledRequest > now {
            try await clock.sleep(until: scheduledRequest)
        }
    }
}

private struct MusicBrainzReleaseGroupSearchResponse: Codable {
    let releaseGroups: [MusicBrainzReleaseGroup]

    private enum CodingKeys: String, CodingKey {
        case releaseGroups = "release-groups"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        releaseGroups = try container.decodeIfPresent(
            [MusicBrainzReleaseGroup].self,
            forKey: .releaseGroups
        ) ?? []
    }
}

private struct MusicBrainzReleaseGroup: Codable {
    let id: String?
    let title: String?
    let firstReleaseDate: String?
    let artistCredits: [MusicBrainzArtistCredit]?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case firstReleaseDate = "first-release-date"
        case artistCredits = "artist-credit"
    }

    var searchResult: MusicBrainzAlbumSearchResult? {
        guard let releaseGroupID = normalized(id),
              let title = normalized(title) else {
            return nil
        }

        return MusicBrainzAlbumSearchResult(
            releaseGroupID: releaseGroupID,
            title: title,
            artist: artistName,
            releaseYear: releaseYear
        )
    }

    private var artistName: String? {
        guard let artistCredits else { return nil }

        let value = artistCredits.reduce(into: "") { result, credit in
            guard let name = normalized(credit.name ?? credit.artist?.name)
            else { return }

            result += name
            result += credit.joinPhrase ?? ""
        }

        return normalized(value)
    }

    private var releaseYear: Int? {
        guard let firstReleaseDate,
              let year = firstReleaseDate.split(separator: "-").first else {
            return nil
        }

        return Int(year)
    }

    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }

        let normalizedValue = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return normalizedValue.isEmpty ? nil : normalizedValue
    }
}

private struct MusicBrainzArtistCredit: Codable {
    let name: String?
    let joinPhrase: String?
    let artist: MusicBrainzArtist?

    private enum CodingKeys: String, CodingKey {
        case name
        case joinPhrase = "joinphrase"
        case artist
    }
}

private struct MusicBrainzArtist: Codable {
    let name: String?
}
