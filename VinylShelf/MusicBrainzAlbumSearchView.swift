import SwiftUI
import VinylShelfCore

@MainActor
struct MusicBrainzAlbumSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MusicBrainzAlbumSearchViewModel

    private let onSelect: @MainActor (
        MusicBrainzAlbumSearchResult
    ) -> Void

    init(
        albumSearcher: any MusicBrainzAlbumSearching,
        onSelect: @escaping @MainActor (
            MusicBrainzAlbumSearchResult
        ) -> Void
    ) {
        _viewModel = State(
            initialValue: MusicBrainzAlbumSearchViewModel(
                albumSearcher: albumSearcher
            )
        )
        self.onSelect = onSelect
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            content
                .navigationTitle("Buscar álbum")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: $viewModel.searchText,
                    prompt: "Nome do álbum"
                )
                .onSubmit(of: .search) {
                    viewModel.search()
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") {
                            viewModel.cancelSearch()
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Buscar") {
                            viewModel.search()
                        }
                        .disabled(!viewModel.canSearch)
                    }
                }
        }
        .onDisappear {
            viewModel.cancelSearch()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView {
                Label("Buscar no MusicBrainz", systemImage: "music.note")
            } description: {
                Text(
                    "Digite o nome de um álbum e toque em Buscar. Os resultados representam álbuns, não edições físicas específicas."
                )
            }

        case .loading:
            ProgressView("Buscando álbuns...")

        case let .results(results):
            List {
                Section {
                    ForEach(results, id: \.releaseGroupID) { result in
                        Button {
                            onSelect(result)
                            dismiss()
                        } label: {
                            MusicBrainzAlbumSearchResultRow(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text(
                        "Confirme os dados no formulário antes de salvar."
                    )
                }
            }
            .listStyle(.plain)

        case .empty:
            ContentUnavailableView(
                "Nenhum álbum encontrado",
                systemImage: "magnifyingglass",
                description: Text("Tente pesquisar outro nome de álbum.")
            )

        case let .failed(message):
            ContentUnavailableView {
                Label(
                    "Não foi possível pesquisar",
                    systemImage: "exclamationmark.triangle"
                )
            } description: {
                Text(message)
            } actions: {
                Button("Tentar novamente") {
                    viewModel.search()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

private struct MusicBrainzAlbumSearchResultRow: View {
    let result: MusicBrainzAlbumSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(result.title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(result.artist ?? "Artista não informado")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(
                result.releaseYear.map { String($0) }
                    ?? "Ano não informado"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
