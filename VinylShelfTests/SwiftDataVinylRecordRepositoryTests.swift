import Foundation
import SwiftData
import Testing
import VinylShelfCore
@testable import VinylShelf

struct SwiftDataVinylRecordRepositoryTests {
    @Test("Adds and fetches a record while preserving its UUID")
    func addsAndFetchesRecord() async throws {
        let repository = try makeRepository()
        let record = VinylRecord(
            title: "Clube da Esquina",
            artist: "Milton Nascimento & Lô Borges",
            releaseYear: 1972,
            genre: "MPB"
        )

        try await repository.add(record)

        let fetchedRecord = try await repository.fetch(id: record.id)
        let allRecords = try await repository.fetchAll()

        #expect(fetchedRecord == record)
        #expect(allRecords == [record])
        #expect(fetchedRecord?.id == record.id)
    }

    @Test("Rejects a duplicate UUID without replacing the stored record")
    func rejectsDuplicateUUID() async throws {
        let repository = try makeRepository()
        let id = UUID()
        let originalRecord = VinylRecord(
            id: id,
            title: "Transa",
            artist: "Caetano Veloso"
        )
        let duplicateRecord = VinylRecord(
            id: id,
            title: "Cores, Nomes",
            artist: "Caetano Veloso"
        )
        try await repository.add(originalRecord)

        await #expect(
            throws: SwiftDataVinylRecordRepositoryError.duplicateID(id)
        ) {
            try await repository.add(duplicateRecord)
        }

        let storedRecord = try await repository.fetch(id: id)
        #expect(storedRecord == originalRecord)
    }

    @Test("Updates an existing record")
    func updatesExistingRecord() async throws {
        let repository = try makeRepository()
        let id = UUID()
        let originalRecord = VinylRecord(
            id: id,
            title: "Construção",
            artist: "Chico Buarque"
        )
        let updatedRecord = VinylRecord(
            id: id,
            title: "Construção",
            artist: "Chico Buarque",
            releaseYear: 1971,
            genre: "MPB"
        )
        try await repository.add(originalRecord)

        try await repository.update(updatedRecord)

        let storedRecord = try await repository.fetch(id: id)
        #expect(storedRecord == updatedRecord)
    }

    @Test("Rejects updating a missing record")
    func rejectsUpdatingMissingRecord() async throws {
        let repository = try makeRepository()
        let record = VinylRecord(
            title: "Acabou Chorare",
            artist: "Novos Baianos"
        )

        await #expect(
            throws: SwiftDataVinylRecordRepositoryError.recordNotFound(
                record.id
            )
        ) {
            try await repository.update(record)
        }
    }

    @Test("Removes a record and rejects removing it again")
    func removesExistingRecord() async throws {
        let repository = try makeRepository()
        let record = VinylRecord(
            title: "A Tábua de Esmeralda",
            artist: "Jorge Ben Jor"
        )
        try await repository.add(record)

        try await repository.remove(id: record.id)

        let storedRecord = try await repository.fetch(id: record.id)
        #expect(storedRecord == nil)

        await #expect(
            throws: SwiftDataVinylRecordRepositoryError.recordNotFound(
                record.id
            )
        ) {
            try await repository.remove(id: record.id)
        }
    }
}

private func makeRepository() throws -> SwiftDataVinylRecordRepository {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: VinylRecordEntity.self,
        configurations: configuration
    )
    return SwiftDataVinylRecordRepository(modelContainer: container)
}
