//
//  HexColorTransformer.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import AppKit.NSColor
import Foundation

// https://github.com/pirate-test-runscope-prod-1/cotEditorMac/blob/fcdb37b62592f9baef0db293f1dbda3f2998d408/CotEditor/Sources/HexColorTransformer.swift
class HexColorTransformer: ValueTransformer {

    // MARK: Public Properties

    static let name = NSValueTransformerName("HexColorTransformer")

    // MARK: -
    // MARK: Value Transformer Methods

    /// Class of transformed value
    override class func transformedValueClass() -> AnyClass {

        NSString.self
    }

    /// Can reverse transformeation?
    override class func allowsReverseTransformation() -> Bool {

        true
    }

    /// From color code hex to NSColor (String -> NSColor)
    override func transformedValue(_ value: Any?) -> Any? {

        guard let code = value as? String else { return nil }

        var type: ColorCodeType?
        let color = NSColor(colorCode: code, type: &type)

        guard type == .hex || type == .shortHex else { return nil }

        return color
    }

    /// From NSColor to hex color code string (NSColor -> String)
    override func reverseTransformedValue(_ value: Any?) -> Any? {

        let color = value as? NSColor ?? .labelColor

        let sanitizedColor = color.usingColorSpace(.genericRGB)

        return sanitizedColor?.colorCode(type: .hex)
    }
}
