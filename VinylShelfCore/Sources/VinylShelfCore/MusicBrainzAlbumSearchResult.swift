public struct MusicBrainzAlbumSearchResult: Equatable, Sendable {
    public let releaseGroupID: String
    public let title: String
    public let artist: String?
    public let releaseYear: Int?

    public init(
        releaseGroupID: String,
        title: String,
        artist: String?,
        releaseYear: Int?
    ) {
        self.releaseGroupID = releaseGroupID
        self.title = title
        self.artist = artist
        self.releaseYear = releaseYear
    }
}
