//
//  GDAOTests.swift
//  GDAOTests
//
//  Created by IonVoda on 16/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//

import XCTest
import CoreData
@testable import GDAO

class GDAOTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCoreDataRelationToMany() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let stack = CoreDataStack.init(modelName: "Model", persistentType: .inMemory)
        let backgroudContext = stack.newBackgroundContext
        XCTAssertNotNil(stack)

        let profileTypeStr = String(describing: Profile.self)
        XCTAssertEqual(profileTypeStr, "Profile")

        let profileEntity = NSEntityDescription.entity(forEntityName: profileTypeStr, in: backgroudContext)
        XCTAssertNotNil(profileEntity)
        let profile = NSManagedObject.init(entity: profileEntity!, insertInto: backgroudContext)
        XCTAssertNotNil(profile)

        let userRelationDescription = profile.entity.relationshipsByName["user"]
        XCTAssertNotNil(userRelationDescription)
        XCTAssertEqual(userRelationDescription!.isToMany, false)


        let userTypeStr = String(describing: User.self)
        XCTAssertEqual(userTypeStr, "User")

        let userEntity = NSEntityDescription.entity(forEntityName: userTypeStr, in: backgroudContext)
        XCTAssertNotNil(userEntity)
        let user = NSManagedObject.init(entity: userEntity!, insertInto: backgroudContext)
        XCTAssertNotNil(user)

        let profileRelationDescription = user.entity.relationshipsByName["profileSet"]
        XCTAssertNotNil(profileRelationDescription)
        XCTAssertEqual(profileRelationDescription!.isToMany, true)

    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
