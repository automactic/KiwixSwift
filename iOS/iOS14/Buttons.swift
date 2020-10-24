//
//  Buttons.swift
//  Kiwix
//
//  Created by Chris Li on 10/24/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct SwiftUIBarButton: View {
    let iconName: String
    @State var isPushed: Bool = false
    var action: (() -> Void)?
    
    var image: some View {
        Image(systemName: iconName)
            .font(Font.body.weight(.regular))
            .imageScale(.large)
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            ZStack(alignment: .center) {
                if isPushed {
                    Color(.systemBlue).cornerRadius(6)
                    image.foregroundColor(Color(.systemBackground))
                } else {
                    image
                }
            }.frame(width: 32, height: 32)
        }
    }
}

@available(iOS 14.0, *)
struct BarButtonModifier: ViewModifier {
    @Binding var isPushed: Bool
    
    init(isPushed: Binding<Bool>? = nil) {
        self._isPushed = isPushed ?? .constant(true)
    }
    
    private func image(_ content: Content) -> some View {
        content.font(Font.body.weight(.regular)).imageScale(.large).padding(10)
    }
    
    func body(content: Content) -> some View {
        return ZStack {
            if isPushed {
                Color(.systemBlue).aspectRatio(1, contentMode: .fit).cornerRadius(6)
                image(content).foregroundColor(Color(.systemBackground))
            } else {
                image(content)
            }
        }
    }
}

@available(iOS 14.0, *)
struct GoBackButton: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    var body: some View {
        Button {
            sceneViewModel.goBack()
        } label: {
            Image(systemName: "chevron.left")
        }
        .modifier(BarButtonModifier())
        .disabled(!sceneViewModel.canGoBack || sceneViewModel.contentDisplayMode != .webView)
    }
}

@available(iOS 14.0, *)
struct GoForwardButton: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel

    var body: some View {
        Button {
            sceneViewModel.goForward()
        } label: {
            Image(systemName: "chevron.right")
        }
        .modifier(BarButtonModifier())
        .disabled(!sceneViewModel.canGoForward || sceneViewModel.contentDisplayMode != .webView)
    }
}

@available(iOS 14.0, *)
struct HouseButton: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel

    var body: some View {
        let image = Image(systemName: "house").imageScale(.large)
        Button {
            sceneViewModel.houseButtonTapped()
        } label: {
            ZStack {
                if sceneViewModel.contentDisplayMode == .homeView {
                    Color(.systemBlue).aspectRatio(1, contentMode: .fit).cornerRadius(6)
                    image.foregroundColor(Color(.systemBackground)).padding(4)
                } else {
                    image.padding(4)
                }
            }
        }.disabled(sceneViewModel.currentArticleURL == nil)
    }
}
