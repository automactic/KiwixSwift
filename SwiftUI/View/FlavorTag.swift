//
//  FlavorTag.swift
//  Kiwix
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
struct FlavorTag: View {
    let flavor: Flavor
    
    init(_ flavor: Flavor) {
        self.flavor = flavor
    }
    
    var body: some View {
        Text(flavor.description)
            .fontWeight(.medium)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: .infinity, style: .continuous)
                    .stroke(.quaternary, lineWidth: 1)
            )
            .background(
                backgroundColor.opacity(0.75),
                in: RoundedRectangle(cornerRadius: .infinity, style: .continuous)
            )
            .help(help)
    }
    
    var backgroundColor: Color {
        switch flavor {
        case .max:
            return .green
        case .noPic:
            return .blue
        case .mini:
            return .orange
        }
    }
    
    var help: String {
        switch flavor {
        case .max:
            return "everything except large media files like video/audio"
        case .noPic:
            return "most pictures have been removed"
        case .mini:
            return "only a subset of the text is available, probably the first section"
        }
    }
}

@available(iOS 15.0, *)
struct Tag_Previews: PreviewProvider {
    static var previews: some View {
        FlavorTag(Flavor(rawValue: "maxi")!).padding().previewLayout(.sizeThatFits)
        FlavorTag(Flavor(rawValue: "nopic")!).padding().previewLayout(.sizeThatFits)
        FlavorTag(Flavor(rawValue: "mini")!).padding().previewLayout(.sizeThatFits)
    }
}
