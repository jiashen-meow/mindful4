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

//    private static let fontName = "GloriaHallelujah"
    private static let fontName = "Schoolbell"

    // MARK: - Named sizes matching the app's type scale

    /// Large display text — titles, result screen headline.
    static var appTitle: Font {
        .custom(fontName, fixedSize: 28)
    }

    /// Section / page headings.
    static var appHeadline: Font {
        .custom(fontName, fixedSize: 20)
    }

    /// Body copy.
    static var appBody: Font {
        .custom(fontName, fixedSize: 18)
    }

    /// Secondary labels, captions.
    static var appCaption: Font {
        .custom(fontName, fixedSize: 15)
    }
    
    /// Third tier labels, captions.
    static var appLabel: Font {
        .custom(fontName, fixedSize: 12)
    }

    // MARK: - Arbitrary size helper

    /// Use when you need an exact size not covered by the named scale.
    static func app(size: CGFloat) -> Font {
        .custom(fontName, fixedSize: size)
    }
}

// MARK: - View modifier shorthand

extension Text {
    func appFont(size: CGFloat? = nil) -> Text {
        self.font(.app(size: size ?? 15)).tracking(1.0)
    }

    var appTitle: Text    { self.font(.appTitle).tracking(1.0) }
    var appHeadline: Text { self.font(.appHeadline).tracking(1.0) }
    var appBody: Text     { self.font(.appBody).tracking(1.0) }
    var appCaption: Text  { self.font(.appCaption).tracking(0.5) }
    var appLabel: Text  { self.font(.appLabel).tracking(0.5) }
}

// MARK: - App background color

extension Color {
    /// Warm off-white in light mode (#FAF6EE), dark brown in dark mode (#1B120D).
    /// Use this as the page background across all screens.
    static var appBackground: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0x1C / 255.0, green: 0x14 / 255.0, blue: 0x10 / 255.0, alpha: 1)
                : UIColor(red: 0xFA / 255.0, green: 0xF6 / 255.0, blue: 0xEE / 255.0, alpha: 1)
        })
    }
}
