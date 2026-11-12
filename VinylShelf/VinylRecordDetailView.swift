import SwiftUI
import VinylShelfCore

@MainActor
struct VinylRecordDetailView: View {
    let record: VinylRecord

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                coverPlaceholder

                VStack(alignment: .leading, spacing: 8) {
                    Text(record.title)
                        .font(.largeTitle.bold())

                    Text(record.artist)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                GroupBox("Informações") {
                    VStack(spacing: 12) {
                        LabeledContent(
                            "Ano de lançamento",
                            value: releaseYearText
                        )

                        Divider()

                        LabeledContent("Gênero", value: genreText)
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(maxWidth: 640)
            .padding()
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Detalhes")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var coverPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondary.opacity(0.15))

            Image(systemName: "opticaldisc.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .padding(64)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 320)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Capa não disponível")
    }

    private var releaseYearText: String {
        record.releaseYear.map { String($0) } ?? "Não informado"
    }

    private var genreText: String {
        record.genre ?? "Não informado"
    }
}
