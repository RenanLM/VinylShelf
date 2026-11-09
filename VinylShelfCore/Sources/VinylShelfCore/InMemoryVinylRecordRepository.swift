import Foundation

public enum InMemoryVinylRecordRepositoryError: Error, Equatable, Sendable {
    case duplicateID(UUID)
    case recordNotFound(UUID)
}

public actor InMemoryVinylRecordRepository: VinylRecordRepository {
    private var recordsByID: [UUID: VinylRecord] = [:]

    public init() {}

    public func fetchAll() async throws -> [VinylRecord] {
        Array(recordsByID.values)
    }

    public func fetch(id: UUID) async throws -> VinylRecord? {
        recordsByID[id]
    }

    public func add(_ record: VinylRecord) async throws {
        guard recordsByID[record.id] == nil else {
            throw InMemoryVinylRecordRepositoryError.duplicateID(record.id)
        }

        recordsByID[record.id] = record
    }

    public func update(_ record: VinylRecord) async throws {
        guard recordsByID[record.id] != nil else {
            throw InMemoryVinylRecordRepositoryError.recordNotFound(record.id)
        }

        recordsByID[record.id] = record
    }

    public func remove(id: UUID) async throws {
        guard recordsByID.removeValue(forKey: id) != nil else {
            throw InMemoryVinylRecordRepositoryError.recordNotFound(id)
        }
    }
}
