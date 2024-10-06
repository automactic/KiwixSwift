// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import SwiftUI

/// Helper struct to calculate sizes and positions related to Brand logo
/// The logo:
/// - it should not be wider than half of the screen or 300
/// - it should not be taller than half of the screen
/// - it should make vertical space for one row of buttons below it including spaces
/// This is especially important on iPhone in landscape mode (vertical compact mode)
/// The 2 buttons (open file / fetch catalog):
/// - they are displayed in 2 rows, matching the width of the logo
/// - on iPhone landscape they are displayed in 1 row, matching the full width - spacing
/// The loading messages:
/// - they are vertically aligned into the center place, where the buttons will be displayed
/// Error message:
/// - displayed below the buttons, with equal vertical spacing
/// - on iPhone in landscape, it is displayed above the logo (due to lack of space below the logo)
///
struct LogoCalc {

    private enum Const {
        static let maxLogoWidth: CGFloat = 300
        ///   44 height for the row of buttons,
        /// + 20 spacing above and below (x2)
        /// + 32 for bottom bar
        static let minButtonSpace: CGFloat = oneRowOfButtonsHeight + spacing * 2 + 32 // 116
        static let oneRowOfButtonsHeight: CGFloat = 44
        static let twoRowsOfButtonsHeight: CGFloat = 96
        static let spacing: CGFloat = 20
        static let errorMsgHeight: CGFloat = 22
    }

    private let geometry: CGSize
    private let originalImage: CGSize
    private let isCompact: Bool

    init(geometry: CGSize, originalImageSize: CGSize, isVerticalCompact: Bool) {
        self.geometry = geometry
        self.originalImage = originalImageSize
        self.isCompact = isVerticalCompact
    }

    var logoSize: CGSize {
        let height = min(geometry.height * 0.5,
                         // 2 * 116 = 232 this is used on the splash screen as well
                         geometry.height - 2 * Const.minButtonSpace)
        let width = min(geometry.width * 0.5, Const.maxLogoWidth)
        let size = CGSize(width: width, height: height)
        // we need to "fit" the original image size into the size we got
        // in order to get back the actually displayed size of the fitted image.
        // This way we can place the buttons right below it
        // and not below the frame in was fitted into
        // |----------------|
        // |[ actual height]|
        // |----------------| <- the frame height
        return Resizer.fit(originalImage, into: size)
    }

    var errorTextCenterY: CGFloat {
        if isCompact { // put the error to the top of the screen
            return (geometry.height - logoSize.height - Const.errorMsgHeight) * 0.5
            - Const.spacing
        } else {
            return (geometry.height + logoSize.height + Const.errorMsgHeight) * 0.5
            + Const.spacing + Const.twoRowsOfButtonsHeight + Const.spacing
        }
    }

    var buttonCenterY: CGFloat {
        if isCompact { // one row of buttons (HStack)
            return (geometry.height + logoSize.height + Const.oneRowOfButtonsHeight) * 0.5 + Const.spacing
        } else { // two row of buttons (VStack)
            return (geometry.height + logoSize.height + Const.twoRowsOfButtonsHeight) * 0.5 + Const.spacing
        }
    }

    var buttonsWidth: CGFloat {
        if isCompact {
            return geometry.width - 2 * Const.spacing
        } else {
            return logoSize.width // 2 column buttons, match the logo width
        }
    }
}

struct LogoView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    var body: some View {
        GeometryReader { geometry in
            let logoCalc = LogoCalc(geometry: geometry.size,
                                    originalImageSize: Brand.loadingLogoSize,
                                    isVerticalCompact: verticalSizeClass == .compact)
            let logoSize = logoCalc.logoSize
            Image(Brand.loadingLogoImage)
                .resizable()
                .scaledToFit()
                .frame(width: logoSize.width, height: logoSize.height)
                .position(
                    x: geometry.size.width * 0.5,
                    y: geometry.size.height * 0.5
                )
            }.ignoresSafeArea()
    }
}

struct LoadingMessageView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let message: String
    var body: some View {
        GeometryReader { geometry in
            let logoCalc = LogoCalc(geometry: geometry.size,
                                    originalImageSize: Brand.loadingLogoSize,
                                    isVerticalCompact: verticalSizeClass == .compact)
            Text(message)
                .position(
                    x: geometry.size.width * 0.5,
                    // we want the loading message vertically centered to the buttons
                    // that will appear
                    y: logoCalc.buttonCenterY
                )
        }
    }
}

struct LoadingProgressView: View {
    var body: some View {
        GeometryReader { geometry in
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.primary)
                .frame(
                    width: geometry.size.width * 0.618,
                    height: geometry.size.height * 0.191
                )
                .position(
                    x: geometry.size.width * 0.5,
                    y: geometry.size.height * 0.809
                )
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            LogoView()
            LoadingMessageView(message: "welcome.loading.data.text".localized)
        }.ignoresSafeArea()
    }
}

#Preview {
    LoadingView()
}
