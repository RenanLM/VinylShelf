import Foundation
import SwiftData
import VinylShelfCore

enum SwiftDataVinylRecordRepositoryError: Error, Equatable, Sendable {
    case duplicateID(UUID)
    case recordNotFound(UUID)
    case persistenceFailure
}

@ModelActor
actor SwiftDataVinylRecordRepository: VinylRecordRepository {
    func fetchAll() async throws -> [VinylRecord] {
        try execute {
            try modelContext
                .fetch(FetchDescriptor<VinylRecordEntity>())
                .map(\.domainModel)
        }
    }

    func fetch(id: UUID) async throws -> VinylRecord? {
        try execute {
            try findEntity(id: id)?.domainModel
        }
    }

    func add(_ record: VinylRecord) async throws {
        try execute {
            guard try findEntity(id: record.id) == nil else {
                throw SwiftDataVinylRecordRepositoryError.duplicateID(record.id)
            }

            modelContext.insert(VinylRecordEntity(record: record))
            try modelContext.save()
        }
    }

    func update(_ record: VinylRecord) async throws {
        try execute {
            guard let entity = try findEntity(id: record.id) else {
                throw SwiftDataVinylRecordRepositoryError.recordNotFound(
                    record.id
                )
            }

            entity.update(from: record)
            try modelContext.save()
        }
    }

    func remove(id: UUID) async throws {
        try execute {
            guard let entity = try findEntity(id: id) else {
                throw SwiftDataVinylRecordRepositoryError.recordNotFound(id)
            }

            modelContext.delete(entity)
            try modelContext.save()
        }
    }

    private func findEntity(id: UUID) throws -> VinylRecordEntity? {
        let recordID = id
        var descriptor = FetchDescriptor<VinylRecordEntity>(
            predicate: #Predicate { entity in
                entity.id == recordID
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func execute<Result>(
        _ operation: () throws -> Result
    ) throws -> Result {
        do {
            return try operation()
        } catch let repositoryError as SwiftDataVinylRecordRepositoryError {
            throw repositoryError
        } catch {
            modelContext.rollback()
            throw SwiftDataVinylRecordRepositoryError.persistenceFailure
        }
    }
}
