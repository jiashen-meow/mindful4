//
//  Font+App.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Convenience API for the Gloria Hallelujah custom font.
//
//  Setup steps (one-time, done in Xcode):
//  ─────────────────────────────────────────────────────────────────────────
//  1. Download GloriaHallelujah-Regular.ttf from Google Fonts:
//     https://fonts.google.com/specimen/Gloria+Hallelujah
//
//  2. Drag the .ttf file into Xcode. In the "Add to targets" dialog make
//     sure BOTH the main app target (mindful3) AND the widget target
//     (mindful3Widget) are checked.
//
//  3. Main app Info.plist — add the key "Fonts provided by application"
//     (UIAppFonts) as an Array and add the item:
//         GloriaHallelujah-Regular.ttf
//
//  4. Widget extension Info.plist — add the same key + value.
//     (Each extension that uses the font needs its own declaration.)
//
//  After those steps every call to Font.app(...) or .appFont(...) will
//  use Gloria Hallelujah automatically.
//  ─────────────────────────────────────────────────────────────────────────

import SwiftUI

extension Font {

    private static let fontName = "GloriaHallelujah"

    // MARK: - Named sizes matching the app's type scale

    /// Large display text — titles, result screen headline.
    static var appTitle: Font {
        .custom(fontName, fixedSize: 28)
    }

    /// Section / page headings.
    static var appHeadline: Font {
        .custom(fontName, fixedSize: 17)
    }

    /// Body copy.
    static var appBody: Font {
        .custom(fontName, fixedSize: 15)
    }

    /// Secondary labels, captions.
    static var appCaption: Font {
        .custom(fontName, fixedSize: 12)
    }

    // MARK: - Arbitrary size helper

    /// Use when you need an exact size not covered by the named scale.
    static func app(size: CGFloat) -> Font {
        .custom(fontName, fixedSize: size)
    }
}

// MARK: - View modifier shorthand

extension View {
    /// Applies Gloria Hallelujah at the given size (defaults to body).
    func appFont(size: CGFloat? = nil) -> some View {
        self.font(.app(size: size ?? 15))
    }
}
