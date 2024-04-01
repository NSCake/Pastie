//
//  PastieTests.swift
//  PastieTests
//
//  Created by Tanner Bennett on 3/10/24.
//

import XCTest
@testable import Pastie

final class PastieTests: XCTestCase {
    
    let manager = PDBManager.shared

    override func setUpWithError() throws {
        
    }
    
    func testInsertingStringPutsIDInLastResult() throws {
        manager.add(.init(string: "http://google.com/")!, title: "Google")
        
        let insert = try XCTUnwrap(manager.lastInsert)
        let rows = try XCTUnwrap(insert.rows)
        XCTAssertFalse(rows.isEmpty)
//        XCTAssert(result.keyedRows)
    }
}
