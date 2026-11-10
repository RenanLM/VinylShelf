import SwiftUI
import VinylShelfCore

@MainActor
struct AddVinylRecordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var input = VinylRecordFormInput()
    @State private var isSaving = false
    @State private var errorMessage: String?

    let onSave: @MainActor (VinylRecord) async throws -> Void

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
            .navigationTitle("Novo disco")
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
            let record = try input.makeRecord()
            isSaving = true
            defer { isSaving = false }

            try await onSave(record)
            dismiss()
        } catch let validationError as VinylRecordFormValidationError {
            errorMessage = validationError.message
        } catch {
            errorMessage = "Não foi possível salvar o disco. Tente novamente."
        }
    }
}
