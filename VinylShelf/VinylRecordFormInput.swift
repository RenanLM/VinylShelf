import Foundation
import VinylShelfCore

enum VinylRecordFormValidationError: Error, Equatable, Sendable {
    case titleRequired
    case artistRequired
    case invalidReleaseYear

    var message: String {
        switch self {
        case .titleRequired:
            return "Informe o título do disco."
        case .artistRequired:
            return "Informe o artista do disco."
        case .invalidReleaseYear:
            return "Informe um ano entre 1900 e o ano atual."
        }
    }
}

struct VinylRecordFormInput {
    static let minimumReleaseYear = 1900

    var title = ""
    var artist = ""
    var releaseYear = ""
    var genre = ""

    func makeRecord(
        currentYear: Int = Calendar.current.component(.year, from: Date())
    ) throws -> VinylRecord {
        let normalizedTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !normalizedTitle.isEmpty else {
            throw VinylRecordFormValidationError.titleRequired
        }

        let normalizedArtist = artist.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !normalizedArtist.isEmpty else {
            throw VinylRecordFormValidationError.artistRequired
        }

        let normalizedReleaseYear = releaseYear.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let parsedReleaseYear: Int?

        if normalizedReleaseYear.isEmpty {
            parsedReleaseYear = nil
        } else if let year = Int(normalizedReleaseYear),
                  Self.minimumReleaseYear...currentYear ~= year {
            parsedReleaseYear = year
        } else {
            throw VinylRecordFormValidationError.invalidReleaseYear
        }

        let normalizedGenre = genre.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return VinylRecord(
            title: normalizedTitle,
            artist: normalizedArtist,
            releaseYear: parsedReleaseYear,
            genre: normalizedGenre.isEmpty ? nil : normalizedGenre
        )
    }
}
