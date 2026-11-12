import Foundation
import Testing
import VinylShelfCore
@testable import VinylShelf

struct MusicBrainzAlbumSearchViewModelTests {
    @Test("Changing text does not start a search automatically")
    @MainActor
    func waitsForExplicitSearchRequest() async {
        let searcher = StubMusicBrainzAlbumSearcher(
            behavior: .success([])
        )
        let viewModel = MusicBrainzAlbumSearchViewModel(
            albumSearcher: searcher
        )

        viewModel.searchText = "Kind of Blue"
        await Task.yield()

        #expect(viewModel.state == .idle)
        #expect(await searcher.receivedQueries().isEmpty)
    }

    @Test("Publishes results after a successful search")
    @MainActor
    func searchesSuccessfully() async {
        let result = makeResult(title: "Kind of Blue")
        let searcher = StubMusicBrainzAlbumSearcher(
            behavior: .success([result])
        )
        let viewModel = MusicBrainzAlbumSearchViewModel(
            albumSearcher: searcher
        )
        viewModel.searchText = "  Kind of Blue  "

        viewModel.search()

        #expect(
            await waitUntil {
                viewModel.state == .results([result])
            }
        )
        #expect(await searcher.receivedQueries() == ["Kind of Blue"])
    }

    @Test("Publishes an empty state when no albums are found")
    @MainActor
    func handlesEmptyResults() async {
        let viewModel = MusicBrainzAlbumSearchViewModel(
            albumSearcher: StubMusicBrainzAlbumSearcher(
                behavior: .success([])
            )
        )
        viewModel.searchText = "Missing Album"

        viewModel.search()

        #expect(await waitUntil { viewModel.state == .empty })
    }

    @Test("Publishes a specific message for MusicBrainz HTTP 503")
    @MainActor
    func handlesServiceUnavailable() async {
        let viewModel = MusicBrainzAlbumSearchViewModel(
            albumSearcher: StubMusicBrainzAlbumSearcher(
                behavior: .serviceUnavailable
            )
        )
        viewModel.searchText = "Kind of Blue"

        viewModel.search()

        #expect(
            await waitUntil {
                viewModel.state == .failed(
                    "O MusicBrainz está temporariamente indisponível. Tente novamente mais tarde."
                )
            }
        )
    }

    @Test("Stores the selected album result")
    @MainActor
    func selectsResult() {
        let viewModel = MusicBrainzAlbumSearchViewModel(
            albumSearcher: StubMusicBrainzAlbumSearcher(
                behavior: .success([])
            )
        )
        let result = makeResult(title: "Clube da Esquina")

        viewModel.select(result)

        #expect(viewModel.selectedResult == result)
    }

    @Test("Ignores an older response after a newer search")
    @MainActor
    func ignoresOutdatedResponse() async {
        let searcher = ControlledMusicBrainzAlbumSearcher()
        let viewModel = MusicBrainzAlbumSearchViewModel(
            albumSearcher: searcher
        )
        let olderResult = makeResult(title: "Older")
        let newerResult = makeResult(title: "Newer")

        viewModel.searchText = "First"
        viewModel.search()
        #expect(await waitForRequest("First", in: searcher))

        viewModel.searchText = "Second"
        viewModel.search()
        #expect(await waitForRequest("Second", in: searcher))

        await searcher.complete("Second", with: [newerResult])
        #expect(
            await waitUntil {
                viewModel.state == .results([newerResult])
            }
        )

        await searcher.complete("First", with: [olderResult])
        await Task.yield()

        #expect(viewModel.state == .results([newerResult]))
    }

    @Test("Cancellation prevents a pending response from changing state")
    @MainActor
    func cancelsPendingSearch() async {
        let searcher = ControlledMusicBrainzAlbumSearcher()
        let viewModel = MusicBrainzAlbumSearchViewModel(
            albumSearcher: searcher
        )
        viewModel.searchText = "Pending"
        viewModel.search()
        #expect(await waitForRequest("Pending", in: searcher))

        viewModel.cancelSearch()
        await searcher.complete(
            "Pending",
            with: [makeResult(title: "Ignored")]
        )
        await Task.yield()

        #expect(viewModel.state == .idle)
    }
}

private actor StubMusicBrainzAlbumSearcher: MusicBrainzAlbumSearching {
    enum Behavior: Sendable {
        case success([MusicBrainzAlbumSearchResult])
        case serviceUnavailable
    }

    private let behavior: Behavior
    private var queries: [String] = []

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func searchAlbums(
        matching searchText: String
    ) async throws -> [MusicBrainzAlbumSearchResult] {
        queries.append(searchText)

        switch behavior {
        case let .success(results):
            return results
        case .serviceUnavailable:
            throw MusicBrainzClientError.httpFailure(statusCode: 503)
        }
    }

    func receivedQueries() -> [String] {
        queries
    }
}

private actor ControlledMusicBrainzAlbumSearcher: MusicBrainzAlbumSearching {
    private var continuations: [
        String: CheckedContinuation<
            [MusicBrainzAlbumSearchResult],
            any Error
        >
    ] = [:]

    func searchAlbums(
        matching searchText: String
    ) async throws -> [MusicBrainzAlbumSearchResult] {
        try await withCheckedThrowingContinuation { continuation in
            continuations[searchText] = continuation
        }
    }

    func hasRequest(_ searchText: String) -> Bool {
        continuations[searchText] != nil
    }

    func complete(
        _ searchText: String,
        with results: [MusicBrainzAlbumSearchResult]
    ) {
        continuations.removeValue(forKey: searchText)?.resume(
            returning: results
        )
    }
}

@MainActor
private func waitUntil(
    _ condition: @escaping @MainActor () -> Bool
) async -> Bool {
    for _ in 0..<100 {
        if condition() { return true }
        await Task.yield()
    }

    return condition()
}

@MainActor
private func waitForRequest(
    _ searchText: String,
    in searcher: ControlledMusicBrainzAlbumSearcher
) async -> Bool {
    for _ in 0..<100 {
        if await searcher.hasRequest(searchText) { return true }
        await Task.yield()
    }

    return await searcher.hasRequest(searchText)
}

private func makeResult(
    title: String
) -> MusicBrainzAlbumSearchResult {
    MusicBrainzAlbumSearchResult(
        releaseGroupID: title,
        title: title,
        artist: "Artist",
        releaseYear: 2000
    )
}
