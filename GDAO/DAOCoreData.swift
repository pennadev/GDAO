//
//  GDAOBase.swift
//  GDAOBase
//
//  Created by IonVoda on 12/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//

import Foundation
import CoreData

class DAOCoreData {
    private let managedObjectContext: NSManagedObjectContext
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    func fetch<C: NSManagedObject>(entityType: C.Type, predicate: NSPredicate? = nil, sorts: [NSSortDescriptor]? = nil) -> C? {
        let objects  = fetchAll(entityType: entityType, predicate: predicate, sorts: sorts, fetchLimit: 1)
        return objects.first
    }

    func fetchAll<C: NSManagedObject>(entityType: C.Type, predicate: NSPredicate? = nil, sorts: [NSSortDescriptor]? = nil, batchSize: Int? = nil, fetchLimit: Int? = nil) -> [C] {
        let fetchRequest = C.fetchRequest()

        fetchRequest.sortDescriptors = sorts ?? []
        if let batchSize = batchSize {
            fetchRequest.fetchBatchSize = batchSize
        }

        if let fetchLimit = fetchLimit {
            fetchRequest.fetchLimit = fetchLimit
        }

        fetchRequest.predicate = predicate
        let objects: [C]?
        do {
            objects = try managedObjectContext.fetch(fetchRequest) as? [C]
        } catch {
            fatalError(error.localizedDescription)
        }

        return objects ?? []
    }

    // uniqueIdentifiers: (key, val) pair to identify uniquelly an object
    func fetch<C: NSManagedObject>(entityType: C.Type, uniqueIdentifiers: [String: NSObject]) -> C? {
        let allObjects = fetchAll(entityType: entityType, uniqueIdentifiers: uniqueIdentifiers, fetchLimit: 1)
        return allObjects?.first
    }

    func fetchAll<C: NSManagedObject>(entityType: C.Type, uniqueIdentifiers: [String: NSObject], fetchLimit: Int? = nil) -> [C]? {
        guard uniqueIdentifiers.isEmpty == false else {
            fatalError("Please provide Unique Identifers for fetch")
        }

        let sortDescr = [NSSortDescriptor(key: uniqueIdentifiers.keys.first, ascending: true)]
        let predicateArray: [NSPredicate] = uniqueIdentifiers.compactMap() { (key, value) in
            let pred = NSPredicate(format: "%K == %@", key, value)
            return pred
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicateArray)
        let allObjects = fetchAll(entityType: entityType, predicate: predicate, sorts: sortDescr, fetchLimit: fetchLimit)
        return allObjects
    }

    // CREATE
    func insert<C: NSManagedObject>(entityType: C.Type) -> C {
        let typeStr = String(describing: entityType)
        let managedObject = NSEntityDescription.insertNewObject(forEntityName: typeStr, into: managedObjectContext)

        guard let managedObjectC = managedObject as? C else {
            fatalError("object: \(managedObject) cannot be casted to classType: \(typeStr)")
        }

        return managedObjectC
    }

    //DELETE
    func delete(_ managedObject: NSManagedObject) {
        managedObjectContext.delete(managedObject)
    }

    func deleteAll<C: NSManagedObject>(entityType: C.Type, predicate: NSPredicate? = nil, deleteUsingPersistentCoordinator: Bool = false) -> Void {
        let typeStr = String(describing: entityType)
        let entity = NSEntityDescription.entity(forEntityName: typeStr, in: managedObjectContext)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = entity
        fetchRequest.includesPropertyValues = false

        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs

        do {
            let result: NSBatchDeleteResult?
            if deleteUsingPersistentCoordinator {
                result = try managedObjectContext.persistentStoreCoordinator?.execute(deleteRequest, with: managedObjectContext) as? NSBatchDeleteResult
            } else {
                result = try managedObjectContext.execute(deleteRequest) as? NSBatchDeleteResult
            }
            if let objectIDArray = result?.result as? [NSManagedObjectID], objectIDArray.isEmpty == false {
                let changes: [AnyHashable : Any] = [NSDeletedObjectsKey : objectIDArray]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [managedObjectContext])
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func perform(_ completion: @escaping ()->Void) {
        managedObjectContext.perform {
            completion()
        }
    }
}
