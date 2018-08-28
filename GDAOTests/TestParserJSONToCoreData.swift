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
    private var coreDataStack: CoreDataStack!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack.init(modelName: "GDAO", persistentType: .inMemory)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        coreDataStack = nil
        super.tearDown()
    }

    private func loadJsonResult() -> Dictionary<String, NSObject> {
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

        return jsonResultDic!
    }

    func test_ParseSyncUserWithProfiles_parsedValueIsArrayWithOneObjectUserType() {
        // This is an example of a performance test case.
        XCTAssertNotNil(coreDataStack)

        let privateContext = coreDataStack.newBackgroundContext
        XCTAssertNotNil(privateContext)

        class DelegateParser: ParserDelegate {
            func findPrimaryKeys(for modelType: NSManagedObject.Type) throws -> Set<String> {
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

        let jsonResult = loadJsonResult()
        do {
            let users: [Any]? = try parser.parse([jsonResult], rootType: User.self)
            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let typeFirst = type(of: users!.first!)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)
        } catch {
            XCTFail()
        }
    }

    func test_ParseAsyncUserWithProfiles_parsedValueIsArrayWithOneObjectUserType() {
        // This is an example of a performance test case.
        XCTAssertNotNil(coreDataStack)

        let privateContext = coreDataStack.newBackgroundContext
        XCTAssertNotNil(privateContext)

        class DelegateParser: ParserDelegate {
            func findPrimaryKeys(for modelType: NSManagedObject.Type) throws -> Set<String> {
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

        let expect = expectation(description: "ExpectParserAsyncOperation")
        let jsonResult = loadJsonResult()

        var users: [Any]?
        parser.parseAsync([jsonResult], rootType: User.self) { value in
            users = value
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3)
        
        XCTAssertNotNil(users)
        XCTAssertFalse(users!.isEmpty)
        XCTAssertTrue(users!.count == 1)
        let typeFirst = type(of: users!.first!)
        XCTAssertNotNil(typeFirst)
        XCTAssertTrue(typeFirst == User.self)

        let user = users!.first as! User
        XCTAssertTrue(user.profileSet?.count == 3)
    }
}
