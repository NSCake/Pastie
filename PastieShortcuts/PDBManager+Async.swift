//
//  PDBManager+Async.swift
//  Pastie
//
//  Created by Tanner Bennett on 6/7/25.
//

extension PDBManager {
    static func open() async throws -> PDBManager {
        return try await withCheckedThrowingContinuation { promise in
            PDBManager.open { db, error in
                if let error {
                    promise.resume(throwing: error)
                }
                
                promise.resume(returning: db!)
            }
        }
    }
    
    func add(_ strings: [String]) async {
        await withCheckedContinuation { promise in
            self.add(strings) { success in
                promise.resume()
            }
        }
    }
}
