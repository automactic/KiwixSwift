//
//  BuildingBlocks.swift
//  Kiwix
//
//  Created by Chris Li on 10/26/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

@available(iOS 13.0, *)
struct ActionCell: View {
    let title: String
    let isDestructive: Bool
    let action: (() -> Void)
    
    init(title: String, isDestructive: Bool = false, action: @escaping (() -> Void) = {}) {
        self.title = title
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action, label: {
            HStack {
                Spacer()
                Text(title)
                    .fontWeight(.medium)
                    .foregroundColor(isDestructive ? .red : nil)
                Spacer()
            }
        })
    }
}

@available(iOS 14.0, *)
extension View {
    @ViewBuilder func hidden(_ isHidden: Bool) -> some View {
        if isHidden {
            self.hidden()
        } else {
            self
        }
    }
}

@available(iOS 14.0, *)
struct WebView: UIViewRepresentable {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    func makeUIView(context: Context) -> WKWebView { sceneViewModel.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) { }
}

@available(iOS 13.0, *)
struct DisclosureIndicator: View {
    var body: some View {
        Image(systemName: "chevron.forward")
            .font(Font.footnote.weight(.bold))
            .foregroundColor(Color(.systemFill))
    }
}

@available(iOS 13.0, *)
struct Favicon: View {
    private let image: Image
    private let outline = RoundedRectangle(cornerRadius: 4, style: .continuous)
    
    init(data: Data?) {
        if let data = data, let image = UIImage(data: data) {
            self.image = Image(uiImage: image)
        } else {
            self.image = Image("GenericZimFile")
        }
    }
    
    init(uiImage: UIImage) {
        self.image = Image(uiImage: uiImage)
    }
    
    var body: some View {
        image
            .renderingMode(.original)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
            .background(Color(.white))
            .clipShape(outline)
            .overlay(outline.stroke(Color(.white).opacity(0.9), lineWidth: 1))
    }
}

@available(iOS 13.0, *)
struct TitleDetailCell: View {
    let title: String
    let detail: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(detail).foregroundColor(.secondary)
        }
    }
}

@available(iOS 13.0, *)
extension List {
    func insetGroupedListStyle() -> some View {
        if #available(iOS 14.0, *) {
            return AnyView(self.listStyle(InsetGroupedListStyle()))
        } else {
            return AnyView(self.listStyle(GroupedListStyle()).environment(\.horizontalSizeClass, .regular))
        }
    }
}

@available(iOS 13.0, *)
struct ZimFileCell: View {
    let zimFile: ZimFile
    let accessory: Accessory
    
    init(_ zimFile: ZimFile, accessory: Accessory = .none) {
        self.zimFile = zimFile
        self.accessory = accessory
    }
    
    var body: some View {
        HStack {
            Favicon(data: zimFile.faviconData)
            VStack(alignment: .leading) {
                Text(zimFile.title).lineLimit(1)
                Text([zimFile.sizeDescription, zimFile.creationDateDescription, zimFile.articleCountShortDescription]
                        .compactMap({$0})
                        .joined(separator: ", ")).lineLimit(1).font(.footnote)
            }.foregroundColor(.primary)
            Spacer()
            switch accessory {
            case .none:
                EmptyView()
            case .onDevice:
                if zimFile.state == .onDevice {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Image(systemName:"iphone").foregroundColor(.secondary)
                    } else if UIDevice.current.userInterfaceIdiom == .pad {
                        Image(systemName:"ipad").foregroundColor(.secondary)
                    }
                } else {
                    EmptyView()
                }
            }
            DisclosureIndicator()
        }
    }
    
    enum Accessory {
        case none, onDevice
    }
}

@available(iOS 13.0, *)
struct ZimFileDownloadDetailView: View {
    let zimFile: ZimFile
    
    init(_ zimFile: ZimFile) {
        self.zimFile = zimFile
    }
    
    var progress: String {
        [zimFile.downloadedSizeDescription, zimFile.downloadedPercentDescription]
            .compactMap({ $0 })
            .joined(separator: " - ")
    }
    
    var body: some View {
        switch zimFile.state {
        case .downloadQueued:
            Text("Queued")
        case .downloadInProgress:
            HStack {
                Text("Downloading...")
                Spacer()
                Text(progress).foregroundColor(.secondary)
            }
        case .downloadPaused:
            HStack {
                Text("Pause")
                Spacer()
                Text(progress).foregroundColor(.secondary)
            }
        case .downloadError:
            Text("Error")
            if let errorDescription = zimFile.downloadErrorDescription {
                Text(errorDescription)
            }
        default:
            EmptyView()
        }
    }
}
