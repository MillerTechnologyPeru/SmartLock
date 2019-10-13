//
//  SliderCell.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/30/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import SwiftUI

/// Slider Cell
@available(iOSApplicationExtension 13.0, *)
public struct SliderCell: View {
    
    public let title: Text
    
    public let value: Binding<Double>
    
    public let text: (Double) -> (Text)
    
    public let from: Double
    
    public let through: Double
    
    public let by: Double
    
    public init(title: Text,
                value: Binding<Double>,
                from: Double,
                through: Double,
                by: Double = 1.0,
                text: @escaping (Double) -> (Text)) {
        
        self.title = title
        self.value = value
        self.text = text
        self.from = from
        self.through = through
        self.by = by
    }
    
    public var body: some View {
        VStack {
            Spacer(minLength: 8)
            HStack {
                title.lineLimit(2)
                Spacer(minLength: 20)
                text(value.wrappedValue)
            }
            Slider(value: value, in: from ... through, step: by)
        }
    }
}

/*
#if DEBUG
@available(iOSApplicationExtension 13.0, *)
extension SliderCell: PreviewProvider {
    
    public static var previews: some View {
        SliderCell()
    }
}
#endif
*/
