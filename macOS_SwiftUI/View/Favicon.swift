//
//  Favicon.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 1/2/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Favicon: View {
    let category: Category
    let imageData: Data?
    let imageURL: URL?
    
    var body: some View {
        image
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(2)
            .padding(1)
            .background(.white, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
            .task {
                guard let imageURL = imageURL else { return }
                try? await Database.shared.saveImageData(url: imageURL)
            }
    }
    
    @ViewBuilder
    var image: some View {
        if let data = imageData, #available(macOS 12, *), let image = NSImage(data: data) {
            Image(nsImage: image).resizable()
        } else {
            AsyncImage(url: imageURL) { image in
                image.resizable()
            } placeholder: {
                Image("Wikipedia").resizable()
            }
        }
    }
}

struct Favicon_Previews: PreviewProvider {
    static var previews: some View {
        Favicon(
            category: .wikipedia,
            imageData: nil,
            imageURL: URL(
                string: "https://library.kiwix.org/meta?name=favicon&content=wikipedia_en_climate_change_maxi_2021-12"
            )!
        ).frame(width: 200, height: 200).scaleEffect(5)
    }
}
