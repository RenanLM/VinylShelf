import Foundation
import Observation
import VinylShelfCore

protocol MusicBrainzAlbumSearching: Sendable {
    func searchAlbums(
        matching searchText: String
    ) async throws -> [MusicBrainzAlbumSearchResult]
}

extension MusicBrainzClient: MusicBrainzAlbumSearching {}

@MainActor
@Observable
final class MusicBrainzAlbumSearchViewModel {
    enum State: Equatable {
        case idle
        case loading
        case results([MusicBrainzAlbumSearchResult])
        case empty
        case failed(String)
    }

    var searchText = ""
    private(set) var state: State = .idle
    private(set) var selectedResult: MusicBrainzAlbumSearchResult?

    var canSearch: Bool {
        !searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty && !isLoading
    }

    var isLoading: Bool {
        state == .loading
    }

    @ObservationIgnored
    private let albumSearcher: any MusicBrainzAlbumSearching

    @ObservationIgnored
    private var searchTask: Task<Void, Never>?

    @ObservationIgnored
    private var searchGeneration = 0

    init(albumSearcher: any MusicBrainzAlbumSearching) {
        self.albumSearcher = albumSearcher
    }

    func search() {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            cancelSearch()
            state = .idle
            return
        }

        searchGeneration &+= 1
        let currentGeneration = searchGeneration
        searchTask?.cancel()
        state = .loading

        let albumSearcher = albumSearcher
        searchTask = Task { [weak self] in
            do {
                let results = try await albumSearcher.searchAlbums(
                    matching: query
                )

                guard let self,
                      !Task.isCancelled,
                      searchGeneration == currentGeneration else {
                    return
                }

                state = results.isEmpty ? .empty : .results(results)
                searchTask = nil
            } catch {
                guard let self,
                      !Task.isCancelled,
                      searchGeneration == currentGeneration else {
                    return
                }

                state = .failed(Self.message(for: error))
                searchTask = nil
            }
        }
    }

    func select(_ result: MusicBrainzAlbumSearchResult) {
        selectedResult = result
    }

    func cancelSearch() {
        searchGeneration &+= 1
        searchTask?.cancel()
        searchTask = nil

        if state == .loading {
            state = .idle
        }
    }

    private static func message(for error: any Error) -> String {
        if let clientError = error as? MusicBrainzClientError,
           clientError == .httpFailure(statusCode: 503) {
            return "O MusicBrainz está temporariamente indisponível. Tente novamente mais tarde."
        }

        return "Não foi possível buscar álbuns. Verifique sua conexão e tente novamente."
    }
}
