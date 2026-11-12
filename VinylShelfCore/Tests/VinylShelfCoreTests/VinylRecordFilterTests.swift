import Testing
@testable import VinylShelfCore

@Suite("VinylRecordFilter")
struct VinylRecordFilterTests {
    @Test("Filters records by title")
    func filtersRecordsByTitle() {
        let target = VinylRecord(
            title: "Clube da Esquina",
            artist: "Milton Nascimento & Lô Borges"
        )
        let other = VinylRecord(title: "Luz", artist: "Djavan")

        let result = VinylRecordFilter.filter(
            [other, target],
            matching: "Clube"
        )

        #expect(result == [target])
    }

    @Test("Filters records by artist")
    func filtersRecordsByArtist() {
        let target = VinylRecord(
            title: "Construção",
            artist: "Chico Buarque"
        )
        let other = VinylRecord(title: "Luz", artist: "Djavan")

        let result = VinylRecordFilter.filter(
            [other, target],
            matching: "Chico"
        )

        #expect(result == [target])
    }

    @Test("Returns no records when the search has no matches")
    func returnsNoSearchResults() {
        let record = VinylRecord(title: "Luz", artist: "Djavan")

        let result = VinylRecordFilter.filter(
            [record],
            matching: "The Beatles"
        )

        #expect(result.isEmpty)
    }

    @Test("An empty search returns all records in their original order")
    func emptySearchReturnsAllRecords() {
        let firstRecord = VinylRecord(title: "Luz", artist: "Djavan")
        let secondRecord = VinylRecord(
            title: "Construção",
            artist: "Chico Buarque"
        )
        let records = [firstRecord, secondRecord]

        let result = VinylRecordFilter.filter(records, matching: "   ")

        #expect(result == records)
    }

    @Test("Search ignores letter case and diacritics")
    func searchIgnoresCaseAndDiacritics() {
        let target = VinylRecord(
            title: "Construção",
            artist: "Chico Buarque"
        )
        let other = VinylRecord(title: "Luz", artist: "Djavan")

        let result = VinylRecordFilter.filter(
            [other, target],
            matching: "CONSTRUCAO"
        )

        #expect(result == [target])
    }
}
