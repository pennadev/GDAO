//
//  GDAOBase.swift
//  TestAriva
//
//  Created by IonVoda on 12/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//

import Foundation
import CoreData

class GDAOBase {
    private let managedObjectContext: NSManagedObjectContext
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    func getOneByPredicate<C: NSManagedObject>(_ entityName: C.Type, sorts: [NSSortDescriptor]? = nil, predicate: NSPredicate? = nil) -> C? {
        let objects  = getAllByPredicate(entityName, sorts:sorts, predicate: predicate, fetchLimit: 1)
        return objects.first
    }

    func getAllByPredicate<C: NSManagedObject>(_ entityName: C.Type, sorts:[NSSortDescriptor]? = nil, predicate:NSPredicate? = nil, batchSize:Int? = nil, fetchLimit: Int? = nil) -> [C] {

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
    func getOneByIds<C: NSManagedObject>(_ entityName: C.Type, uuids: [String: NSObject]) -> C? {
        let allObjects = getAllByIds(entityName, uuids: uuids, fetchLimit: 1)
        return allObjects?.first
    }

    func getAllByIds<C: NSManagedObject>(_ entityName: C.Type, uuids: [String: NSObject], fetchLimit: Int? = nil) -> [C]? {
        guard uuids.isEmpty == false else {
            fatalError("Please provide Unique Identifers for fetch")
        }

        let sortDescr = [NSSortDescriptor(key: uuids.keys.first, ascending: true)]
        let predicateArray: [NSPredicate] = uuids.compactMap() { (key, value) in
            let pred = NSPredicate(format: "%K == %@", key, value)
            return pred
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicateArray)
        let allObjects = getAllByPredicate(entityName, sorts:sortDescr, predicate:predicate, fetchLimit: fetchLimit)
        return allObjects
    }

    // CREATE
    func insertDataForEntityName<C: NSManagedObject>(_ entityName: C.Type) -> C {
        let type = NSStringFromClass(entityName)
        let typeStr = type.components(separatedBy: ".").last!
        let managedObject = NSEntityDescription.insertNewObject(forEntityName: typeStr, into: managedObjectContext)
        return managedObject as! C
    }

    //CREATE or UPDATE
    func createOrFetchObjectWithIds<C: NSManagedObject>(_ entityName: C.Type, uuids: [String:NSObject]) -> (Bool, C) {
        var insert:Bool!
        let retObj: C
        guard uuids.isEmpty == false else {
            fatalError("Received empty uniqueIdentifiers list for entityName:\(entityName). Please check unique IDs identifiers for this entity.")
        }
        
        if let foundObj = getOneByIds(entityName, uuids:uuids) {
            insert = false
            retObj = foundObj
        }
        else {
            insert = true
            let createdObj = insertDataForEntityName(entityName)
            for (key, val) in uuids {
                createdObj.setValue(val, forKey: key)
            }
            retObj = createdObj
        }
        return (insert, retObj)
    }

    //DELETE
    func deleteObject(_ obj: NSManagedObject) {
        managedObjectContext.delete(obj)
    }

    func deleteAll(withEntityName: String, andPredicate: NSPredicate? = nil, deleteUsingPersistentCoordinator: Bool = false) -> Void {
        let entity = NSEntityDescription.entity(forEntityName: withEntityName, in: managedObjectContext)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = entity
        fetchRequest.includesPropertyValues = false

        if let predicate = andPredicate {
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
