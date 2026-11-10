import Foundation
import Observation
import VinylShelfCore

@MainActor
@Observable
final class VinylCatalogViewModel {
    enum State: Equatable {
        case loading
        case loaded([VinylRecord])
        case empty
        case failed(String)
    }

    private(set) var state: State = .loading

    @ObservationIgnored
    private let repository: any VinylRecordRepository

    init(repository: any VinylRecordRepository) {
        self.repository = repository
    }

    func load() async {
        state = .loading

        do {
            let records = try await repository.fetchAll()
            let sortedRecords = records.sorted(by: Self.precedesByTitle)
            state = sortedRecords.isEmpty ? .empty : .loaded(sortedRecords)
        } catch {
            state = .failed("Não foi possível carregar sua coleção.")
        }
    }

    private static func precedesByTitle(
        _ firstRecord: VinylRecord,
        _ secondRecord: VinylRecord
    ) -> Bool {
        let titleComparison = firstRecord.title.localizedCaseInsensitiveCompare(
            secondRecord.title
        )

        if titleComparison != .orderedSame {
            return titleComparison == .orderedAscending
        }

        let artistComparison = firstRecord.artist.localizedCaseInsensitiveCompare(
            secondRecord.artist
        )

        if artistComparison != .orderedSame {
            return artistComparison == .orderedAscending
        }

        return firstRecord.id.uuidString < secondRecord.id.uuidString
    }
}
