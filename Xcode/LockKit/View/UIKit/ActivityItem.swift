//
//  ActivityItem.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/20/22.
//

#if os(iOS)
import Foundation
import UIKit
import LinkPresentation

public final class NewKeyFileActivityItem: UIActivityItemProvider {
    
    public init(invitation: NewKey.Invitation) {
        self.invitation = invitation
        
        let url = type(of: self).url(for: invitation)
        do { try FileManager.default.removeItem(at: url) }
        catch { } // ignore
        super.init(placeholderItem: url)
    }
    
    private static func url(for invitation: NewKey.Invitation) -> URL {
        let fileName = invitation.key.name + "." + NewKey.Invitation.fileExtension
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        return fileURL
    }
    
    public let invitation: NewKey.Invitation
    
    public lazy var fileURL = type(of: self).url(for: invitation)
    
    private lazy var encoder = JSONEncoder()
    
    /// Generate the actual item.
    public override var item: Any {
        // save invitation file
        let url = type(of: self).url(for: invitation)
        do {
            let data = try encoder.encode(invitation)
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            assertionFailure("Could not create key file: \(error)")
            return url
        }
    }
    
    // MARK: - UIActivityItemSource
    
    public override func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        
        return invitation.key.name
    }
    
    public override func activityViewController(
        _ activityViewController: UIActivityViewController,
        thumbnailImageForActivityType activityType: UIActivity.ActivityType?,
        suggestedSize size: CGSize
    ) -> UIImage? {
        
        return UIImage(permissionType: invitation.key.permission.type)
    }
    
    @MainActor
    public override func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        
        let imageName = PermissionType.Image(permissionType: invitation.key.permission.type)
        let permissionImageURL = AssetExtractor.shared.url(for: imageName.rawValue, in: .lockKit)
        assert(permissionImageURL != nil, "Missing permission image")
        let metadata = LPLinkMetadata()
        metadata.title = invitation.key.name
        metadata.imageProvider = permissionImageURL.flatMap { NSItemProvider(contentsOf: $0) }
        return metadata
    }
}

public extension NewKeyFileActivityItem {
    
    static let excludedActivityTypes: [UIActivity.ActivityType] = [.postToTwitter,
                                                                   .postToFacebook,
                                                                   .postToWeibo,
                                                                   .postToTencentWeibo,
                                                                   .postToFlickr,
                                                                   .postToVimeo,
                                                                   .print,
                                                                   .assignToContact,
                                                                   .saveToCameraRoll,
                                                                   .addToReadingList,
                                                                   .openInIBooks,
                                                                   .markupAsPDF]
}

// MARK: - Activity Type

/// `UIActivity` types
public enum LockActivity: String {
    
    case newKey =               "com.colemancda.lock.activity.newKey"
    case manageKeys =           "com.colemancda.lock.activity.manageKeys"
    case delete =               "com.colemancda.lock.activity.delete"
    case rename =               "com.colemancda.lock.activity.rename"
    case update =               "com.colemancda.lock.activity.update"
    case homeKitEnable =        "com.colemancda.lock.activity.homeKitEnable"
    case addVoiceShortcut =     "com.colemancda.lock.activity.addVoiceShortcut"
    case shareKeyCloudKit =     "com.colemancda.lock.activity.shareKeyCloudKit"
    
    var activityType: UIActivity.ActivityType {
        return UIActivity.ActivityType(rawValue: self.rawValue)
    }
}

#endif
