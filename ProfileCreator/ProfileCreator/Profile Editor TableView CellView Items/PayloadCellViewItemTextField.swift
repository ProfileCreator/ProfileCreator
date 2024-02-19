//
//  PayloadCellViewItems.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class EditorTextField {

    class func title(profile: Profile,
                     subkey: PayloadSubkey,
                     indent: Int,
                     constraints: inout [NSLayoutConstraint],
                     cellView: PayloadCellView) -> NSTextField? {

        let title = profile.settings.titleString(forSubkey: subkey)
        guard !title.isEmpty else {
            Log.shared.debug(message: "Subkey: \(subkey.keyPath) has no title", category: String(describing: self))
            return nil
        }

        // -------------------------------------------------------------------------
        //  Calculate Indent
        // -------------------------------------------------------------------------
        let indentValue: CGFloat = 8.0 + (16.0 * CGFloat(indent))

        // -------------------------------------------------------------------------
        //  Create and setup text field
        // -------------------------------------------------------------------------
        let showKeyAsTitle = UserDefaults.standard.bool(forKey: PreferenceKey.payloadEditorShowKeyAsTitle)
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byWordWrapping
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular), weight: .bold)
        textField.textColor = cellView.isExcludedArray == nil ? .labelColor : .secondaryLabelColor
        textField.stringValue = showKeyAsTitle ? subkey.key : title
        textField.toolTip = showKeyAsTitle ? title : subkey.key
        textField.textColor = showKeyAsTitle ? .systemBrown : .labelColor
        textField.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth - (indentValue + 8.0)
        if cellView.isEnabled, cellView.isExcludedArray != nil, let textColor = textField.textColor {
            textField.textColor = textColor.withAlphaComponent(0.3)
        }

        if subkey.platformsDeprecated != .none || subkey.appDeprecated != nil {
            textField.attributedStringValue = profile.settings.attributedTitleString(forSubkey: subkey, cellView: cellView)
        }

        // ---------------------------------------------------------------------
        //  Setup GestureRecognizer
        // ---------------------------------------------------------------------
        let gesture = NSClickGestureRecognizer()
        gesture.numberOfClicksRequired = 1
        gesture.target = cellView
        gesture.action = #selector(cellView.toggleTitle(sender:))
        textField.addGestureRecognizer(gesture)

        // -------------------------------------------------------------------------
        //  Add text field to cell view
        // -------------------------------------------------------------------------
        cellView.addSubview(textField)

        // -------------------------------------------------------------------------
        //  Setup Layout Constraings for text field
        // -------------------------------------------------------------------------

        // Top
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: cellView,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: 3.0))

        cellView.updateHeight(3.0 + textField.intrinsicContentSize.height)

        // -------------------------------------------------------------------------
        //  Add NSLayoutConstraints
        // -------------------------------------------------------------------------
        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: cellView,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: indentValue))

        // Trailing
        constraints.append(NSLayoutConstraint(item: cellView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textField,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))

        return textField
    }

    class func description(profile: Profile,
                           subkey: PayloadSubkey,
                           indent: Int,
                           constraints: inout [NSLayoutConstraint],
                           cellView: PayloadCellView) -> NSTextField? {

        guard let description = profile.settings.descriptionString(forSubkey: subkey), !description.isEmpty else {
            return nil
        }

        // -------------------------------------------------------------------------
        //  Calculate Indent
        // -------------------------------------------------------------------------
        let indentValue: CGFloat = 8.0 + (16.0 * CGFloat(indent))

        // ---------------------------------------------------------------------
        //  Create and setup TextField
        // ---------------------------------------------------------------------
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byWordWrapping
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = true
        textField.textColor = .secondaryLabelColor
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular))
        textField.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth - (indentValue + 8.0)
        textField.stringValue = description
        textField.toolTip = subkey.key
        if cellView.isEnabled, cellView.isExcludedArray != nil, let textColor = textField.textColor {
            textField.textColor = textColor.withAlphaComponent(0.4)
        }

        // ---------------------------------------------------------------------
        //  Add text field to cell view
        // ---------------------------------------------------------------------
        cellView.addSubview(textField)

        // ---------------------------------------------------------------------
        //  Setup Layout Constraings for TextField
        // ---------------------------------------------------------------------
        if cellView.textFieldTitle != nil {

            // Top
            constraints.append(NSLayoutConstraint(item: textField,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: cellView.textFieldTitle,
                                                  attribute: .bottom,
                                                  multiplier: 1.0,
                                                  constant: 2.0))

            cellView.updateHeight(2.0 + textField.intrinsicContentSize.height)
        } else {

            // Top
            constraints.append(NSLayoutConstraint(item: textField,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: cellView,
                                                  attribute: .top,
                                                  multiplier: 1.0,
                                                  constant: 8.0))

            cellView.updateHeight(8.0 + textField.intrinsicContentSize.height)
        }

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: cellView,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: indentValue))

        // Trailing
        constraints.append(NSLayoutConstraint(item: cellView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textField,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))

        return textField
    }

    class func note(note: String,
                    indent: Int,
                    cellView: PayloadCellView) -> NSTextField {

        // ---------------------------------------------------------------------
        //  Create and setup TextField
        // ---------------------------------------------------------------------
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byWordWrapping
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = true
        textField.textColor = .secondaryLabelColor
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular))
        textField.stringValue = note

        textField.setContentCompressionResistancePriority(.required, for: .vertical)
        textField.setContentHuggingPriority(.required, for: .vertical)

        return textField
    }

    class func appRestrictions(forSubkey subkey: PayloadManagedPreferenceSubkey) -> String? {
        var string = ""

        if let appMin = subkey.appMin {
            string += appMin
        }

        if let appMax = subkey.appMax {
            if !string.isEmpty {
                string += "-" + appMax
            } else {
                string += "<=" + appMax
            }
        } else if !string.isEmpty {
            string += "+"
        }

        return !string.isEmpty ? string : nil
    }

    class func macOSRestrictions(forSubkey subkey: PayloadSubkey) -> String? {
        var string = ""

        if let macOSMin = subkey.macOSMin {
            string += macOSMin
        }

        if let macOSMax = subkey.macOSMax {
            if !string.isEmpty {
                string += "-" + macOSMax
            } else {
                string += "<=" + macOSMax
            }
        } else if !string.isEmpty {
            string += "+"
        }

        return !string.isEmpty ? string : nil
    }

    class func iOSRestrictions(forSubkey subkey: PayloadSubkey) -> String? {
        var string = ""

        if let iOSMin = subkey.iOSMin {
            string += iOSMin
        }

        if let iOSMax = subkey.iOSMax {
            if !string.isEmpty {
                string += "-" + iOSMax
            } else {
                string += "<=" + iOSMax
            }
        } else if !string.isEmpty {
            string += "+"
        }

        return !string.isEmpty ? string : nil
    }

    class func tvOSRestrictions(forSubkey subkey: PayloadSubkey) -> String? {
        var string = ""

        if let tvOSMin = subkey.tvOSMin {
            string += tvOSMin
        }

        if let tvOSMax = subkey.tvOSMax {
            if !string.isEmpty {
                string += "-" + tvOSMax
            } else {
                string += "<=" + tvOSMax
            }
        } else if !string.isEmpty {
            string += "+"
        }

        return !string.isEmpty ? string : nil
    }

    class func footer(profile: Profile,
                      subkey: PayloadSubkey,
                      indent: Int,
                      constraints: inout [NSLayoutConstraint],
                      cellView: PayloadCellView) -> NSTextField? {

        // OS RESTRICTIONS

        var footerString = ""
        if
            let managedPreferenceSubkey = subkey as? PayloadManagedPreferenceSubkey,
            let appRestriction = self.appRestrictions(forSubkey: managedPreferenceSubkey) {
            footerString += "Version: " + appRestriction
        }

        if let macOSRestriction = self.macOSRestrictions(forSubkey: subkey) {
            if !footerString.isEmpty {
                footerString += ", "
            }
            footerString += "macOS: " + macOSRestriction
        }

        if let iOSRestriction = self.iOSRestrictions(forSubkey: subkey) {
            if !footerString.isEmpty {
                footerString += ", "
            }
            footerString += "iOS: " + iOSRestriction
        }

        if let tvOSRestriction = self.tvOSRestrictions(forSubkey: subkey) {
            if !footerString.isEmpty {
                footerString += ", "
            }
            footerString += "tvOS: " + tvOSRestriction
        }

        // TARGETS

        if let targets = subkey.targets, targets != subkey.payload?.targets {
            if !footerString.isEmpty {
                footerString += " | "
            }
            footerString += "Scope: " + PayloadUtility.string(fromTargets: targets, separator: ",")
        }

        // ---------------------------------------------------------------------
        //  Create and setup TextField
        // ---------------------------------------------------------------------
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byWordWrapping
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.textColor = .tertiaryLabelColor
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .small))
        textField.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
        textField.toolTip = subkey.key
        if cellView.isEnabled, cellView.isExcludedArray != nil, let textColor = textField.textColor {
            textField.textColor = textColor.withAlphaComponent(0.4)
        }

        if footerString.isEmpty { return nil }

        // ---------------------------------------------------------------------
        //  Add text field to cell view
        // ---------------------------------------------------------------------
        cellView.addSubview(textField)

        // ---------------------------------------------------------------------
        //  Setup Layout Constraings for TextField
        // ---------------------------------------------------------------------
        let indentValue: CGFloat = 8.0 + (16.0 * CGFloat(indent))

        // Leading
        let leadingView = cellView.imageViewSubstitutionVariables ?? cellView.imageViewDocumentation ?? cellView
        if leadingView != cellView {
            footerString = "| " + footerString
        }

        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: leadingView,
                                              attribute: leadingView != cellView ? .trailing : .leading,
                                              multiplier: 1.0,
                                              constant: leadingView != cellView ? 4.0 : indentValue))

        // Trailing
        constraints.append(NSLayoutConstraint(item: cellView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textField,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))

        textField.stringValue = footerString

        return textField
    }

    class func message(profile: Profile,
                       subkey: PayloadSubkey,
                       payloadIndex: Int,
                       indent: Int,
                       constraints: inout [NSLayoutConstraint],
                       cellView: PayloadCellView) -> NSTextField? {

        var message = ""
        if
            let sensitiveMessage = subkey.sensitiveMessage,
            profile.settings.isEnabled(subkey, onlyByUser: false, ignoreConditionals: false, payloadIndex: payloadIndex) {
            if !message.isEmpty { message += "\n" }
            message += sensitiveMessage
        }

        if cellView.isEnabled, let excludedArray = cellView.isExcludedArray {
            if !message.isEmpty { message += "\n" }
            message += NSLocalizedString("This key will not be included in the profile because of exclusion rules", comment: "") + ":"
            for excludedDict in excludedArray {
                // Should make this a struct? to not have to do this dance
                guard
                    let key = excludedDict["key"] as? String,
                    let targetKeyPath = excludedDict["target"] as? String else { continue }

                switch key {
                case ManifestKey.isPresent.rawValue:
                    guard let value = excludedDict["value"] as? Bool else { continue }
                    if value {
                        message.append("\n  • \(targetKeyPath) " + NSLocalizedString("is included", comment: ""))
                    } else {
                        message.append("\n  • \(targetKeyPath) " + NSLocalizedString("is not included", comment: "") )
                    }
                case ManifestKey.distribution.rawValue:
                    message.append("\n  • " + NSLocalizedString("Distribution method is", comment: "") + ": \(PayloadUtility.string(fromDistribution: profile.settings.distributionMethod, separator: ","))")
                case ManifestKey.containsAny.rawValue,
                     ManifestKey.notContainsAny.rawValue,
                     ManifestKey.rangeList.rawValue,
                     ManifestKey.notRangeList.rawValue:
                    if let value = excludedDict["value"] {
                        message.append("\n  • \(targetKeyPath) " + NSLocalizedString("has value", comment: "") + ": \(value)")
                    } else {
                        message.append("\n  • \(targetKeyPath) " + NSLocalizedString("current value", comment: ""))
                    }
                case ManifestKey.isEmpty.rawValue:
                    if let keyValue = excludedDict["keyValue"] as? Bool, keyValue {
                        message.append("\n  • \(targetKeyPath) " + NSLocalizedString("is empty", comment: ""))
                    } else {
                        message.append("\n  • \(targetKeyPath) " + NSLocalizedString("is not empty", comment: ""))
                    }
                default:
                    message.append("\n  • Unhandled exclusion key: \(key) for target: \(targetKeyPath)")
                    Log.shared.error(message: "Unhandled key: \(key) in exclude dictionary: \(excludedDict)", category: String(describing: self))
                }
            }
        }

        if message.isEmpty { return nil }

        // -------------------------------------------------------------------------
        //  Calculate Indent
        // -------------------------------------------------------------------------
        let indentValue: CGFloat = 8.0 + (16.0 * CGFloat(indent))

        // ---------------------------------------------------------------------
        //  Create and setup TextField
        // ---------------------------------------------------------------------
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byWordWrapping
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.textColor = .systemOrange
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular))
        textField.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth - (indentValue + 8.0)
        textField.stringValue = message

        // ---------------------------------------------------------------------
        //  Add text field to cell view
        // ---------------------------------------------------------------------
        cellView.addSubview(textField)

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: cellView,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: indentValue))

        // Trailing
        constraints.append(NSLayoutConstraint(item: cellView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textField,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))

        return textField
    }

    class func input(defaultString: String?,
                     placeholderString: String?,
                     cellView: PayloadCellView) -> PayloadTextField {

        // -------------------------------------------------------------------------
        //  Create and setup text field
        // -------------------------------------------------------------------------
        let textField = PayloadTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byTruncatingTail
        textField.isBordered = true
        textField.isBezeled = true
        textField.bezelStyle = .squareBezel
        textField.drawsBackground = false
        textField.isEditable = true
        textField.isSelectable = true
        textField.textColor = .labelColor
        textField.backgroundColor = .controlBackgroundColor
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular))
        textField.stringValue = defaultString ?? ""
        textField.placeholderString = placeholderString ?? ""
        // textField.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
        textField.allowsEditingTextAttributes = false
        if cellView is NSTextFieldDelegate { textField.delegate = cellView as? NSTextFieldDelegate }

        // -------------------------------------------------------------------------
        //  Add text field to cell view
        // -------------------------------------------------------------------------
        cellView.addSubview(textField)

        return textField
    }

    class func label(string: String?,
                     fontWeight: NSFont.Weight?,
                     cellView: ProfileCreatorCellView) -> NSTextField {

        // -------------------------------------------------------------------------
        //  Create and setup text field
        // -------------------------------------------------------------------------
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byWordWrapping
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.textColor = .labelColor
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular), weight: fontWeight ?? .bold)
        // textField.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
        textField.stringValue = string ?? ""

        // -------------------------------------------------------------------------
        //  Add text field to cell view
        // -------------------------------------------------------------------------
        cellView.addSubview(textField)

        return textField
    }

    class func label(string: String?,
                     fontWeight: NSFont.Weight?,
                     leadingItem: NSView?,
                     leadingConstant: CGFloat?,
                     trailingItem: NSView?,
                     constraints: inout [NSLayoutConstraint],
                     cellView: ProfileCreatorCellView) -> NSTextField {

        // -------------------------------------------------------------------------
        //  Create and setup text field
        // -------------------------------------------------------------------------
        let textField = self.label(string: string, fontWeight: fontWeight, cellView: cellView)
        /*
         textField.translatesAutoresizingMaskIntoConstraints = false
         textField.lineBreakMode = .byWordWrapping
         textField.isBordered = false
         textField.isBezeled = false
         textField.drawsBackground = false
         textField.isEditable = false
         textField.isSelectable = false
         textField.textColor = .labelColor
         textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular), weight: fontWeight ?? .bold)
         textField.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
         textField.stringValue = string ?? ""
         
         // -------------------------------------------------------------------------
         //  Add text field to cell view
         // -------------------------------------------------------------------------
         cellView.addSubview(textField)
         */
        // -------------------------------------------------------------------------
        //  Setup Layout Constraings for text field
        // -------------------------------------------------------------------------

        if let leadingView = leadingItem {

            let leadingConstantValue: CGFloat
            if leadingView is NSPopUpButton, leadingView is NSTextField {
                leadingConstantValue = 6.0
            } else {
                leadingConstantValue = 2.0
            }

            // Leading
            constraints.append(NSLayoutConstraint(item: textField,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: leadingView,
                                                  attribute: .trailing,
                                                  multiplier: 1.0,
                                                  constant: leadingConstant ?? leadingConstantValue))

            // Baseline
            constraints.append(NSLayoutConstraint(item: textField,
                                                  attribute: .firstBaseline,
                                                  relatedBy: .equal,
                                                  toItem: leadingView,
                                                  attribute: .firstBaseline,
                                                  multiplier: 1.0,
                                                  constant: 0.0))
        } else {

            // Leading
            constraints.append(NSLayoutConstraint(item: textField,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: cellView,
                                                  attribute: .leading,
                                                  multiplier: 1.0,
                                                  constant: 8.0))
        }

        if let trailingView = trailingItem {

            let trailingConstant: CGFloat
            if trailingView is NSPopUpButton {
                trailingConstant = 6.0
            } else {
                trailingConstant = 2.0
            }

            // Trailing
            constraints.append(NSLayoutConstraint(item: trailingView,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: textField,
                                                  attribute: .trailing,
                                                  multiplier: 1.0,
                                                  constant: trailingConstant))

            // Baseline
            constraints.append(NSLayoutConstraint(item: textField,
                                                  attribute: .firstBaseline,
                                                  relatedBy: .equal,
                                                  toItem: trailingView,
                                                  attribute: .firstBaseline,
                                                  multiplier: 1.0,
                                                  constant: 0.0))
        } else {

            // Trailing
            constraints.append(NSLayoutConstraint(item: cellView,
                                                  attribute: .trailing,
                                                  relatedBy: .equal,
                                                  toItem: textField,
                                                  attribute: .trailing,
                                                  multiplier: 1.0,
                                                  constant: 8.0))
        }

        return textField

    }
}
