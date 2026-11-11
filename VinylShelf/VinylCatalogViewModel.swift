import Foundation
import Observation
import VinylShelfCore

@MainActor
@Observable
final class VinylCatalogViewModel {
    enum OperationError: Error, Equatable, Sendable {
        case updateAlreadyInProgress
    }

    enum State: Equatable {
        case loading
        case loaded([VinylRecord])
        case empty
        case failed(String)
    }

    private(set) var state: State = .loading
    private(set) var recordBeingDeletedID: UUID?
    private(set) var recordBeingUpdatedID: UUID?

    var isDeleting: Bool {
        recordBeingDeletedID != nil
    }

    var isUpdating: Bool {
        recordBeingUpdatedID != nil
    }

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

    func add(_ record: VinylRecord) async throws {
        try await repository.add(record)
        await load()
    }

    func update(_ record: VinylRecord) async throws {
        guard recordBeingUpdatedID == nil else {
            throw OperationError.updateAlreadyInProgress
        }

        recordBeingUpdatedID = record.id
        defer { recordBeingUpdatedID = nil }

        try await repository.update(record)
        await load()
    }

    func delete(_ record: VinylRecord) async throws {
        guard recordBeingDeletedID == nil else { return }

        recordBeingDeletedID = record.id
        defer { recordBeingDeletedID = nil }

        try await repository.remove(id: record.id)
        await load()
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
