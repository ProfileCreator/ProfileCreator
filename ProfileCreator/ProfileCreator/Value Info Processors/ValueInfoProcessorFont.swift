//
//  ValueInfoProcessorFont.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

class ValueInfoProcessorFont: ValueInfoProcessor {

    // MARK: -
    // MARK: Intialization

    override init() {
        super.init(withIdentifier: "font")
    }

    override func valueInfo(forData data: Data) -> ValueInfo? {

        var valueInfo = ValueInfo()
        var fontInformation: FontInformation

        // Get FontInfo
        do {
            guard let fontInfo = try FontInformation(data: data) else {
                Log.shared.error(message: "Failed to create font information from passed data", category: String(describing: self))
                return nil
            }
            fontInformation = fontInfo
        } catch {
            Log.shared.error(message: "Failed to create font information from passed data with error: \(error)", category: String(describing: self))
            return nil
        }

        // Look for both language types to search across macintosh(.english), microsoft(.en_us) and unicode font descriptions.
        let fontDescriptions = fontInformation.descriptions(forLanguages: [.english, .en_us])

        let fontDescription: FontDescription
        if let unicode = fontDescriptions.first(where: { $0.platformIdentifier == .unicode }) {
            fontDescription = unicode
        } else if let macintosh = fontDescriptions.first(where: { $0.platformIdentifier == .macintosh }) {
            fontDescription = macintosh
        } else if let microsoft = fontDescriptions.first(where: { $0.platformIdentifier == .microsoft }) {
            fontDescription = microsoft
        } else {
            return nil
        }

        // Title
        if let fontName = fontDescription.fullName ?? fontDescription.postScriptName {
            valueInfo.title = fontName
        } else {
            valueInfo.title = NSLocalizedString("Unknown Font", comment: "")
        }

        // Top
        valueInfo.topLabel = NSLocalizedString("Format", comment: "")
        valueInfo.topContent = fontInformation.formatString

        // Center
        valueInfo.centerLabel = NSLocalizedString("Version", comment: "")
        valueInfo.centerContent = fontDescription.version ?? "Unknown"

        // Bottom
        if let manufacturer = fontDescription.manufacturer {
            valueInfo.bottomLabel = NSLocalizedString("Manufacturer", comment: "")
            valueInfo.bottomContent = manufacturer
        } else if let designer = fontDescription.designer {
            valueInfo.bottomLabel = NSLocalizedString("Designer", comment: "")
            valueInfo.bottomContent = designer
        } else if let copyright = fontDescription.copyright {
            valueInfo.bottomLabel = NSLocalizedString("Copyright", comment: "")
            valueInfo.bottomContent = copyright
        }

        // Icon
        valueInfo.icon = NSWorkspace.shared.icon(forFileType: fontInformation.uti as String)

        return valueInfo
    }

}
