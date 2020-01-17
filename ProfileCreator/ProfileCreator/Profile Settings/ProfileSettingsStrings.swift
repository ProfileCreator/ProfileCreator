//
//  ProfileSettingsStrings.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    func placeholderString(forSubkey subkey: PayloadSubkey, isRequired: Bool, payloadIndex: Int) -> String? {
        if let valuePlaceholder = subkey.valuePlaceholder as? String {
            return valuePlaceholder
        } else if isRequired {
            return NSLocalizedString("Required", comment: "")
        } else if subkey.require == .push || subkey.conditionals.contains(where: { $0.require == .push }) {
            return NSLocalizedString("Set On Device", comment: "")
        }
        return nil
    }

    func titleString(forSubkey subkey: PayloadSubkey) -> String {
        var titleString: String
        if let title = subkey.title, !title.isEmpty {
            titleString = title
        } else {
            titleString = subkey.key
        }

        // Add Supervised
        if subkey.supervised {
            titleString += " (Supervised)"
        }

        // Add Platforms
        if
            let platforms = subkey.platformsManifest {
            let platformsString = PayloadUtility.string(fromPlatforms: platforms, separator: ",")
            titleString += " (\(platformsString))"
        }

        if
            let notPlatforms = subkey.platformsNotManifest,
            let payloadPlatforms = subkey.payload?.platforms.subtracting(notPlatforms) {
            let platformsString = PayloadUtility.string(fromPlatforms: payloadPlatforms, separator: ",")
            titleString += " (\(platformsString))"
        }

        return titleString
    }

    func attributedTitleKeyString(forSubkey subkey: PayloadSubkey, cellView: PayloadCellView) -> NSAttributedString {
        let title = subkey.key

        let titleFont = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular), weight: .bold)
        let attributedString = NSMutableAttributedString(string: title, attributes: [.foregroundColor: NSColor.systemBrown, .font: titleFont])

        let deprecatedColor = cellView.isEnabled ? NSColor.systemRed : NSColor.systemRed.withAlphaComponent(0.7)
        let deprecatedString = self.deprecatedString(forSubkey: subkey)
        cellView.deprecatedString = deprecatedString

        let attributedSubstring = NSMutableAttributedString(string: deprecatedString, attributes: [.font: titleFont])
        attributedSubstring.addAttribute(.foregroundColor, value: deprecatedColor, range: NSRange(location: 0, length: deprecatedString.count))

        attributedString.append(attributedSubstring)

        return attributedString
    }

    func deprecatedString(forSubkey subkey: PayloadSubkey) -> String {
        var deprecatedString = NSLocalizedString(" Deprecated", comment: "")
        if subkey.platformsDeprecated != .none, subkey.platforms != subkey.platformsDeprecated {
            deprecatedString += " (\(PayloadUtility.string(fromPlatforms: subkey.platformsDeprecated, separator: ", ")))"
        }
        return deprecatedString
    }

    func attributedTitleString(forSubkey subkey: PayloadSubkey, cellView: PayloadCellView) -> NSAttributedString {

        let title = self.titleString(forSubkey: subkey)
        let titleFont = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular), weight: .bold)

        let attributedString = NSMutableAttributedString(string: title, attributes: [.foregroundColor: NSColor.labelColor, .font: titleFont])

        let deprecatedColor = cellView.isEnabled ? NSColor.systemRed : NSColor.systemRed.withAlphaComponent(0.7)
        let deprecatedString = self.deprecatedString(forSubkey: subkey)
        cellView.deprecatedString = deprecatedString

        let attributedSubstring = NSMutableAttributedString(string: deprecatedString, attributes: [.font: titleFont])
        attributedSubstring.addAttribute(.foregroundColor, value: deprecatedColor, range: NSRange(location: 0, length: deprecatedString.count))

        attributedString.append(attributedSubstring)

        return attributedString
    }

    func descriptionString(forSubkey subkey: PayloadSubkey) -> String? {
        var descriptionString: String?
        if let description = subkey.description {
            descriptionString = description
        } else if let descriptionReference = subkey.descriptionReference, !descriptionReference.isEmpty {
            descriptionString = descriptionReference
        }

        return descriptionString
    }
}
