//
//  ZimFileCell.swift
//  Kiwix
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI

struct ZimFileCell: View {
    @State var isHovering: Bool = false
    
    let zimFile: ZimFile
    let prominent: Prominent
    
    init(_ zimFile: ZimFile, prominent: Prominent = .size) {
        self.zimFile = zimFile
        self.prominent = prominent
    }
    
    var body: some View {
        VStack(spacing: 8) {
            switch prominent {
            case .size:
                HStack(alignment: .top) {
                    Text(ZimFileCell.sizeFormatter.string(fromByteCount: zimFile.size))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    if #available(iOS 15.0, *), let flavor = Flavor(rawValue: zimFile.flavor) {
                        FlavorTag(flavor)
                    }
                }
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        if #available(iOS 15.0, *) {
                            Text("\(zimFile.articleCount.formatted(.number.notation(.compactName))) articles")
                                .font(.caption)
                        }
                        Text(ZimFileCell.dateFormatter.string(from: zimFile.created))
                            .font(.caption)
                    }.foregroundColor(.secondary)
                    Spacer()
                }
            case .title:
                HStack {
                    Text(
                        zimFile.category == Category.stackExchange.rawValue ?
                        zimFile.name.replacingOccurrences(of: "Stack Exchange", with: "") :
                        zimFile.name
                    ).fontWeight(.semibold).foregroundColor(.primary).lineLimit(1)
                    Spacer()
                    if #available(iOS 15.0, *) {
                        Favicon(
                            category: Category(rawValue: zimFile.category) ?? .other,
                            imageData: zimFile.faviconData,
                            imageURL: zimFile.faviconURL
                        ).frame(height: 20)
                    }
                }
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text(ZimFileCell.sizeFormatter.string(fromByteCount: zimFile.size))
                            .font(.caption)
                        Text(ZimFileCell.dateFormatter.string(from: zimFile.created))
                            .font(.caption)
                    }.foregroundColor(.secondary)
                    Spacer()
                    if #available(iOS 15.0, *), let flavor = Flavor(rawValue: zimFile.flavor) {
                        FlavorTag(flavor)
                    }
                }
            }
        }
        .padding()
        .modifier(CellBackground(isHovering: isHovering))
        .onHover { self.isHovering = $0 }
    }
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    enum Prominent {
        case size, title
    }
}

struct ZimFileCell_Previews: PreviewProvider {
    static let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    static let zimFile: ZimFile = {
        let zimFile = ZimFile(context: context)
        zimFile.articleCount = 100
        zimFile.category = "wikipedia"
        zimFile.created = Date()
        zimFile.fileID = UUID()
        zimFile.flavor = "mini"
        zimFile.languageCode = "en"
        zimFile.mediaCount = 100
        zimFile.name = "Wikipedia Zim File Name"
        zimFile.persistentID = ""
        zimFile.size = 1000000000
        
        return zimFile
    }()
    
    static var previews: some View {
        Group {
            ZimFileCell(ZimFileCell_Previews.zimFile)
                .preferredColorScheme(.light)
                .padding()
                .frame(width: 300, height: 100)
                .previewLayout(.sizeThatFits)
            ZimFileCell(ZimFileCell_Previews.zimFile)
                .preferredColorScheme(.dark)
                .padding()
                .frame(width: 300, height: 100)
                .previewLayout(.sizeThatFits)
            ZimFileCell(ZimFileCell_Previews.zimFile, prominent: .title)
                .preferredColorScheme(.light)
                .padding()
                .frame(width: 300, height: 100)
                .previewLayout(.sizeThatFits)
            ZimFileCell(ZimFileCell_Previews.zimFile, prominent: .title)
                .preferredColorScheme(.dark)
                .padding()
                .frame(width: 300, height: 100)
                .previewLayout(.sizeThatFits)
        }
    }
}
