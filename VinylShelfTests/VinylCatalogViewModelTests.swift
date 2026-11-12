import Foundation
import Testing
import VinylShelfCore
@testable import VinylShelf

struct VinylCatalogViewModelTests {
    @Test("Starts loading and becomes empty when the repository has no records")
    @MainActor
    func loadsEmptyCollection() async {
        let viewModel = VinylCatalogViewModel(
            repository: InMemoryVinylRecordRepository()
        )

        #expect(viewModel.state == .loading)

        await viewModel.load()

        #expect(viewModel.state == .empty)
        viewModel.searchText = "qualquer disco"
        #expect(viewModel.hasNoSearchResults == false)
    }

    @Test("Loads records ordered by title")
    @MainActor
    func loadsRecordsOrderedByTitle() async throws {
        let lastRecord = VinylRecord(title: "Zulu", artist: "Artist B")
        let firstRecord = VinylRecord(title: "Alpha", artist: "Artist A")
        let repository = try InMemoryVinylRecordRepository(
            records: [lastRecord, firstRecord]
        )
        let viewModel = VinylCatalogViewModel(repository: repository)

        await viewModel.load()

        #expect(viewModel.state == .loaded([firstRecord, lastRecord]))
    }

    @Test("Finds a loaded record by its identifier")
    @MainActor
    func findsLoadedRecordByID() async throws {
        let record = VinylRecord(title: "Luz", artist: "Djavan")
        let repository = try InMemoryVinylRecordRepository(records: [record])
        let viewModel = VinylCatalogViewModel(repository: repository)
        await viewModel.load()

        #expect(viewModel.record(id: record.id) == record)
        #expect(viewModel.record(id: UUID()) == nil)
    }

    @Test("Exposes no-results state for a loaded catalog search")
    @MainActor
    func exposesNoSearchResults() async throws {
        let record = VinylRecord(title: "Luz", artist: "Djavan")
        let repository = try InMemoryVinylRecordRepository(records: [record])
        let viewModel = VinylCatalogViewModel(repository: repository)
        await viewModel.load()

        viewModel.searchText = "The Beatles"

        #expect(viewModel.filteredRecords.isEmpty)
        #expect(viewModel.hasNoSearchResults)
    }

    @Test("Adds a record and reloads the catalog")
    @MainActor
    func addsRecordAndReloadsCatalog() async throws {
        let repository = InMemoryVinylRecordRepository()
        let viewModel = VinylCatalogViewModel(repository: repository)
        let record = VinylRecord(
            title: "Elis & Tom",
            artist: "Elis Regina & Tom Jobim",
            releaseYear: 1974,
            genre: "MPB"
        )

        try await viewModel.add(record)

        #expect(viewModel.state == .loaded([record]))
        #expect(try await repository.fetch(id: record.id) == record)
    }

