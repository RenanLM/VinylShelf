import Testing
@testable import VinylShelf

struct VinylRecordFormInputTests {
    @Test("Creates a normalized record from valid input")
    func createsNormalizedRecord() throws {
        let input = VinylRecordFormInput(
            title: "  Clube da Esquina  ",
            artist: "  Milton Nascimento & Lô Borges  ",
            releaseYear: " 1972 ",
            genre: "  MPB  "
        )

        let record = try input.makeRecord(currentYear: 2026)

        #expect(record.title == "Clube da Esquina")
        #expect(record.artist == "Milton Nascimento & Lô Borges")
        #expect(record.releaseYear == 1972)
        #expect(record.genre == "MPB")
    }

    @Test("Converts empty optional fields to nil")
    func convertsEmptyOptionalFieldsToNil() throws {
        let input = VinylRecordFormInput(
            title: "Construção",
            artist: "Chico Buarque",
            releaseYear: "   ",
            genre: "   "
        )

        let record = try input.makeRecord(currentYear: 2026)

        #expect(record.releaseYear == nil)
        #expect(record.genre == nil)
    }

    @Test("Requires a title")
    func requiresTitle() {
        let input = VinylRecordFormInput(
            title: "   ",
            artist: "Djavan"
        )

        #expect(throws: VinylRecordFormValidationError.titleRequired) {
            try input.makeRecord(currentYear: 2026)
        }
    }

    @Test("Requires an artist")
    func requiresArtist() {
        let input = VinylRecordFormInput(
            title: "Luz",
            artist: "   "
        )

        #expect(throws: VinylRecordFormValidationError.artistRequired) {
            try input.makeRecord(currentYear: 2026)
        }
    }

    @Test(
        "Rejects an invalid release year",
        arguments: ["unknown", "1899", "2027"]
    )
    func rejectsInvalidReleaseYear(_ releaseYear: String) {
        let input = VinylRecordFormInput(
            title: "Luz",
            artist: "Djavan",
            releaseYear: releaseYear
        )

        #expect(throws: VinylRecordFormValidationError.invalidReleaseYear) {
            try input.makeRecord(currentYear: 2026)
        }
    }
}
