import SwiftData
import SwiftUI
import VinylShelfCore

@main
@MainActor
struct VinylShelfApp: App {
    private let modelContainer: ModelContainer
    private let albumSearcher: any MusicBrainzAlbumSearching
    @State private var viewModel: VinylCatalogViewModel

    init() {
        albumSearcher = MusicBrainzClient()

        do {
            let isScreenshotDemoEnabled = ScreenshotDemoConfiguration.isEnabled
            let modelContainer: ModelContainer
            let repository: any VinylRecordRepository

            if isScreenshotDemoEnabled {
                let configuration = ModelConfiguration(
                    isStoredInMemoryOnly: true
                )
                modelContainer = try ModelContainer(
                    for: VinylRecordEntity.self,
                    configurations: configuration
                )
                repository = try InMemoryVinylRecordRepository(
                    records: ScreenshotDemoConfiguration.records
                )
            } else {
                modelContainer = try ModelContainer(
                    for: VinylRecordEntity.self
                )
                repository = SwiftDataVinylRecordRepository(
                    modelContainer: modelContainer
                )
            }

            self.modelContainer = modelContainer
            _viewModel = State(
                initialValue: VinylCatalogViewModel(repository: repository)
            )
        } catch {
            fatalError("Unable to create the model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            VinylCatalogView(
                viewModel: viewModel,
                albumSearcher: albumSearcher
            )
                .modelContainer(modelContainer)
        }
    }
}
