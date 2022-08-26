//
//  LibraryGridPadding.swift
//  Kiwix
//
//  Created by Chris Li on 5/22/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

/// Add padding around the modified view. On iOS, the padding is adjusted so that the modified view align with the search bar.
struct LibraryGridPadding: ViewModifier {
    let width: CGFloat
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content.padding(.all)
        #elseif os(iOS)
        content.padding([.horizontal, .bottom], width > 375 ? 20 : 16)
        #endif
    }
}

struct GridCommon: ViewModifier {
    #if os(iOS)
    @Environment(\.verticalSizeClass) var verticalSizeClass
    #endif
    
    func body(content: Content) -> some View {
        #if os(macOS)
        ScrollView {
            content.padding(.all)
        }
        #elseif os(iOS)
        GeometryReader { proxy in
            ScrollView {
                content.padding(
                    verticalSizeClass == .compact ? .all : [.horizontal, .bottom],
                    proxy.size.width > 375 ? 20 : 16
                )
            }
        }
        #endif
    }
}

