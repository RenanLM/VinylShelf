import Foundation

public enum VinylRecordFilter {
    public static func filter(
        _ records: [VinylRecord],
        matching searchText: String
    ) -> [VinylRecord] {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !query.isEmpty else { return records }

        return records.filter { record in
            contains(record.title, query: query)
                || contains(record.artist, query: query)
        }
    }

    private static func contains(_ value: String, query: String) -> Bool {
        value.range(
            of: query,
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        ) != nil
    }
}
