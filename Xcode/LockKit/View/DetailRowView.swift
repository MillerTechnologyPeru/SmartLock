//
//  DetailRowView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/28/22.
//

import SwiftUI

struct DetailRowView: View {
    
    let title: LocalizedStringKey
    
    let value: String
    
    var body: some View {
        #if os(watchOS)
        VStack(alignment: .leading) {
            Text(verbatim: value)
            Text(title)
                .font(.body)
                .foregroundColor(.gray)
        }
        #else
        HStack {
            Text(title)
                .frame(width: titleWidth, height: nil, alignment: .leading)
                .font(.body)
                .foregroundColor(.gray)
            Text(verbatim: value)
        }
        #endif
    }
}

private extension DetailRowView {
    
    #if !os(watchOS)
    var titleWidth: CGFloat {
        100
    }
    #endif
}

#if DEBUG
struct DetailRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            DetailRowView(
                title: "Lock",
                value: "\(UUID())"
            )
            DetailRowView(
                title: "Key",
                value: "\(UUID())"
            )
            DetailRowView(
                title: "Type",
                value: "Admin"
            )
        }
    }
}
#endif
