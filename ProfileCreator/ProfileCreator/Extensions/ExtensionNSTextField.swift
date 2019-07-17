//
//  ExtensionNSTextField.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

extension NSTextField {
    func highlighSubstrings(for payload: PayloadSubkey) {
        var highlighted = false

        // Highlight formatting errors IMPORTANT: Must be first of the highlights
        if let formatString = payload.format, self.highlightSubstringsNotMatching(format: formatString) {
            highlighted = true
        }

        if let substitutionVariables = payload.substitutionVariables {
            if self.highlightSubstringsMatching(substitutionVariables: substitutionVariables) {
                highlighted = true
            }
            self.updateTrackingAreas()
        }

        if !highlighted {
            self.allowsEditingTextAttributes = false
            self.textColor = .labelColor
        }
    }

    private func highlightSubstringsMatching(substitutionVariables: [String: [String: String]]) -> Bool {
        guard let font = self.font, let payloadTextField = self as? PayloadTextField else { return false }

        // Reset
        payloadTextField.substitutionVariables.removeAll()

        do {
            let regex = try NSRegularExpression(pattern: substitutionVariables.keys.joined(separator: "|"), options: [])
            let regexMatches = regex.matches(in: self.stringValue, options: [], range: NSRange(location: 0, length: self.stringValue.count))

            if regexMatches.isEmpty { return false }

            let attributedString = NSMutableAttributedString(attributedString: self.attributedStringValue) //  NSMutableAttributedString(string: self.stringValue, attributes: [.foregroundColor: NSColor.labelColor, .font: font])
            self.textColor = nil
            for match in regexMatches {
                guard let substring = self.stringValue.substring(with: match.range) else {
                    Log.shared.error(message: "Failed to create substring at range: \(match.range) for string: \(self.stringValue)", category: String(describing: self))
                    continue
                }
                let attributedSubstring = NSMutableAttributedString(string: String(substring), attributes: [.font: font])
                attributedSubstring.addAttribute(.foregroundColor, value: NSColor.systemPurple, range: NSRange(location: 0, length: substring.count))

                if let substitutionVariable = substitutionVariables[String(substring)] {
                    payloadTextField.substitutionVariables[match.range] = [String(substring): substitutionVariable]
                }

                attributedString.replaceCharacters(in: match.range, with: attributedSubstring)
            }
            self.allowsEditingTextAttributes = true
            self.attributedStringValue = attributedString
            return true
        } catch {
            Log.shared.error(message: "Failed to create a regular expression from the substitutionVariables: \(substitutionVariables)", category: String(describing: self))
        }

        return false
    }

    private func highlightSubstringsNotMatching(format: String) -> Bool {
        guard let font = self.font else { return false }

        do {
            let regex = try NSRegularExpression(pattern: format, options: [])
            let regexMatches = regex.matches(in: self.stringValue, options: [], range: NSRange(location: 0, length: self.stringValue.count))
            let attributedString = NSMutableAttributedString(string: self.stringValue, attributes: [.foregroundColor: NSColor.systemRed, .font: font])
            self.textColor = nil
            for match in regexMatches {
                guard let substring = self.stringValue.substring(with: match.range) else {
                    Log.shared.error(message: "Failed to create substring at range: \(match.range) for string: \(self.stringValue)", category: String(describing: self))
                    continue
                }
                let attributedSubstring = NSMutableAttributedString(string: String(substring), attributes: [.font: font])
                attributedSubstring.addAttribute(.foregroundColor, value: NSColor.labelColor, range: NSRange(location: 0, length: substring.count))
                attributedString.replaceCharacters(in: match.range, with: attributedSubstring)
            }
            self.allowsEditingTextAttributes = true
            self.attributedStringValue = attributedString
            return true
        } catch {
            Log.shared.error(message: "Failed to create a regular expression from the string: \(format)", category: String(describing: self))
        }

        return false
    }
}

extension String {
    func substring(with nsrange: NSRange) -> Substring? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return self[range]
    }
}
