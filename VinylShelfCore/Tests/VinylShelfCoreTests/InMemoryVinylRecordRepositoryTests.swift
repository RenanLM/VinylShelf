import Foundation
import Testing
import VinylShelfCore

@Suite("InMemoryVinylRecordRepository")
struct InMemoryVinylRecordRepositoryTests {
    @Test("An empty repository returns no records")
    func emptyRepositoryReturnsNoRecords() async throws {
        let repository = InMemoryVinylRecordRepository()
        let missingID = UUID()

        let records = try await repository.fetchAll()
        let missingRecord = try await repository.fetch(id: missingID)

        #expect(records.isEmpty)
        #expect(missingRecord == nil)
    }

    @Test("Adds and fetches records")
    func addsAndFetchesRecords() async throws {
        let repository = InMemoryVinylRecordRepository()
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
    }

    @Test("Rejects a duplicate identifier without replacing the stored record")
    func rejectsDuplicateIdentifier() async throws {
        let repository = InMemoryVinylRecordRepository()
        let id = UUID()
        let originalRecord = VinylRecord(
            id: id,
            title: "Transa",
            artist: "Caetano Veloso",
            releaseYear: 1972,
            genre: "MPB"
        )
        let duplicateRecord = VinylRecord(
            id: id,
            title: "Cores, Nomes",
            artist: "Caetano Veloso",
            releaseYear: 1982,
            genre: "MPB"
        )
        try await repository.add(originalRecord)

        await #expect(
            throws: InMemoryVinylRecordRepositoryError.duplicateID(id)
        ) {
            try await repository.add(duplicateRecord)
        }

        let storedRecord = try await repository.fetch(id: id)
        #expect(storedRecord == originalRecord)
    }

    @Test("Updates an existing record")
    func updatesExistingRecord() async throws {
        let repository = InMemoryVinylRecordRepository()
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
    func rejectsUpdatingMissingRecord() async {
        let repository = InMemoryVinylRecordRepository()
        let record = VinylRecord(
            title: "Acabou Chorare",
            artist: "Novos Baianos"
        )

        await #expect(
            throws: InMemoryVinylRecordRepositoryError.recordNotFound(record.id)
        ) {
            try await repository.update(record)
        }
    }

    @Test("Removes an existing record")
    func removesExistingRecord() async throws {
        let repository = InMemoryVinylRecordRepository()
        let record = VinylRecord(
            title: "A Tábua de Esmeralda",
            artist: "Jorge Ben Jor",
            releaseYear: 1974,
            genre: "Samba rock"
        )
        try await repository.add(record)

        try await repository.remove(id: record.id)

        let storedRecord = try await repository.fetch(id: record.id)
        #expect(storedRecord == nil)
    }

    @Test("Rejects removing a missing record")
    func rejectsRemovingMissingRecord() async {
        let repository = InMemoryVinylRecordRepository()
        let missingID = UUID()

        await #expect(
            throws: InMemoryVinylRecordRepositoryError.recordNotFound(missingID)
        ) {
            try await repository.remove(id: missingID)
        }
    }
}
