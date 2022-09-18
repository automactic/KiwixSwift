//
//  Patches.swift
//  Kiwix
//
//  Created by Chris Li on 6/11/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import Foundation
import SwiftUI

extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}

extension View {
    func modify<Content>(@ViewBuilder _ transform: (Self) -> Content) -> Content {
        transform(self)
    }
}

#if os(macOS)
enum UserInterfaceSizeClass {
    case compact
    case regular
}
struct HorizontalSizeClassEnvironmentKey: EnvironmentKey {
    static let defaultValue: UserInterfaceSizeClass = .regular
}
struct VerticalSizeClassEnvironmentKey: EnvironmentKey {
    static let defaultValue: UserInterfaceSizeClass = .regular
}
extension EnvironmentValues {
    var horizontalSizeClass: UserInterfaceSizeClass {
        get { self[HorizontalSizeClassEnvironmentKey.self] }
        set { self[HorizontalSizeClassEnvironmentKey.self] = newValue }
    }
    var verticalSizeClass: UserInterfaceSizeClass {
        get { return self[VerticalSizeClassEnvironmentKey.self] }
        set { self[VerticalSizeClassEnvironmentKey.self] = newValue }
    }
}
#endif

struct FocusedSceneValue<T>: ViewModifier {
    private let keyPath: WritableKeyPath<FocusedValues, T?>
    private let value: T
    
    init(_ keyPath: WritableKeyPath<FocusedValues, T?>, _ value: T) {
        self.keyPath = keyPath
        self.value = value
    }
    
    func body(content: Content) -> some View {
        if #available(macOS 12.0, iOS 15.0, *) {
            content.focusedSceneValue(keyPath, value)
        } else {
            content.focusedValue(keyPath, value)
        }
    }
}

/// Ports theme adaptive background colors to SwiftUI
public extension Color {
    #if os(macOS)
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
    static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
    #elseif os(iOS)
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    #endif
}
