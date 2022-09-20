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

// MARK: - Computed Properties

public extension ContactManagedObject {
    
    var nameComponents: PersonNameComponents? {
        get {
            var nameComponents = PersonNameComponents()
            nameComponents.namePrefix = namePrefix
            nameComponents.givenName = givenName
            nameComponents.middleName = middleName
            nameComponents.familyName = familyName
            nameComponents.nameSuffix = nameSuffix
            nameComponents.nickname = nickname
            return nameComponents
        }
        set {
            assert(newValue?.phoneticRepresentation == nil)
            namePrefix = newValue?.namePrefix
            givenName = newValue?.givenName
            middleName = newValue?.middleName
            familyName = newValue?.familyName
            nameSuffix = newValue?.nameSuffix
            nickname = newValue?.nickname
        }
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
    
    func updateContacts() async throws {
        
        // exclude self
        let currentUser = try await cloud.container.fetchUserRecordID()
        
        // insert new contacts
        var insertedUsers = Set<String>()
        for try await user in cloud.container.discoverAllUserIdentities() {
            guard let userRecordID = user.userRecordID,
                userRecordID != currentUser
                else { return }
            insertedUsers.insert(userRecordID.recordName)
            // save in CoreData
            await backgroundContext.commit {
                try $0.insert(contact: user)
            }
        }
        
        // delete old contacts
        let fetchRequest = NSFetchRequest<ContactManagedObject>()
        fetchRequest.entity = ContactManagedObject.entity()
        fetchRequest.sortDescriptors = [
            .init(keyPath: \ContactManagedObject.identifier, ascending: true)
        ]
        fetchRequest.predicate = NSPredicate(format: "NONE %K IN %@", #keyPath(ContactManagedObject.identifier), insertedUsers)
        await backgroundContext.commit { (context) in
            try context.fetch(fetchRequest).forEach {
                context.delete($0)
            }
        }
    }
}

internal extension ContactManagedObject {
    
    static let contactStore = CNContactStore()
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
        managedObject.nameComponents = identity.nameComponents
        if let email = identity.lookupInfo?.emailAddress {
            managedObject.email = email
        }
        if let phoneNumber = identity.lookupInfo?.phoneNumber {
            managedObject.phone = phoneNumber
        }
        
        // find contact in address book
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            do {
                let contactStore = ContactManagedObject.contactStore
                let predicate = CNContact.predicateForContacts(withIdentifiers: identity.contactIdentifiers)
                let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: [
                    CNContactThumbnailImageDataKey as NSString,
                    CNContactEmailAddressesKey as NSString,
                    CNContactPhoneNumbersKey as NSString
                ])
                managedObject.email = contacts.compactMap({ $0.emailAddresses.first?.value as String? }).first
                managedObject.phone = contacts.compactMap({ $0.phoneNumbers.first?.value.stringValue }).first
                managedObject.image = contacts.compactMap({ $0.thumbnailImageData }).first
            } catch {
                #if DEBUG
                log("⚠️ Unable to update contact information from address book. \(error)")
                #endif
            }
        }
        
        return managedObject
    }
}
