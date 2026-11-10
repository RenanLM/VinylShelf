import SwiftUI
import VinylShelfCore

@MainActor
struct VinylCatalogView: View {
    let viewModel: VinylCatalogViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("VinylShelf")
        }
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Carregando coleção...")

        case let .loaded(records):
            List(records) { record in
                VinylRecordRow(record: record)
            }

        case .empty:
            ContentUnavailableView(
                "Coleção vazia",
                systemImage: "opticaldisc",
                description: Text("Seus discos aparecerão aqui.")
            )

        case let .failed(message):
            ContentUnavailableView(
                "Não foi possível carregar",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }
}

private struct VinylRecordRow: View {
    let record: VinylRecord

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.15))

                Image(systemName: "opticaldisc.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.headline)

                Text(record.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(record.releaseYear.map { String($0) } ?? "Ano desconhecido")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
