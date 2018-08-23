//
//  ParserJSONToCoreData.swift
//  GDAOBase
//
//  Created by IonVoda on 12/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//

import Foundation
import CoreData

protocol ParserDelegate: class {
    func uniqueIds(for modelType: NSManagedObject.Type) -> [String]
    func adjust(propertyName: String, for modelType: NSManagedObject.Type) -> String
    func adjust(propertyValue: NSObject, propertyClassName: String, for model: NSManagedObject) -> NSObject?
}

extension ParserDelegate {
    func adjust(propertyName: String, for modelType: NSManagedObject.Type) -> String {
        return propertyName
    }

    func adjust(propertyValue: NSObject, propertyClassName: String, for model: NSManagedObject) -> NSObject? {
        return propertyValue
    }
}

final class ParserJSONToCoreData {
    private class ParserJSONToCoreDataDelegate: ParserDelegate {
        private weak var delegate: ParserDelegate?

        init(delegate: ParserDelegate?) {
            self.delegate = delegate
        }

        func uniqueIds(for modelType: NSManagedObject.Type) -> [String] {
            return delegate?.uniqueIds(for: modelType) ?? []
        }

        func adjust(propertyName: String, for modelType: NSManagedObject.Type) -> String {
            let adjustedPropertyNameToCoreData: String
            if let coreDataPropertyName = delegate?.adjust(propertyName: propertyName, for: modelType) {
                adjustedPropertyNameToCoreData = coreDataPropertyName
            } else {
                adjustedPropertyNameToCoreData = propertyName
            }

            return adjustedPropertyNameToCoreData
        }

        func adjust(propertyValue: NSObject, propertyClassName: String, for model: NSManagedObject) -> NSObject? {
            if let adjustedPropertyValue = delegate?.adjust(propertyValue: propertyValue, propertyClassName: propertyClassName, for: model) {
                return adjustedPropertyValue
            } else {
                return propertyValue
            }
        }
    }

    //MARK: Properties
    private let daoBase: DAOCoreData
    private let delegate: ParserJSONToCoreDataDelegate

    //MARK: Initializer
    init(_ dao: DAOCoreData, delegate: ParserDelegate?) {
        self.daoBase = dao
        self.delegate = ParserJSONToCoreDataDelegate(delegate: delegate)
    }

    //MARK: - Public methods
    func parse<C: NSManagedObject>(_ array: [[String: NSObject]], rootType: C.Type) -> [C]? {
        let parsedManagedObjects = self.addEntityArray(array, modelType: rootType)
        return parsedManagedObjects
    }

    func parseAsync<C: NSManagedObject>(_ array: [[String: NSObject]], rootType: C.Type, completion: @escaping ([C]?) -> Void) {
        daoBase.perform { [weak self] in
            let parsedManagedObjects = self?.parse(array, rootType: rootType)
            completion(parsedManagedObjects)
        }
    }

    // MARK: - Private/Fileprivate methods
    // MARK: AddEntity methods
    private func addEntityArray<C: NSManagedObject>(_ entities: [[String: NSObject]], modelType: C.Type) -> [C] {
        let cdArray: [C] = entities.compactMap { entity in
            let childObj = addEntity(entity, modelType: modelType)
            return childObj
        }

        return cdArray
    }

    private func addEntity<C: NSManagedObject>(_ jsonEntity: [String: NSObject], modelType: C.Type) -> C? {
        guard jsonEntity.isEmpty == false else {
            return nil
        }

        let identifiers = delegate.uniqueIds(for: modelType)
        guard identifiers.isEmpty == false else {
            fatalError("Missing identifiers in NSManagedObject ClassName:\(modelType)")
        }

        let identifiersDic = identifiers.reduce([String: NSObject]()) { (result, jsonPropertyName) in
            let coreDataPropertyName: String = delegate.adjust(propertyName: jsonPropertyName, for: modelType)

            var resultDic = result
            resultDic[coreDataPropertyName] = jsonEntity[jsonPropertyName]
            return resultDic
        }

        let model: C
        if let fetchedModel = daoBase.fetch(entityType: modelType, uniqueIdentifiers: identifiersDic) {
            model = fetchedModel
        } else {
            model = daoBase.insert(entityType: modelType)
        }

        let allPropertiesKeySet: Set<String> = Set(model.entity.propertiesByName.keys)
        let relationshipsKeySet: Set<String> = Set(model.entity.relationshipsByName.keys)
        let propertiesKeySet: Set<String> = allPropertiesKeySet.subtracting(relationshipsKeySet)

        jsonEntity.forEach{ (jsonPropertyName, value) in
            let adjustedPropertyNameToCoreData = delegate.adjust(propertyName: jsonPropertyName, for: modelType)
            if relationshipsKeySet.contains(adjustedPropertyNameToCoreData) {
                guard let relationValue = createRelation(propertyValue: value, relationshipClassName: adjustedPropertyNameToCoreData, parent: model) else {
                    fatalError("Missing property:\(adjustedPropertyNameToCoreData) in NSManagedObject ClassName:\(modelType)")
                }
                model.setValue(relationValue, forKey: adjustedPropertyNameToCoreData)
            } else if propertiesKeySet.contains(adjustedPropertyNameToCoreData) {
                guard let propertyValue = delegate.adjust(propertyValue: value, propertyClassName: adjustedPropertyNameToCoreData, for: model)  else {
                    fatalError("Adjusting property:\(adjustedPropertyNameToCoreData) in NSManagedObject ClassName:\(modelType)")
                }
                model.setValue(propertyValue, forKey: adjustedPropertyNameToCoreData)
            }
        }

        return model
    }

    private func createRelation<C: NSManagedObject>(propertyValue: NSObject, relationshipClassName: String, parent: C) -> NSObject? {
        if let objectToProcess = propertyValue as? [String: NSObject] {
            if parent.isToMany(relationshipName: relationshipClassName) {
                let entities = union(value: [objectToProcess], relationshipClassName: relationshipClassName, parent: parent)
                return entities
            } else {
                let type = parent.classType(relationshipName: relationshipClassName)
                let entity = addEntity(objectToProcess, modelType: type)
                return entity
            }
        } else if let objectToProcess = propertyValue as? [[String: NSObject]] {
            if parent.isToMany(relationshipName: relationshipClassName) {
                let entities = union(value: objectToProcess, relationshipClassName: relationshipClassName, parent: parent)
                return entities
            } else {
                fatalError("Property:\(relationshipClassName) in NSManagedObject:\(parent)")
            }
        }

        return nil
    }

    private func union<C: NSManagedObject>(value: [[String: NSObject]], relationshipClassName: String, parent: C) -> NSObject? {
        let type = parent.classType(relationshipName: relationshipClassName)
        let array = addEntityArray(value, modelType: type)
        let newChild = Set(array)
        if let oldRelationSet = parent.value(forKey: relationshipClassName) as? Set<NSManagedObject> {
            return newChild.union(oldRelationSet) as NSSet
        } else {
            return newChild as NSSet
        }
    }
}
