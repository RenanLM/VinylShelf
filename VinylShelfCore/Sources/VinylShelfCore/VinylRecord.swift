import Foundation

public struct VinylRecord: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let artist: String
    public let releaseYear: Int?
    public let genre: String?

    public init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        releaseYear: Int? = nil,
        genre: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.releaseYear = releaseYear
        self.genre = genre
    }
}
