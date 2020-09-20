//
//  ZimFileCell.swift
//  Kiwix
//
//  Created by Chris Li on 9/5/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct ZimFileCell: View {
    let id: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 36, height: 36)
                Image(systemName: "text.book.closed")
            }
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Row \(id)").font(.headline)
                    Text("file_name_looooooong.zim")
                        .font(.subheadline)
                }
                Divider()
                HStack {
                    Label("35.5 GB", systemImage: "internaldrive").font(.caption)
                    Spacer()
                    Label("3.5k articles", systemImage: "doc.text").font(.caption)
                    Spacer()
                    Label("2020-09-18", systemImage: "calendar").font(.caption)
                }
            }
        }
        .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
        .background(Color(UIColor.white))
        .cornerRadius(10)
    }
}

@available(iOS 14.0, *)
struct ZimFileCell_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
//            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
//                ForEach(1...100, id: \.self) {
//                    ZimFileCell(id: $0)
//                }
//            }
            LazyVStack(alignment: .leading) {
                ForEach(1...100, id: \.self) {
                    ZimFileCell(id: $0)
                }
            }
            .padding(.all, 10)
        }
        .background(Color(.systemGroupedBackground))
        .previewDevice(PreviewDevice(rawValue: "iPhone 11"))
    }
}
