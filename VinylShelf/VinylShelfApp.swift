import SwiftUI

@main
@MainActor
struct VinylShelfApp: App {
    @State private var viewModel: VinylCatalogViewModel

    init() {
        let repository = DemoVinylRecords.makeRepository()
        _viewModel = State(
            initialValue: VinylCatalogViewModel(repository: repository)
        )
    }

    var body: some Scene {
        WindowGroup {
            VinylCatalogView(viewModel: viewModel)
        }
    }
}
