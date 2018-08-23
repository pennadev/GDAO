//
//  TestParserJSONToCoreData.swift
//  GDAOTests
//
//  Created by IonVoda on 23/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//

import XCTest
import CoreData
import CwlPreconditionTesting

@testable import GDAO

class TestParserJSONToCoreData: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func test_ParseUserWithProfiles() {
        // This is an example of a performance test case.
        let bundle = Bundle(for: type(of: self))
        XCTAssertNotNil(bundle)
        
        let path = bundle.path(forResource: "UserWithProfile", ofType: "json")
        XCTAssertNotNil(path)

        let urlPath = URL(fileURLWithPath: path!)
        XCTAssertNotNil(urlPath)

        let data = try? Data(contentsOf: urlPath, options: .mappedIfSafe)
        XCTAssertNotNil(data)

        let jsonResult = try? JSONSerialization.jsonObject(with: data!, options: .mutableLeaves)
        XCTAssertNotNil(jsonResult)

        let jsonResultDic = jsonResult as? Dictionary<String, NSObject>
        XCTAssertNotNil(jsonResultDic)

        let coreDataStack = CoreDataStack.init(modelName: "GDAO", persistentType: .inMemory)
        XCTAssertNotNil(coreDataStack)

        let privateContext = coreDataStack.newBackgroundContext
        XCTAssertNotNil(privateContext)


        class DelegateParser: ParserDelegate {
            func uniqueIds(for modelType: NSManagedObject.Type) -> [String] {
                if modelType == Profile.self {
                    return ["id"]
                } else if modelType == User.self {
                    return ["id"]
                }
                return []
            }
        }

        let dao = DAOCoreData(managedObjectContext: privateContext)
        XCTAssertNotNil(dao)
        let delegate = DelegateParser()
        XCTAssertNotNil(delegate)
        let parser = ParserJSONToCoreData.init(dao, delegate: delegate)
        XCTAssertNotNil(parser)

        let userParsed = parser.parse([jsonResultDic!], rootType: User.self)
        XCTAssertNotNil(userParsed)
        XCTAssertFalse(userParsed!.isEmpty)
    }
}
