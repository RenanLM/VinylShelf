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
