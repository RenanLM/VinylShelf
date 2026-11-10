import Foundation
import SwiftData
import VinylShelfCore

@Model
final class VinylRecordEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var artist: String
    var releaseYear: Int?
    var genre: String?

    init(record: VinylRecord) {
        id = record.id
        title = record.title
        artist = record.artist
        releaseYear = record.releaseYear
        genre = record.genre
    }

    var domainModel: VinylRecord {
        VinylRecord(
            id: id,
            title: title,
            artist: artist,
            releaseYear: releaseYear,
            genre: genre
        )
    }

    func update(from record: VinylRecord) {
        precondition(id == record.id, "A record ID cannot be changed")
        title = record.title
        artist = record.artist
        releaseYear = record.releaseYear
        genre = record.genre
    }
}
