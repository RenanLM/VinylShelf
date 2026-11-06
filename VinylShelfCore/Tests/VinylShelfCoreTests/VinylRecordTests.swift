import Foundation
import Testing
import VinylShelfCore

@Suite("VinylRecord")
struct VinylRecordTests {
    @Test("Initializes with all informed values")
    func initializesWithAllInformedValues() {
        let id = UUID()

        let record = VinylRecord(
            id: id,
            title: "The Dark Side of the Moon",
            artist: "Pink Floyd",
            releaseYear: 1973,
            genre: "Progressive rock"
        )

        #expect(record.id == id)
        #expect(record.title == "The Dark Side of the Moon")
        #expect(record.artist == "Pink Floyd")
        #expect(record.releaseYear == 1973)
        #expect(record.genre == "Progressive rock")
    }

    @Test("Defaults optional details to nil")
    func usesDefaultValues() {
        let record = VinylRecord(
            title: "Clube da Esquina",
            artist: "Milton Nascimento & Lô Borges"
        )

        #expect(record.releaseYear == nil)
        #expect(record.genre == nil)
    }

    @Test("Records with the same values are equal")
    func comparesByValue() {
        let id = UUID()
        let firstRecord = VinylRecord(
            id: id,
            title: "Djavan",
            artist: "Djavan",
            releaseYear: 1978,
            genre: "MPB"
        )
        let secondRecord = VinylRecord(
            id: id,
            title: "Djavan",
            artist: "Djavan",
            releaseYear: 1978,
            genre: "MPB"
        )

        #expect(firstRecord == secondRecord)
    }
}
