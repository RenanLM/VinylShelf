import SwiftUI
import VinylShelfCore

@MainActor
struct VinylRecordFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var input: VinylRecordFormInput
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let recordID: UUID?
    private let navigationTitle: String
    private let saveFailureMessage: String
    let onSave: @MainActor (VinylRecord) async throws -> Void

    init(
        initialRecord: VinylRecord? = nil,
        onSave: @escaping @MainActor (VinylRecord) async throws -> Void
    ) {
        recordID = initialRecord?.id
        navigationTitle = initialRecord == nil ? "Novo disco" : "Editar disco"
        saveFailureMessage = initialRecord == nil
            ? "Não foi possível salvar o disco. Tente novamente."
            : "Não foi possível atualizar o disco. Tente novamente."
        self.onSave = onSave

        let initialInput = initialRecord.map {
            VinylRecordFormInput(record: $0)
        } ?? VinylRecordFormInput()
        _input = State(initialValue: initialInput)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Disco") {
                    TextField("Título", text: $input.title)
                        .textInputAutocapitalization(.words)

                    TextField("Artista", text: $input.artist)
                        .textInputAutocapitalization(.words)
                }

                Section("Detalhes opcionais") {
                    TextField(
                        "Ano de lançamento",
                        text: $input.releaseYear
                    )
                    .keyboardType(.numberPad)

                    TextField("Gênero", text: $input.genre)
                        .textInputAutocapitalization(.words)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        Task {
                            await save()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private func save() async {
        guard !isSaving else { return }
        errorMessage = nil

        do {
            let record = try input.makeRecord(id: recordID ?? UUID())
            isSaving = true
            defer { isSaving = false }

            try await onSave(record)
            dismiss()
        } catch let validationError as VinylRecordFormValidationError {
            errorMessage = validationError.message
        } catch {
            errorMessage = saveFailureMessage
        }
    }
}
