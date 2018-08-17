//
//  CoreDataStack.swift
//  TestAriva
//
//  Created by IonVoda on 11/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//

import Foundation
import CoreData

protocol CoreDataStackDependcy: class {
    var coreDataStack: CoreDataStack! { get set }
}

enum PersistentStoreType {
    case inMemory
    case inBinary
    case inSQLite
}

extension PersistentStoreType {
    var type: String {
        switch self {
        case .inMemory:
            return NSInMemoryStoreType
        case .inBinary:
            return NSBinaryStoreType
        case .inSQLite:
            return NSSQLiteStoreType
        }
    }
}

// MARK: - Core Data stack
class CoreDataStack {
    private let modelName: String
    private let persistentType: PersistentStoreType

    init(modelName: String, persistentType: PersistentStoreType) {
        self.modelName = modelName
        self.persistentType = persistentType
    }

    var viewContext: NSManagedObjectContext {
        let context = persistentContainer.viewContext
        return context
    }

    var newBackgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        return context
    }

    private lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        class PersistentContainer: NSPersistentContainer {}
        let container = PersistentContainer(name: modelName)

        let description = NSPersistentStoreDescription()
        description.type = persistentType.type
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    // MARK: - Core Data Saving support

    class func save(context: NSManagedObjectContext) {        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
