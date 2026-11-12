import Foundation
import VinylShelfCore

enum ScreenshotDemoConfiguration {
    static let readinessFileName = "vinylshelf-screenshot-ready"

#if DEBUG
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("--screenshot-demo")
    }

    static let records = [
        VinylRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "Clube da Esquina",
            artist: "Milton Nascimento & Lô Borges",
            releaseYear: 1972,
            genre: "MPB"
        ),
        VinylRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            title: "Kind of Blue",
            artist: "Miles Davis",
            releaseYear: 1959,
            genre: "Jazz"
        ),
        VinylRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            title: "Rumours",
            artist: "Fleetwood Mac",
            releaseYear: 1977,
            genre: "Rock"
        ),
        VinylRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            title: "Transa",
            artist: "Caetano Veloso",
            releaseYear: 1972,
            genre: "MPB"
        )
    ]

    @MainActor
    static func signalCatalogReady() {
        guard isEnabled else { return }

        guard let cachesDirectory = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else { return }

        let readinessFile = cachesDirectory.appendingPathComponent(
            readinessFileName
        )

        do {
            try Data("ready".utf8).write(
                to: readinessFile,
                options: .atomic
            )
        } catch {
            print("Unable to signal screenshot readiness: \(error)")
        }
    }
#else
    static let isEnabled = false
    static let records: [VinylRecord] = []

    @MainActor
    static func signalCatalogReady() {}
#endif
}
