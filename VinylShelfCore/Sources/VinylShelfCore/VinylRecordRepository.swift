import Foundation

public protocol VinylRecordRepository: Sendable {
    func fetchAll() async throws -> [VinylRecord]
    func fetch(id: UUID) async throws -> VinylRecord?
    func add(_ record: VinylRecord) async throws
    func update(_ record: VinylRecord) async throws
    func remove(id: UUID) async throws
}
