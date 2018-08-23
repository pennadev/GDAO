//
//  TestManagedObjectExtension.swift
//  GDAOTests
//
//  Created by IonVoda on 23/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//

import XCTest
import Foundation
import CoreData
import CwlPreconditionTesting

@testable import GDAO

class TestManagedObjectExtension: XCTestCase {
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

    func testCoreData_Stack_NotNil() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertNotNil(coreDataStack)
    }

    func testCoreDataClass_User_DoNotContainModuleName() {
        let moduleName = NSStringFromClass(User.self).split(separator: ".").first
        XCTAssertNotNil(moduleName)

        let userClass: AnyClass? = NSClassFromString(moduleName! + "." + "User")
        XCTAssertNil(userClass)
        XCTAssertFalse(userClass == User.self)
    }

    func testCoreDataClass_Profile_DoNotContainModuleName() {
        let moduleName = NSStringFromClass(Profile.self).split(separator: ".").first
        XCTAssertNotNil(moduleName)

        let profileClass: AnyClass? = NSClassFromString(moduleName! + "." + "Profile")
        XCTAssertNil(profileClass)
        XCTAssertFalse(profileClass == Profile.self)
    }

    func testCoreData_Profile_HasRelationship() {
        let backgroudContext = coreDataStack.newBackgroundContext
        let profileTypeStr = String(describing: Profile.self)
        XCTAssertEqual(profileTypeStr, "Profile")

        let profileEntity = NSEntityDescription.entity(forEntityName: profileTypeStr, in: backgroudContext)
        XCTAssertNotNil(profileEntity)
        let profile = NSManagedObject.init(entity: profileEntity!, insertInto: backgroudContext)
        XCTAssertNotNil(profile)

        let userRelationDescription = profile.classType(relationshipName: "user")
        XCTAssertNotNil(userRelationDescription)
        XCTAssertTrue(userRelationDescription == User.self)
    }

    func testCoreData_Profile_HasRelationshipToOneWithUser() {
        let backgroudContext = coreDataStack.newBackgroundContext
        let profileTypeStr = String(describing: Profile.self)
        XCTAssertEqual(profileTypeStr, "Profile")

        let profileEntity = NSEntityDescription.entity(forEntityName: profileTypeStr, in: backgroudContext)
        XCTAssertNotNil(profileEntity)
        let profile = NSManagedObject.init(entity: profileEntity!, insertInto: backgroudContext)
        XCTAssertNotNil(profile)

        let isToMany = profile.isToMany(relationshipName: "user")
        XCTAssertFalse(isToMany)
    }

    func testCoreData_User_HasRelationship() {
        let backgroudContext = coreDataStack.newBackgroundContext
        let userTypeStr = String(describing: User.self)
        XCTAssertEqual(userTypeStr, "User")

        let userEntity = NSEntityDescription.entity(forEntityName: userTypeStr, in: backgroudContext)
        XCTAssertNotNil(userEntity)
        let user = NSManagedObject.init(entity: userEntity!, insertInto: backgroudContext)
        XCTAssertNotNil(user)

        let profileRelationDescription = user.classType(relationshipName: "profileSet")
        XCTAssertNotNil(profileRelationDescription)
        XCTAssertTrue(profileRelationDescription == Profile.self)
    }

    func testCoreData_Profile_HasNoRelationshipToManyWith_anyRelationshipName() {
        let backgroudContext = coreDataStack.newBackgroundContext
        let profileTypeStr = String(describing: Profile.self)
        XCTAssertEqual(profileTypeStr, "Profile")

        let profileEntity = NSEntityDescription.entity(forEntityName: profileTypeStr, in: backgroudContext)
        XCTAssertNotNil(profileEntity)
        let profile = NSManagedObject.init(entity: profileEntity!, insertInto: backgroudContext)
        XCTAssertNotNil(profile)

        let isToMany = profile.isToMany(relationshipName: "anyRelationshipName")
        XCTAssertFalse(isToMany)

        let exception: BadInstructionException? = catchBadInstruction {
            let _ = profile.classType(relationshipName: "anyRelationshipName")
        }
        XCTAssertNotEqual(exception, nil)
    }


    func testCoreData_User_HasNoRelationshipToManyWith_anyRelationshipName() {
        let backgroudContext = coreDataStack.newBackgroundContext
        let userTypeStr = String(describing: User.self)
        XCTAssertEqual(userTypeStr, "User")

        let userEntity = NSEntityDescription.entity(forEntityName: userTypeStr, in: backgroudContext)
        XCTAssertNotNil(userEntity)
        let user = NSManagedObject.init(entity: userEntity!, insertInto: backgroudContext)
        XCTAssertNotNil(user)

        let isToMany = user.isToMany(relationshipName: "anyRelationshipName")
        XCTAssertFalse(isToMany)

        let exception: BadInstructionException? = catchBadInstruction {
            let _ = user.classType(relationshipName: "anyRelationshipName")
        }
        XCTAssertNotEqual(exception, nil)
    }
}
