import VinylShelfCore

enum DemoVinylRecords {
    static let records = [
        VinylRecord(
            title: "The Dark Side of the Moon",
            artist: "Pink Floyd",
            releaseYear: 1973,
            genre: "Progressive rock"
        ),
        VinylRecord(
            title: "Clube da Esquina",
            artist: "Milton Nascimento & Lô Borges",
            releaseYear: 1972,
            genre: "MPB"
        ),
        VinylRecord(
            title: "Construção",
            artist: "Chico Buarque",
            releaseYear: 1971,
            genre: "MPB"
        ),
        VinylRecord(
            title: "A Tábua de Esmeralda",
            artist: "Jorge Ben Jor",
            releaseYear: 1974,
            genre: "Samba rock"
        ),
    ]

    static func makeRepository() -> InMemoryVinylRecordRepository {
        do {
            return try InMemoryVinylRecordRepository(records: records)
        } catch {
            preconditionFailure("Invalid demo records: \(error)")
        }
    }
}
