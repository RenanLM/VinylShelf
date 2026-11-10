import SwiftData
import SwiftUI

@main
@MainActor
struct VinylShelfApp: App {
    private let modelContainer: ModelContainer
    @State private var viewModel: VinylCatalogViewModel

    init() {
        do {
            let modelContainer = try ModelContainer(
                for: VinylRecordEntity.self
            )
            let repository = SwiftDataVinylRecordRepository(
                modelContainer: modelContainer
            )

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
            VinylCatalogView(viewModel: viewModel)
                .modelContainer(modelContainer)
        }
    }
}
