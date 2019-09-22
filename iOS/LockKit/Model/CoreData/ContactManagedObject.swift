//
//  ContactManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock
import CloudKit
import Contacts

public final class ContactManagedObject: NSManagedObject {
    
    internal convenience init(identifier: String, context: NSManagedObjectContext) {
        
        self.init(context: context)
        self.identifier = identifier
    }
    
    internal static func find(_ identifier: String, in context: NSManagedObjectContext) throws -> ContactManagedObject? {
        
        try context.find(identifier: identifier as NSString,
                         propertyName: #keyPath(ContactManagedObject.identifier),
                         type: ContactManagedObject.self)
    }
}

// MARK: - Fetch

public extension ContactManagedObject {
    
    static func fetch(in context: NSManagedObjectContext) throws -> [ContactManagedObject] {
        let fetchRequest = NSFetchRequest<ContactManagedObject>()
        fetchRequest.entity = entity()
        fetchRequest.fetchBatchSize = 40
        fetchRequest.sortDescriptors = [
            .init(keyPath: \ContactManagedObject.identifier, ascending: true)
        ]
        return try context.fetch(fetchRequest)
    }
}

// MARK: - Store

public extension Store {
    
    #if os(iOS)
    func updateContacts() throws {
        
        // insert new contacts
        var insertedUsers = Set<String>()
        let context = backgroundContext
        try cloud.container.discoverAllUserIdentities { (user) in
            guard let userRecordID = user.userRecordID
                else { return }
            insertedUsers.insert(userRecordID.recordName)
            context.commit { try $0.insert(contact: user) }
        }
        
        // delete old contacts
        let fetchRequest = NSFetchRequest<ContactManagedObject>()
        fetchRequest.entity = ContactManagedObject.entity()
        fetchRequest.sortDescriptors = [
            .init(keyPath: \ContactManagedObject.identifier, ascending: true)
        ]
        fetchRequest.predicate = NSPredicate(format: "NONE %K IN %@", #keyPath(ContactManagedObject.identifier), insertedUsers)
        context.commit { (context) in
            try context.fetch(fetchRequest).forEach {
                context.delete($0)
            }
        }
    }
    #endif
}

internal extension NSManagedObjectContext {
    
    @discardableResult
    func insert(contact identity: CKUserIdentity) throws -> ContactManagedObject? {
        
        guard let userRecordID = identity.userRecordID
            else { return nil }
        
        // find or create
        let identifier = userRecordID.recordName
        let managedObject = try ContactManagedObject.find(identifier, in: self)
            ?? ContactManagedObject(identifier: identifier, context: self)
        
        // update values
        managedObject.namePrefix = identity.nameComponents?.namePrefix
        managedObject.givenName = identity.nameComponents?.givenName
        managedObject.middleName = identity.nameComponents?.middleName
        managedObject.familyName = identity.nameComponents?.familyName
        managedObject.nameSuffix = identity.nameComponents?.namePrefix
        managedObject.nickname = identity.nameComponents?.nickname
        
        return managedObject
    }
}