    @Test("Propagates an error when adding fails")
    @MainActor
    func propagatesAddError() async {
        let viewModel = VinylCatalogViewModel(
            repository: FailingVinylRecordRepository()
        )
        let record = VinylRecord(title: "Transa", artist: "Caetano Veloso")

        await #expect(throws: RepositoryFailure.self) {
            try await viewModel.add(record)
        }
    }

    @Test("Updates a record and reloads the catalog")
    @MainActor
    func updatesRecordAndReloadsCatalog() async throws {
        let originalRecord = VinylRecord(
            title: "Elis & Tom",
            artist: "Elis Regina & Tom Jobim"
        )
        let updatedRecord = VinylRecord(
            id: originalRecord.id,
            title: "Elis & Tom",
            artist: "Elis Regina & Tom Jobim",
            releaseYear: 1974,
            genre: "MPB"
        )
        let repository = try InMemoryVinylRecordRepository(
            records: [originalRecord]
        )
        let viewModel = VinylCatalogViewModel(repository: repository)
        await viewModel.load()

        try await viewModel.update(updatedRecord)

        #expect(viewModel.state == .loaded([updatedRecord]))
        #expect(viewModel.isUpdating == false)
        #expect(
            try await repository.fetch(id: originalRecord.id) == updatedRecord
        )
        #expect(viewModel.record(id: originalRecord.id) == updatedRecord)
    }

    @Test("Keeps the current catalog when updating fails")
    @MainActor
    func keepsCatalogWhenUpdateFails() async {
        let originalRecord = VinylRecord(
            title: "Construção",
            artist: "Chico Buarque"
        )
        let updatedRecord = VinylRecord(
            id: originalRecord.id,
            title: "Construção",
            artist: "Chico Buarque",
            releaseYear: 1971
        )
        let repository = UpdateFailingVinylRecordRepository(
            record: originalRecord
        )
        let viewModel = VinylCatalogViewModel(repository: repository)
        await viewModel.load()

        await #expect(throws: RepositoryFailure.self) {
            try await viewModel.update(updatedRecord)
        }

        #expect(viewModel.state == .loaded([originalRecord]))
        #expect(viewModel.isUpdating == false)
        let storedRecord = try? await repository.fetch(id: originalRecord.id)
        #expect(storedRecord == originalRecord)
    }

    @Test("Deletes a record and shows the empty state")
    @MainActor
    func deletesRecordAndShowsEmptyState() async throws {
        let record = VinylRecord(title: "Luz", artist: "Djavan")
        let repository = try InMemoryVinylRecordRepository(records: [record])
        let viewModel = VinylCatalogViewModel(repository: repository)
        await viewModel.load()

        try await viewModel.delete(record)

        #expect(viewModel.state == .empty)
        #expect(viewModel.isDeleting == false)
        #expect(try await repository.fetch(id: record.id) == nil)
    }

    @Test("Keeps the record when deletion fails")
    @MainActor
    func keepsRecordWhenDeletionFails() async {
        let record = VinylRecord(title: "Transa", artist: "Caetano Veloso")
        let repository = RemoveFailingVinylRecordRepository(record: record)
        let viewModel = VinylCatalogViewModel(repository: repository)
        await viewModel.load()

        await #expect(throws: RepositoryFailure.self) {
            try await viewModel.delete(record)
        }

        #expect(viewModel.state == .loaded([record]))
        #expect(viewModel.isDeleting == false)
    }

    @Test("Exposes an error state when loading fails")
    @MainActor
    func exposesLoadingError() async {
        let viewModel = VinylCatalogViewModel(
            repository: FailingVinylRecordRepository()
        )

        await viewModel.load()

        #expect(
            viewModel.state == .failed(
                "Não foi possível carregar sua coleção."
            )
        )
    }
}

private struct RepositoryFailure: Error {}

private actor FailingVinylRecordRepository: VinylRecordRepository {
    func fetchAll() async throws -> [VinylRecord] {
        throw RepositoryFailure()
    }

    func fetch(id: UUID) async throws -> VinylRecord? {
        throw RepositoryFailure()
    }

    func add(_ record: VinylRecord) async throws {
        throw RepositoryFailure()
    }

    func update(_ record: VinylRecord) async throws {
        throw RepositoryFailure()
    }

    func remove(id: UUID) async throws {
        throw RepositoryFailure()
    }
}

private actor RemoveFailingVinylRecordRepository: VinylRecordRepository {
    let record: VinylRecord

    init(record: VinylRecord) {
        self.record = record
    }

    func fetchAll() async throws -> [VinylRecord] {
        [record]
    }

    func fetch(id: UUID) async throws -> VinylRecord? {
        id == record.id ? record : nil
    }

    func add(_ record: VinylRecord) async throws {
        throw RepositoryFailure()
    }

    func update(_ record: VinylRecord) async throws {
        throw RepositoryFailure()
    }

    func remove(id: UUID) async throws {
        throw RepositoryFailure()
    }
}

private actor UpdateFailingVinylRecordRepository: VinylRecordRepository {
    let record: VinylRecord

    init(record: VinylRecord) {
        self.record = record
    }

    func fetchAll() async throws -> [VinylRecord] {
        [record]
    }

    func fetch(id: UUID) async throws -> VinylRecord? {
        id == record.id ? record : nil
    }

    func add(_ record: VinylRecord) async throws {
        throw RepositoryFailure()
    }

    func update(_ record: VinylRecord) async throws {
        throw RepositoryFailure()
    }

    func remove(id: UUID) async throws {
        throw RepositoryFailure()
    }
}
