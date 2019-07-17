//
//  ProfileCreatorExportTests.swift
//  ProfileCreatorExportTests
//
//  Created by Erik Berglund on 2018-06-19.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import XCTest

class ProfileCreatorExportTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testExports() {

        // FIXME: Hardcoded
        let exportConfigurations = URL(fileURLWithPath: "/Users/erikberglund/Documents/GitHub/ProfileCreatorDev/ProfileCreator/ProfileCreatorExportTests/ExportConfigurations")
        XCTAssert(FileManager.default.fileExists(atPath: exportConfigurations.path), "Path to export configurations directory not found!")

        let exportProfiles = URL(fileURLWithPath: "/Users/erikberglund/Documents/GitHub/ProfileCreatorDev/ProfileCreator/ProfileCreatorExportTests/ExportProfiles")
        XCTAssert(FileManager.default.fileExists(atPath: exportProfiles.path), "Path to export profiles directory not found!")

        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
