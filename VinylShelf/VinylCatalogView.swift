import SwiftUI
import VinylShelfCore

@MainActor
struct VinylCatalogView: View {
    @State private var isPresentingAddForm = false
    @State private var recordBeingEdited: VinylRecord?
    @State private var recordPendingDeletion: VinylRecord?
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingDeletionError = false

    @Bindable var viewModel: VinylCatalogViewModel
    let albumSearcher: any MusicBrainzAlbumSearching

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("VinylShelf")
                .searchable(
                    text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Buscar por título ou artista"
                )
                .navigationDestination(for: VinylRecord.ID.self) { recordID in
                    detailDestination(for: recordID)
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isPresentingAddForm = true
                        } label: {
                            Label("Adicionar disco", systemImage: "plus")
                        }
                        .disabled(
                            viewModel.isDeleting || viewModel.isUpdating
                        )
                    }
                }
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $isPresentingAddForm) {
            VinylRecordFormView(albumSearcher: albumSearcher) { record in
                try await viewModel.add(record)
            }
        }
        .sheet(item: $recordBeingEdited) { record in
            VinylRecordFormView(initialRecord: record) { updatedRecord in
                try await viewModel.update(updatedRecord)
            }
        }
        .confirmationDialog(
            "Excluir disco?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible,
            presenting: recordPendingDeletion
        ) { record in
            Button("Excluir", role: .destructive) {
                recordPendingDeletion = nil

                Task {
                    do {
                        try await viewModel.delete(record)
                    } catch {
                        isShowingDeletionError = true
                    }
                }
            }

            Button("Cancelar", role: .cancel) {
                recordPendingDeletion = nil
            }
        } message: { record in
            Text(
                "\(record.title), de \(record.artist), será removido da sua coleção."
            )
        }
        .alert(
            "Não foi possível excluir",
            isPresented: $isShowingDeletionError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("O disco foi mantido na sua coleção. Tente novamente.")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Carregando coleção...")

        case .loaded:
            if viewModel.hasNoSearchResults {
                ContentUnavailableView {
                    Label(
                        "Nenhum disco encontrado",
                        systemImage: "magnifyingglass"
                    )
                } description: {
                    Text("Tente buscar por outro título ou artista.")
                } actions: {
                    Button("Limpar busca") {
                        viewModel.searchText = ""
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                List(viewModel.filteredRecords) { record in
                    NavigationLink(value: record.id) {
                        VinylRecordRow(record: record)
                    }
                    .swipeActions(
                        edge: .trailing,
                        allowsFullSwipe: false
                    ) {
                        Button(role: .destructive) {
                            recordPendingDeletion = record
                            isShowingDeleteConfirmation = true
                        } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                        .disabled(
                            viewModel.isDeleting || viewModel.isUpdating
                        )

                        Button {
                            recordBeingEdited = record
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        .tint(.blue)
                        .disabled(
                            viewModel.isDeleting || viewModel.isUpdating
                        )
                    }
                }
                .listStyle(.plain)
                .onAppear {
                    ScreenshotDemoConfiguration.signalCatalogReady()
                }
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

    @ViewBuilder
    private func detailDestination(
        for recordID: VinylRecord.ID
    ) -> some View {
        if let record = viewModel.record(id: recordID) {
            VinylRecordDetailView(record: record)
        } else {
            ContentUnavailableView(
                "Disco indisponível",
                systemImage: "opticaldisc",
                description: Text(
                    "Este disco não está mais disponível na coleção."
                )
            )
        }
    }
}

private struct VinylRecordRow: View {
    let record: VinylRecord

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.15))

                Image(systemName: "opticaldisc.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .frame(width: 56, height: 56)

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
