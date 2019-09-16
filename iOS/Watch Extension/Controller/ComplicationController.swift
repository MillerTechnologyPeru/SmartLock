//
//  ComplicationController.swift
//  Watch Extension
//
//  Created by Alsey Coleman Miller on 8/28/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import ClockKit
import LockKit

final class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        log("⌚️ Initialized \(type(of: self))")
    }
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        log("⌚️ Providing current timeline entry for complication")
        async {
            do { try Store.shared.scan(duration: 1.0) }
            catch { log("⚠️ Unable to scan") }
            mainQueue { [weak self] in
                guard let self = self else { return }
                let template = self.template(for: complication)
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                handler(entry)
            }
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> ()) {
        // This method will be called once per supported complication, and the results will be cached
        log("⌚️ Providing placeholder template for complication")
        let template = self.template(for: complication)
        handler(template)
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(nil)
    }
    
    // MARK: - Private Methods
    
    private func template(for complication: CLKComplication) -> CLKComplicationTemplate {
        
        //let locksCount = Store.shared.peripherals.value.count
        switch complication.family {
        case .modularSmall:
            let image = UIImage(named: "watchAdmin")!
            let template = CLKComplicationTemplateModularSmallSimpleImage()
            let imageProvider = CLKImageProvider(onePieceImage: image)
            imageProvider.tintColor = StyleKit.wirelessBlue
            template.imageProvider = imageProvider
            return template
            /*
        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeTallBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "Lock")
            template.bodyTextProvider = CLKSimpleTextProvider(text: "\(locksCount) nearby locks")
            return template
        case .utilitarianSmall:
            let image = StyleKit.imageOfPermissionBadgeAnytime(imageSize: CGSize(width: 18, height: 18))
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.textProvider = CLKSimpleTextProvider(text: "\(locksCount) nearby locks")
            template.imageProvider = CLKImageProvider(onePieceImage: image)
            return template
        case .utilitarianSmallFlat:
            let image = StyleKit.imageOfPermissionBadgeAnytime(imageSize: CGSize(width: 18, height: 18))
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.textProvider = CLKSimpleTextProvider(text: "\(locksCount) nearby locks")
            template.imageProvider = CLKImageProvider(onePieceImage: image)
            return template
        case .utilitarianLarge:
            let image = StyleKit.imageOfPermissionBadgeAnytime(imageSize: CGSize(width: 18, height: 18))
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.textProvider = CLKSimpleTextProvider(text: "\(locksCount) nearby locks")
            template.imageProvider = CLKImageProvider(onePieceImage: image)
            return template
        case .circularSmall:
            let image = StyleKit.imageOfPermissionBadgeAnytime(imageSize: CGSize(width: 32, height: 32))
            let template = CLKComplicationTemplateCircularSmallSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: image)
            return template
        case .extraLarge:
            if locksCount > 0 {
                let image = StyleKit.imageOfPermissionBadgeAnytime(imageSize: CGSize(width: 84, height: 84))
                let template = CLKComplicationTemplateExtraLargeStackImage()
                template.line1ImageProvider = CLKImageProvider(onePieceImage: image)
                template.line2TextProvider = CLKSimpleTextProvider(text: "\(locksCount) nearby locks")
                return template
            } else {
                let image = StyleKit.imageOfPermissionBadgeAnytime(imageSize: CGSize(width: 182, height: 182))
                let template = CLKComplicationTemplateExtraLargeSimpleImage()
                template.imageProvider = .init(onePieceImage: image)
                return template
            }
        case .graphicCorner:
            guard #available(watchOSApplicationExtension 5.0, *)
                else { fatalError() }
            let template = CLKComplicationTemplateGraphicCornerTextImage()
            let image = StyleKit.imageOfPermissionBadgeAnytime(imageSize: CGSize(width: 40, height: 40))
            template.textProvider = CLKSimpleTextProvider(text: "\(locksCount) nearby locks")
            template.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
            return template
        case .graphicBezel:
            guard #available(watchOSApplicationExtension 5.0, *)
                else { fatalError() }
            let image = StyleKit.imageOfPermissionBadgeAnytime(imageSize: CGSize(width: 84, height: 84))
            let template = CLKComplicationTemplateGraphicBezelCircularText()
            template.textProvider = CLKSimpleTextProvider(text: "\(locksCount) nearby locks")
            let circularTemplate = CLKComplicationTemplateGraphicCircularImage()
            circularTemplate.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
            template.circularTemplate = circularTemplate
            return template
        case .graphicCircular:
            guard #available(watchOSApplicationExtension 6.0, *)
                else { fatalError() }
            let image = StyleKit.imageOfPermissionBadgeAnytime(imageSize: CGSize(width: 84, height: 84))
            let template = CLKComplicationTemplateGraphicCircularImage()
            template.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
            return template
        case .graphicRectangular:
            guard #available(watchOSApplicationExtension 5.0, *)
                else { fatalError() }
            let image = StyleKit.imageOfPermissionBadgeAnytime(imageSize: CGSize(width: 94, height: 94))
            let template = CLKComplicationTemplateGraphicRectangularLargeImage()
            template.textProvider = CLKSimpleTextProvider(text: "\(locksCount) nearby locks")
            template.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
            return template
        */
        default:
            fatalError("Complication family \(complication.family.rawValue) not supported")
        }
    }
}
