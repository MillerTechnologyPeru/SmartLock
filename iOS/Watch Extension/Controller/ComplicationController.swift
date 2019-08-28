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
        let template = self.template(for: complication)
        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        handler(entry)
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
        
        switch complication.family {
        case .modularSmall:
            let image = StyleKit.imageOfPermissionBadgeAnytime(imageSize: CGSize(width: 64, height: 64))
            let complicationTemplate = CLKComplicationTemplateModularSmallSimpleImage()
            let imageProvider = CLKImageProvider(onePieceImage: image)
            imageProvider.tintColor = StyleKit.wirelessBlue
            complicationTemplate.imageProvider = imageProvider
            return complicationTemplate
        default:
            log("Complication family \(complication.family.rawValue) not supported")
            let complicationTemplate = CLKComplicationTemplate()
            return complicationTemplate
        }
    }
}
