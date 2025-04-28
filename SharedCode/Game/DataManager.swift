//
//  DataManager.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/14/25.
//

import SwiftUI
import CloudKit


class DataManager: ObservableObject {
   
    private let container = CKContainer(identifier: "iCloud.com.lucaslongo.Speed2048")
    private let recordID = CKRecord.ID(recordName: "currentGame")

    private var privateDatabase: CKDatabase {
        return container.privateCloudDatabase
    }
    
    private var gameStateFileURL: URL {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("Speed2048.json")
    }

    func loadGameStateLocally() async throws -> GameState {
        let data = try Data(contentsOf: gameStateFileURL)
        guard let gameState = try? JSONDecoder().decode(GameState.self, from: data) else {
            throw GameDataManagementError.decodingError
        }
        return gameState
    }

    func saveGameStateLocally(gameState: GameState) async throws {
        let data = try JSONEncoder().encode(gameState)
        try data.write(to: gameStateFileURL, options: .atomic)
    }

    func fetchGameStateFromCloud() async throws -> GameState {
        let record = try await privateDatabase.record(for: recordID)
        guard let asset = record["stateAsset"] as? CKAsset,
              let fileURL = asset.fileURL else {
            throw GameDataManagementError.noGameFound
        }
        let data = try Data(contentsOf: fileURL)
        guard let cloudState = try? JSONDecoder().decode(GameState.self, from: data) else {
            throw GameDataManagementError.decodingError
        }
        return cloudState
    }

    func saveGameStateToCloud(gameState: GameState) async throws {
        let data = try JSONEncoder().encode(gameState)
        let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        try data.write(to: tempFileURL, options: .atomic)

        let record: CKRecord
        do {
            record = try await privateDatabase.record(for: recordID)
        } catch {
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                record = CKRecord(recordType: "GameState", recordID: recordID)
            } else {
                try? FileManager.default.removeItem(at: tempFileURL)
                throw GameDataManagementError.cloudKitError
            }
        }

        record["stateAsset"] = CKAsset(fileURL: tempFileURL)
        do {
            try await privateDatabase.save(record)
        } catch {
            try? FileManager.default.removeItem(at: tempFileURL)
            if let ckError = error as? CKError, ckError.code == .serverRecordChanged {
                await resolveCloudConflict(gameState: gameState, tempFileURL: tempFileURL)
            } else {
                throw GameDataManagementError.cloudKitError
            }
        }
        try? FileManager.default.removeItem(at: tempFileURL)
    }

    private func resolveCloudConflict(gameState: GameState, tempFileURL: URL) async {
        do {
            let latestRecord = try await privateDatabase.record(for: recordID)
            let data = try JSONEncoder().encode(gameState)
            let newTempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
            try data.write(to: newTempFileURL, options: .atomic)

            latestRecord["stateAsset"] = CKAsset(fileURL: newTempFileURL)
            try await privateDatabase.save(latestRecord)
            try? FileManager.default.removeItem(at: newTempFileURL)
        } catch {
            print("Conflict resolution failed: \(error.localizedDescription)")
        }
    }
}
