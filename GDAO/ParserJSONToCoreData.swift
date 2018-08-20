//
//  ParserJSONToCoreData.swift
//  GDAOBase
//
//  Created by IonVoda on 12/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//

import Foundation
import CoreData

final class ParserJSONToCoreData {
    private let daoBase: DAOCoreData
    init(_ dao: DAOCoreData) {
        self.daoBase = dao
    }

    //MARK: - Public methods
    func parseAsync<C: NSManagedObject>(_ array: [[String: NSObject]], rootType: C.Type, completion: @escaping ([C]?) -> Void) {
        daoBase.perform { [weak self] in
            let parsedManagedObjects = self?.addEntityArray(array, type: rootType)
            completion(parsedManagedObjects)
        }
    }

    // MARK: - Private/Fileprivate methods
    // MARK: AddEntity methods
    fileprivate func addEntityArray<C: NSManagedObject>(_ entities: [[String: NSObject]], type: C.Type) -> [C] {
        let cdArray: [C] = entities.compactMap({ entity in
            let childObj = addEntity(entity, type: type)
            return childObj
        })

        return cdArray
    }

    fileprivate func addEntity<C: NSManagedObject>(_ entity: [String: NSObject], type: C.Type) -> C? {
        guard
            entity.isEmpty == false,
            //TODO: get identifiers!
            let id = entity["id"] as? NSNumber else {
            return nil
        }

        let model: C
        if let fetchedModel = daoBase.fetch(entityType: type, uniqueIdentifiers: ["id": id]) {
            model = fetchedModel
        } else {
            model = daoBase.insert(entityType: type)
        }

        let propertiesKeySet: Set<String> = Set(model.entity.propertiesByName.keys)
        let relationsKeySet: Set<String> = Set(model.entity.relationshipsByName.keys)

        entity.forEach{ (key, value) in
            //TODO: adapting json property name to database property name
            var cdKey = key
            if key == "kids" {
                cdKey = "commentSet"
            }

            guard model.entity.propertiesByName.keys.contains(cdKey) == true else {
                fatalError("Missing property:\(cdKey) in NSManagedObject ClassName:\(type)")
            }

            if propertiesKeySet.contains(cdKey) {
                guard let propertyValue = createProperty(propertyValue: value, propertyClassName: cdKey, model: model)  else {
                    return
                }
                model.setValue(propertyValue, forKey: cdKey)
            } else if relationsKeySet.contains(cdKey) {
                guard let relationValue = createRelation(propertyValue: value, relationClassName: cdKey, model: model) else {
                    return
                }

                model.setValue(relationValue, forKey: cdKey)
            }
        }

        return model
    }

    private func classType(relationName: String, in model: NSManagedObject) -> (Bool, NSManagedObject.Type) {
        let modelEntity = model.entity
        let modelAttributes = modelEntity.relationshipsByName
        let entityDescription = modelAttributes[relationName]
        guard
            let relationClassStr = entityDescription?.destinationEntity?.name,
            let classType = NSClassFromString(relationClassStr) as? NSManagedObject.Type else {
                fatalError("Missing propertyName:\(relationName) in NSManagedObjectEntity:\(modelEntity)")
        }

        let isToMany = entityDescription?.isToMany ?? false
        return (isToMany, classType)
    }

    private func createRelation<C: NSManagedObject>(propertyValue: NSObject, relationClassName: String, model: C) -> NSObject? {
        let (isToMany, type) = classType(relationName: relationClassName, in: model)
        if let objectToProcess = propertyValue as? [String: NSObject],
            let entity = addEntity(objectToProcess, type: type) {
            if isToMany {
                let newChild = Set([entity])
                if let oldRelationSet = model.value(forKey: relationClassName) as? Set<NSManagedObject> {
                    return newChild.union(oldRelationSet) as NSSet
                }
                return newChild as NSSet
            }
            return entity
        } else if let objectToProcess = propertyValue as? [[String: NSObject]] {
            let array = addEntityArray(objectToProcess, type: type)
            let newChild = Set(array)
            if let oldRelationSet = model.value(forKey: relationClassName) as? Set<NSManagedObject> {
                return newChild.union(oldRelationSet) as NSSet
            }
            return newChild as NSSet
        }

        return nil
    }

    private func classType(propertyName: String, in model: NSManagedObject) -> AnyClass {
        let modelEntity = model.entity
        let modelAttributes = modelEntity.attributesByName
        guard
            let propertyClassStr = modelAttributes[propertyName]?.attributeValueClassName,
            let propertyClass = NSClassFromString(propertyClassStr) else {
                fatalError("Missing propertyName:\(propertyName) in NSManagedObjectEntity:\(modelEntity)")
        }

        return propertyClass
    }

    private func createProperty<C: NSManagedObject>(propertyValue: NSObject, propertyClassName: String, model: C) -> NSObject? {
        let type: AnyClass = classType(propertyName: propertyClassName, in: model)
        guard propertyValue.isKind(of: NSNull.self) == false else {
            return nil
        }

        guard let valueStr = propertyValue as? String else {
            return propertyValue
        }

        if type == NSDecimalNumber.self {
            return NSDecimalNumber(string: valueStr)
        }
        return propertyValue
    }
}
