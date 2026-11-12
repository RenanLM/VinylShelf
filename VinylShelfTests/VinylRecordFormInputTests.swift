import Testing
import VinylShelfCore
@testable import VinylShelf

struct VinylRecordFormInputTests {
    @Test("Initializes editing input with the record values")
    func initializesInputForEditing() {
        let record = VinylRecord(
            title: "Luz",
            artist: "Djavan",
            releaseYear: 1982,
            genre: "MPB"
        )

        let input = VinylRecordFormInput(record: record)

        #expect(input.title == "Luz")
        #expect(input.artist == "Djavan")
        #expect(input.releaseYear == "1982")
        #expect(input.genre == "MPB")
    }

    @Test("Applies a MusicBrainz result to the editable fields")
    func appliesMusicBrainzResult() {
        var input = VinylRecordFormInput(genre: "Jazz")
        let result = MusicBrainzAlbumSearchResult(
            releaseGroupID: "release-group-id",
            title: "Kind of Blue",
            artist: "Miles Davis",
            releaseYear: 1959
        )

        input.apply(result)

        #expect(input.title == "Kind of Blue")
        #expect(input.artist == "Miles Davis")
        #expect(input.releaseYear == "1959")
        #expect(input.genre == "Jazz")
    }

    @Test("Clears unavailable MusicBrainz fields without changing genre")
    func appliesMusicBrainzResultWithMissingValues() {
        var input = VinylRecordFormInput(
            artist: "Previous Artist",
            releaseYear: "2000",
            genre: "Rock"
        )
        let result = MusicBrainzAlbumSearchResult(
            releaseGroupID: "release-group-id",
            title: "Unknown Album",
            artist: nil,
            releaseYear: nil
        )

        input.apply(result)

        #expect(input.title == "Unknown Album")
        #expect(input.artist.isEmpty)
        #expect(input.releaseYear.isEmpty)
        #expect(input.genre == "Rock")
    }

    @Test("Preserves the original UUID when creating an edited record")
    func preservesOriginalIDWhenEditing() throws {
        let originalRecord = VinylRecord(
            title: "Luz",
            artist: "Djavan",
            releaseYear: 1982
        )
        let input = VinylRecordFormInput(
            title: "  Luz  ",
            artist: "  Djavan  ",
            releaseYear: "1982",
            genre: "  MPB  "
        )

        let editedRecord = try input.makeRecord(
            id: originalRecord.id,
            currentYear: 2026
        )

        #expect(editedRecord.id == originalRecord.id)
        #expect(editedRecord.genre == "MPB")
    }

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
