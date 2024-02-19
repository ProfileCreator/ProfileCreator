//
//  PreferencesViewElements.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

public func addSeparator(toView: NSView,
                         lastSubview: NSView?,
                         height: inout CGFloat,
                         topIndent: CGFloat?,
                         constraints: inout [NSLayoutConstraint],
                         sender: Any? = nil) -> NSView? {

    // ---------------------------------------------------------------------
    //  Create and add vertical separator
    // ---------------------------------------------------------------------
    let separator = NSBox(frame: NSRect(x: 250.0, y: 15.0, width: kPreferencesWindowWidth - (20.0 * 2), height: 250.0))
    separator.translatesAutoresizingMaskIntoConstraints = false
    separator.boxType = .separator
    toView.addSubview(separator)

    // ---------------------------------------------------------------------
    //  Add Constraints
    // ---------------------------------------------------------------------

    // Top
    var constantTop: CGFloat
    if let topIndentValue = topIndent {
        constantTop = topIndentValue
    } else if sender is ProfileExportAccessoryView {
        constantTop = 6.0
    } else {
        constantTop = 8.0
    }
    constraints.append(NSLayoutConstraint(item: separator,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: lastSubview ?? toView,
                                          attribute: (lastSubview != nil) ? .bottom : .top,
                                          multiplier: 1,
                                          constant: constantTop))

    // Leading
    constraints.append(NSLayoutConstraint(item: separator,
                                          attribute: .leading,
                                          relatedBy: .equal,
                                          toItem: toView,
                                          attribute: .leading,
                                          multiplier: 1,
                                          constant: 20.0))

    // Trailing
    constraints.append(NSLayoutConstraint(item: toView,
                                          attribute: .trailing,
                                          relatedBy: .equal,
                                          toItem: separator,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 20.0))

    // ---------------------------------------------------------------------
    //  Update height value
    // ---------------------------------------------------------------------
    height += constantTop + separator.intrinsicContentSize.height

    return separator

}

public func addHeader(title: String,
                      controlSize: NSControl.ControlSize = .regular,
                      withSeparator: Bool,
                      textFieldTitle: NSTextField = NSTextField(),
                      toView: NSView,
                      lastSubview: NSView?,
                      height: inout CGFloat,
                      constraints: inout [NSLayoutConstraint],
                      sender: Any? = nil) -> NSView? {

    // -------------------------------------------------------------------------
    //  Create and add TextField title
    // -------------------------------------------------------------------------
    textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
    textFieldTitle.lineBreakMode = .byTruncatingTail
    textFieldTitle.isBordered = false
    textFieldTitle.isBezeled = false
    textFieldTitle.drawsBackground = false
    textFieldTitle.isEditable = false
    textFieldTitle.isSelectable = false
    textFieldTitle.textColor = .labelColor
    if sender is ProfileExportAccessoryView {
        textFieldTitle.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: controlSize), weight: .bold)
    }
    textFieldTitle.alignment = .left
    textFieldTitle.stringValue = title
    textFieldTitle.controlSize = controlSize
    toView.addSubview(textFieldTitle)

    // -------------------------------------------------------------------------
    //  Add Constraints
    // -------------------------------------------------------------------------
    // Top
    var constantTop: CGFloat = 20.0
    if sender is ProfileExportAccessoryView {
        constantTop = 10.0
    }
    constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: lastSubview ?? toView,
                                          attribute: (lastSubview != nil) ? .bottom : .top,
                                          multiplier: 1,
                                          constant: constantTop))

    // Leading
    // FIXME: Update functions to remove hardcoded class checks
    // All of these hardcoded things is mostly to get things done faster, need to revisit to actually check all the custom needs and update the functions accordingly
    if !(sender is ProfileExportAccessoryView) {
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: toView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 20.0))
    }

    // Trailing
    constraints.append(NSLayoutConstraint(item: toView,
                                          attribute: .trailing,
                                          relatedBy: .equal,
                                          toItem: textFieldTitle,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 20.0))

    // -------------------------------------------------------------------------
    //  Update height value
    // -------------------------------------------------------------------------
    height += 20.0 + textFieldTitle.intrinsicContentSize.height

    if withSeparator {

        // ---------------------------------------------------------------------
        //  Create and add vertical separator
        // ---------------------------------------------------------------------
        let separator = NSBox(frame: NSRect(x: 250.0, y: 15.0, width: kPreferencesWindowWidth - (20.0 * 2), height: 250.0))
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.boxType = .separator
        toView.addSubview(separator)

        // ---------------------------------------------------------------------
        //  Add Constraints
        // ---------------------------------------------------------------------

        // Top
        constantTop = 8.0
        if sender is ProfileExportAccessoryView {
            constantTop = 6.0
        }
        constraints.append(NSLayoutConstraint(item: separator,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: textFieldTitle,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: constantTop))

        // Leading

        if sender is ProfileExportAccessoryView {
            constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: separator,
                                                  attribute: .leading,
                                                  multiplier: 1,
                                                  constant: 0.0))
        } else {
            constraints.append(NSLayoutConstraint(item: separator,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: toView,
                                                  attribute: .leading,
                                                  multiplier: 1,
                                                  constant: 20.0))
        }

        // Trailing
        constraints.append(NSLayoutConstraint(item: toView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: separator,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 20.0))

        // ---------------------------------------------------------------------
        //  Update height value
        // ---------------------------------------------------------------------
        height += 8.0 + separator.intrinsicContentSize.height

        return separator
    } else {
        return textFieldTitle
    }
}

func setupLabel(string: String?, controlSize: NSControl.ControlSize = .regular, toView: NSView, indent: CGFloat, constraints: inout [NSLayoutConstraint]) -> NSTextField? {

    guard var labelString = string else { return nil }

    if !labelString.hasSuffix(":") {
        labelString.append(":")
    }

    // -------------------------------------------------------------------------
    //  Create and add TextField Label
    // -------------------------------------------------------------------------
    let textFieldLabel = NSTextField()
    textFieldLabel.translatesAutoresizingMaskIntoConstraints = false
    textFieldLabel.lineBreakMode = .byTruncatingTail
    textFieldLabel.isBordered = false
    textFieldLabel.isBezeled = false
    textFieldLabel.drawsBackground = false
    textFieldLabel.isEditable = false
    textFieldLabel.isSelectable = true
    textFieldLabel.textColor = .labelColor
    textFieldLabel.alignment = .right
    textFieldLabel.stringValue = labelString
    textFieldLabel.controlSize = controlSize
    textFieldLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    toView.addSubview(textFieldLabel)

    // Leading
    constraints.append(NSLayoutConstraint(item: textFieldLabel,
                                          attribute: .leading,
                                          relatedBy: .equal,
                                          toItem: toView,
                                          attribute: .leading,
                                          multiplier: 1,
                                          constant: indent))

    return textFieldLabel
}

public func addColorWell(label: String?,
                         controlSize: NSControl.ControlSize = .regular,
                         bindTo: Any?,
                         bindKeyPath: String,
                         toView: NSView,
                         lastSubview: NSView?,
                         lastTextField: NSView?,
                         height: inout CGFloat,
                         indent: CGFloat,
                         constraints: inout [NSLayoutConstraint]) -> NSColorWell? {

    // -------------------------------------------------------------------------
    //  Create and add Label if label string was passed
    // -------------------------------------------------------------------------
    let textFieldLabel = setupLabel(string: label, controlSize: controlSize, toView: toView, indent: indent, constraints: &constraints)

    let colorWell = NSColorWell()
    colorWell.translatesAutoresizingMaskIntoConstraints = false
    colorWell.isBordered = true
    toView.addSubview(colorWell)

    // ---------------------------------------------------------------------
    //  Bind color well to keyPath
    // ---------------------------------------------------------------------
    colorWell.bind(NSBindingName.value,
                   to: bindTo ?? UserDefaults.standard,
                   withKeyPath: bindKeyPath,
                   options: [NSBindingOption.continuouslyUpdatesValue: true, NSBindingOption.valueTransformerName: HexColorTransformer.name])

    // -------------------------------------------------------------------------
    //  Add Constraints
    // -------------------------------------------------------------------------
    // Width
    constraints.append(NSLayoutConstraint(item: colorWell,
                                          attribute: .width,
                                          relatedBy: .equal,
                                          toItem: nil,
                                          attribute: .notAnAttribute,
                                          multiplier: 1,
                                          constant: 44.0))

    // True
    constraints.append(NSLayoutConstraint(item: colorWell,
                                          attribute: .height,
                                          relatedBy: .equal,
                                          toItem: nil,
                                          attribute: .notAnAttribute,
                                          multiplier: 1,
                                          constant: 23.0))

    if let label = textFieldLabel {

        // Top
        var constantTop: CGFloat = 16.0
        if controlSize == .small {
            constantTop = 7.0
        }
        constraints.append(NSLayoutConstraint(item: colorWell,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: lastSubview ?? toView,
                                              attribute: (lastSubview != nil) ? .bottom : .top,
                                              multiplier: 1,
                                              constant: constantTop))

        // Leading
        constraints.append(NSLayoutConstraint(item: colorWell,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: label,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 6.0))

        // Baseline
        constraints.append(NSLayoutConstraint(item: colorWell,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: label,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 0.0))
    } else {

        // Top
        constraints.append(NSLayoutConstraint(item: colorWell,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: lastSubview ?? toView,
                                              attribute: (lastSubview != nil) ? .bottom : .top,
                                              multiplier: 1,
                                              constant: 6.0))

    }

    if lastTextField != nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: colorWell,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: lastTextField,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))
    } else if textFieldLabel == nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: colorWell,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: toView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: indent))

    }

    // Trailing
    constraints.append(NSLayoutConstraint(item: toView,
                                          attribute: .trailing,
                                          relatedBy: .greaterThanOrEqual,
                                          toItem: colorWell,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 20))

    // -------------------------------------------------------------------------
    //  Update height value
    // -------------------------------------------------------------------------
    height += 8.0 + colorWell.intrinsicContentSize.height

    return colorWell
}

public func addDirectoryPathSelection(label: String?,
                                      placeholderValue: String,
                                      buttonTitle: String?,
                                      buttonTarget: Any?,
                                      buttonAction: Selector,
                                      controlSize: NSControl.ControlSize = .regular,
                                      bindTo: Any?,
                                      keyPath: String,
                                      toView: NSView,
                                      lastSubview: NSView?,
                                      lastTextField: NSView?,
                                      height: inout CGFloat,
                                      indent: CGFloat,
                                      constraints: inout [NSLayoutConstraint]) -> NSView? {

    let textFieldLabel = NSTextField()
    if let labelString = label {

        // -------------------------------------------------------------------------
        //  Create and add TextField Label
        // -------------------------------------------------------------------------
        textFieldLabel.translatesAutoresizingMaskIntoConstraints = false
        textFieldLabel.lineBreakMode = .byTruncatingTail
        textFieldLabel.isBordered = false
        textFieldLabel.isBezeled = false
        textFieldLabel.drawsBackground = false
        textFieldLabel.isEditable = false
        textFieldLabel.isSelectable = true
        textFieldLabel.textColor = .labelColor
        textFieldLabel.alignment = .right
        textFieldLabel.stringValue = labelString
        textFieldLabel.controlSize = controlSize
        textFieldLabel.setContentHuggingPriority(.required, for: .horizontal)
        textFieldLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        toView.addSubview(textFieldLabel)

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldLabel,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: toView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: kPreferencesIndent))
    }

    // -------------------------------------------------------------------------
    //  Create and add TextField
    // -------------------------------------------------------------------------
    let textField = NSTextField()
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.lineBreakMode = .byTruncatingMiddle
    textField.isBordered = false
    textField.isBezeled = false
    textField.bezelStyle = .squareBezel
    textField.drawsBackground = false
    textField.isEditable = false
    textField.isSelectable = true
    textField.textColor = .labelColor
    textField.alignment = .left
    textField.placeholderString = placeholderValue
    textField.controlSize = controlSize
    textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    textField.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    textField.setContentHuggingPriority(.defaultLow, for: .vertical)
    toView.addSubview(textField)

    // ---------------------------------------------------------------------
    //  Bind TextField to keyPath
    // ---------------------------------------------------------------------
    textField.bind(NSBindingName.value,
                   to: bindTo ?? UserDefaults.standard,
                   withKeyPath: keyPath,
                   options: [NSBindingOption.continuouslyUpdatesValue: true, NSBindingOption.nullPlaceholder: placeholderValue])

    // -------------------------------------------------------------------------
    //  Create and add button
    // -------------------------------------------------------------------------
    let button = NSButton(title: buttonTitle ?? NSLocalizedString("Choose…", comment: ""), target: buttonTarget, action: buttonAction)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.controlSize = controlSize
    button.setContentCompressionResistancePriority(.required, for: .horizontal)
    button.setContentHuggingPriority(.required, for: .horizontal)
    toView.addSubview(button)

    // -------------------------------------------------------------------------
    //  Add Constraints
    // -------------------------------------------------------------------------
    // TextField Leading
    constraints.append(NSLayoutConstraint(item: textField,
                                          attribute: .leading,
                                          relatedBy: .equal,
                                          toItem: textFieldLabel,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 6.0))

    // Checkbox Center Y
    constraints.append(NSLayoutConstraint(item: textField,
                                          attribute: .firstBaseline,
                                          relatedBy: .equal,
                                          toItem: textFieldLabel,
                                          attribute: .firstBaseline,
                                          multiplier: 1,
                                          constant: 0.0))

    // Button Leading
    constraints.append(NSLayoutConstraint(item: button,
                                          attribute: .leading,
                                          relatedBy: .equal,
                                          toItem: textField,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 6.0))

    // Button Baseline
    constraints.append(NSLayoutConstraint(item: button,
                                          attribute: .firstBaseline,
                                          relatedBy: .equal,
                                          toItem: textFieldLabel,
                                          attribute: .firstBaseline,
                                          multiplier: 1,
                                          constant: 0.0))

    if lastTextField != nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: lastTextField,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))
    }

    // Trailing
    constraints.append(NSLayoutConstraint(item: toView,
                                          attribute: .trailing,
                                          relatedBy: .equal,
                                          toItem: button,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 20.0))

    // -------------------------------------------------------------------------
    //  Update height value
    // -------------------------------------------------------------------------
    height += 20.0 + textField.intrinsicContentSize.height

    return textField
}

public func addPopUpButtonCertificate(label: String?,
                                      controlSize: NSControl.ControlSize = .regular,
                                      bindTo: Any?,
                                      bindKeyPathCheckbox: String,
                                      bindKeyPathPopUpButton: String,
                                      toView: NSView,
                                      lastSubview: NSView?,
                                      lastTextField: NSView?,
                                      height: inout CGFloat,
                                      indent: CGFloat,
                                      constraints: inout [NSLayoutConstraint]) -> NSView? {

    // -------------------------------------------------------------------------
    //  Create and add Label if label string was passed
    // -------------------------------------------------------------------------
    guard let textFieldLabel = setupLabel(string: label, controlSize: controlSize, toView: toView, indent: indent, constraints: &constraints) else { return nil }

    var menu: NSMenu
    var signingCertificatePersistantRef: Data?

    if
        let userDefaults = bindTo as? UserDefaults,
        let persistantRef = userDefaults.data(forKey: bindKeyPathPopUpButton) {
        signingCertificatePersistantRef = persistantRef
    } else if
        let bindObject = bindTo as? NSObject,
        let persistantRef = bindObject.value(forKeyPath: bindKeyPathPopUpButton) as? Data {
        signingCertificatePersistantRef = persistantRef
    }

    if let identityDict = Identities.codeSigningIdentityDict(persistentRef: signingCertificatePersistantRef) {
        menu = Identities.popUpButtonMenu(forCodeSigningIdentityDicts: [identityDict])
    } else {
        menu = NSMenu()
        menu.addItem(NSMenuItem(title: "None", action: nil, keyEquivalent: ""))
    }

    // -------------------------------------------------------------------------
    //  Create and add Checkbox
    // -------------------------------------------------------------------------
    let checkbox = NSButton()
    checkbox.translatesAutoresizingMaskIntoConstraints = false
    checkbox.setButtonType(.switch)
    checkbox.title = ""
    toView.addSubview(checkbox)

    // ---------------------------------------------------------------------
    //  Bind checkbox to keyPath
    // ---------------------------------------------------------------------
    checkbox.bind(.value,
                  to: bindTo ?? UserDefaults.standard,
                  withKeyPath: bindKeyPathCheckbox,
                  options: [.continuouslyUpdatesValue: true])

    // -------------------------------------------------------------------------
    //  Create and add PopUpButton
    // -------------------------------------------------------------------------
    let popUpButton = SigningCertificatePopUpButton()
    popUpButton.translatesAutoresizingMaskIntoConstraints = false
    popUpButton.controlSize = controlSize
    popUpButton.menu = menu
    popUpButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    popUpButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
    toView.addSubview(popUpButton)

    menu.delegate = popUpButton

    // ---------------------------------------------------------------------
    //  Bind PopUpButton to keyPath
    // ---------------------------------------------------------------------
    popUpButton.bind(.selectedObject,
                     to: bindTo ?? UserDefaults.standard,
                     withKeyPath: bindKeyPathPopUpButton,
                     options: [.continuouslyUpdatesValue: true])

    // ---------------------------------------------------------------------
    //  Bind PopUpButton to checkbox state
    // ---------------------------------------------------------------------
    popUpButton.bind(.enabled,
                     to: bindTo ?? UserDefaults.standard,
                     withKeyPath: bindKeyPathCheckbox,
                     options: [.continuouslyUpdatesValue: true])

    // -------------------------------------------------------------------------
    //  Add Constraints
    // -------------------------------------------------------------------------
    // Top
    var constantTop: CGFloat = 8.0
    if lastSubview is NSButton {
        constantTop = 8.0
    } else if controlSize == .small {
        constantTop = 6.0
    }
    // Top
    constraints.append(NSLayoutConstraint(item: popUpButton,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: lastSubview ?? toView,
                                          attribute: (lastSubview != nil) ? .bottom : .top,
                                          multiplier: 1,
                                          constant: constantTop))

    // Checkbox Leading
    constraints.append(NSLayoutConstraint(item: checkbox,
                                          attribute: .leading,
                                          relatedBy: .equal,
                                          toItem: textFieldLabel,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 6.0))

    // Checkbox Center Y
    constraints.append(NSLayoutConstraint(item: checkbox,
                                          attribute: .firstBaseline,
                                          relatedBy: .equal,
                                          toItem: textFieldLabel,
                                          attribute: .firstBaseline,
                                          multiplier: 1,
                                          constant: 2.5))

    // PopUpButton Leading
    constraints.append(NSLayoutConstraint(item: popUpButton,
                                          attribute: .leading,
                                          relatedBy: .equal,
                                          toItem: checkbox,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 5.0))

    // PopUpButton Baseline
    constraints.append(NSLayoutConstraint(item: popUpButton,
                                          attribute: .firstBaseline,
                                          relatedBy: .equal,
                                          toItem: textFieldLabel,
                                          attribute: .firstBaseline,
                                          multiplier: 1,
                                          constant: 0.0))

    if lastTextField != nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: checkbox,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: lastTextField,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))
    }

    // Trailing
    constraints.append(NSLayoutConstraint(item: toView,
                                          attribute: .trailing,
                                          relatedBy: .greaterThanOrEqual,
                                          toItem: popUpButton,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 20.0))

    // -------------------------------------------------------------------------
    //  Update height value
    // -------------------------------------------------------------------------
    height += 8.0 + popUpButton.intrinsicContentSize.height

    return popUpButton
}

class SigningCertificatePopUpButton: NSPopUpButton, NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        let persistentRef = self.selectedItem?.representedObject as? Data
        Identities.shared.updateCodeSigningIdentities()
        menu.removeAllItems()
        menu.addItem(NSMenuItem(title: "None", action: nil, keyEquivalent: ""))
        for identity in Identities.shared.identities {
            guard
                let secIdentityObject = identity[kSecValueRef as String],
                CFGetTypeID(secIdentityObject) == SecIdentityGetTypeID(),
                let secPersistentRef = identity[kSecValuePersistentRef as String] as? Data else {
                    continue
            }
            // swiftlint:disable:next force_cast
            let secIdentity = secIdentityObject as! SecIdentity
            let menuItem = NSMenuItem()
            menuItem.title = identity[kSecAttrLabel as String] as? String ?? "Unknown Certificate"
            menuItem.representedObject = secPersistentRef
            menuItem.image = secIdentity.certificateIconSmall
            menu.addItem(menuItem)
        }
        self.selectItem(at: menu.indexOfItem(withRepresentedObject: persistentRef))
    }
}

public func addButton(label: String?,
                      title: String?,
                      controlSize: NSControl.ControlSize = .regular,
                      bindToEnabled: Any?,
                      bindKeyPathEnabled: String?,
                      target: Any?,
                      selector: Selector,
                      toView: NSView,
                      lastSubview: NSView?,
                      lastTextField: NSView?,
                      height: inout CGFloat,
                      indent: CGFloat,
                      constraints: inout [NSLayoutConstraint]) -> NSView? {

    // -------------------------------------------------------------------------
    //  Create and add Label if label string was passed
    // -------------------------------------------------------------------------
    let textFieldLabel = setupLabel(string: label, controlSize: controlSize, toView: toView, indent: indent, constraints: &constraints)

    // -------------------------------------------------------------------------
    //  Create and add button
    // -------------------------------------------------------------------------
    let button = NSButton(title: title ?? NSLocalizedString("Choose…", comment: ""), target: target, action: selector)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.controlSize = controlSize
    button.setContentCompressionResistancePriority(.required, for: .horizontal)
    toView.addSubview(button)

    // ---------------------------------------------------------------------
    //  Bind Button enabled to checkbox state
    // ---------------------------------------------------------------------
    if let keyPath = bindKeyPathEnabled {
        button.bind(NSBindingName.enabled, to: bindToEnabled ?? UserDefaults.standard, withKeyPath: keyPath, options: [.continuouslyUpdatesValue: true])
    }

    // -------------------------------------------------------------------------
    //  Add Constraints
    // -------------------------------------------------------------------------
    if let label = textFieldLabel {

        // Leading
        constraints.append(NSLayoutConstraint(item: button,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: label,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 6.0))

        // Baseline
        constraints.append(NSLayoutConstraint(item: button,
                                              attribute: .firstBaseline,
                                              relatedBy: .equal,
                                              toItem: label,
                                              attribute: .firstBaseline,
                                              multiplier: 1,
                                              constant: 0.0))
    } else if lastTextField != nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: button,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: lastTextField,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))

    } else {

        // Leading
        constraints.append(NSLayoutConstraint(item: button,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: toView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: indent))
    }

    // Top
    constraints.append(NSLayoutConstraint(item: button,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: lastSubview ?? toView,
                                          attribute: (lastSubview != nil) ? .bottom : .top,
                                          multiplier: 1,
                                          constant: 8.0))

    // Trailing
    if lastTextField is NSButton, let lastButton = lastTextField {
        constraints.append(NSLayoutConstraint(item: lastButton,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: button,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0.0))
    } else {
        constraints.append(NSLayoutConstraint(item: toView,
                                              attribute: .trailing,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: button,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 20.0))
    }

    // Width
    constraints.append(NSLayoutConstraint(item: button,
                                          attribute: .width,
                                          relatedBy: .greaterThanOrEqual,
                                          toItem: nil,
                                          attribute: .notAnAttribute,
                                          multiplier: 1,
                                          constant: button.intrinsicContentSize.width))

    // -------------------------------------------------------------------------
    //  Update height value
    // -------------------------------------------------------------------------
    height += 8.0 + button.intrinsicContentSize.height

    return button
}

public func addPopUpButton(label: String?,
                           titles: [String],
                           controlSize: NSControl.ControlSize = .regular,
                           bindTo: Any?,
                           bindKeyPath: String,
                           toView: NSView,
                           lastSubview: NSView?,
                           lastTextField: NSView?,
                           height: inout CGFloat,
                           indent: CGFloat,
                           constraints: inout [NSLayoutConstraint]) -> NSView? {

    // -------------------------------------------------------------------------
    //  Create and add Label if label string was passed
    // -------------------------------------------------------------------------
    let textFieldLabel = setupLabel(string: label, controlSize: controlSize, toView: toView, indent: indent, constraints: &constraints)

    // -------------------------------------------------------------------------
    //  Create and add PopUpButton
    // -------------------------------------------------------------------------
    let popUpButton = NSPopUpButton()
    popUpButton.translatesAutoresizingMaskIntoConstraints = false
    popUpButton.addItems(withTitles: titles)
    popUpButton.controlSize = controlSize
    popUpButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    toView.addSubview(popUpButton)

    // ---------------------------------------------------------------------
    //  Bind PopUpButton to keyPath
    // ---------------------------------------------------------------------
    popUpButton.bind(NSBindingName.selectedValue, to: bindTo ?? UserDefaults.standard, withKeyPath: bindKeyPath, options: [NSBindingOption.continuouslyUpdatesValue: true])

    // -------------------------------------------------------------------------
    //  Add Constraints
    // -------------------------------------------------------------------------
    // Top
    var constantTop: CGFloat = 6.0
    if controlSize == .small {
        constantTop = 6.0
    }
    constraints.append(NSLayoutConstraint(item: popUpButton,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: lastSubview ?? toView,
                                          attribute: (lastSubview != nil) ? .bottom : .top,
                                          multiplier: 1,
                                          constant: constantTop))

    if let label = textFieldLabel {

        // Leading
        constraints.append(NSLayoutConstraint(item: popUpButton,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: label,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 6.0))

        // Baseline
        constraints.append(NSLayoutConstraint(item: popUpButton,
                                              attribute: .firstBaseline,
                                              relatedBy: .equal,
                                              toItem: label,
                                              attribute: .firstBaseline,
                                              multiplier: 1,
                                              constant: 0.0))
    } else {

        // Leading
        constraints.append(NSLayoutConstraint(item: popUpButton,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: toView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: indent))
    }

    if lastTextField != nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: popUpButton,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: lastTextField,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))

    }

    // Trailing
    constraints.append(NSLayoutConstraint(item: toView,
                                          attribute: .trailing,
                                          relatedBy: .greaterThanOrEqual,
                                          toItem: popUpButton,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 20.0))

    // Width
    constraints.append(NSLayoutConstraint(item: popUpButton,
                                          attribute: .width,
                                          relatedBy: .equal,
                                          toItem: nil,
                                          attribute: .notAnAttribute,
                                          multiplier: 1,
                                          constant: popUpButton.intrinsicContentSize.width))

    // -------------------------------------------------------------------------
    //  Update height value
    // -------------------------------------------------------------------------
    height += 8.0 + popUpButton.intrinsicContentSize.height

    return popUpButton
}

public func addCheckbox(label: String?,
                        title: String,
                        controlSize: NSControl.ControlSize = .regular,
                        bindTo: Any?,
                        bindKeyPath: String,
                        toView: NSView,
                        lastSubview: NSView?,
                        lastTextField: NSView?,
                        height: inout CGFloat,
                        indent: CGFloat,
                        constraints: inout [NSLayoutConstraint]) -> NSView? {

    // -------------------------------------------------------------------------
    //  Create and add Label if label string was passed
    // -------------------------------------------------------------------------
    let textFieldLabel = setupLabel(string: label, controlSize: controlSize, toView: toView, indent: indent, constraints: &constraints)

    // -------------------------------------------------------------------------
    //  Create and add Checkbox
    // -------------------------------------------------------------------------
    let checkbox = NSButton()
    checkbox.translatesAutoresizingMaskIntoConstraints = false
    checkbox.setButtonType(.switch)
    checkbox.title = title
    checkbox.controlSize = controlSize
    toView.addSubview(checkbox)

    // ---------------------------------------------------------------------
    //  Bind checkbox to keyPath
    // ---------------------------------------------------------------------
    checkbox.bind(NSBindingName.value, to: bindTo ?? UserDefaults.standard, withKeyPath: bindKeyPath, options: [.continuouslyUpdatesValue: true])

    // -------------------------------------------------------------------------
    //  Add Constraints
    // -------------------------------------------------------------------------
    if let label = textFieldLabel {

        // Top
        var constantTop: CGFloat = 16.0
        if controlSize == .small {
            constantTop = 7.0
        }

        constraints.append(NSLayoutConstraint(item: checkbox,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: lastSubview ?? toView,
                                              attribute: (lastSubview != nil) ? .bottom : .top,
                                              multiplier: 1,
                                              constant: constantTop))

        // Leading
        constraints.append(NSLayoutConstraint(item: checkbox,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: label,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 6.0))

        // Baseline
        constraints.append(NSLayoutConstraint(item: checkbox,
                                              attribute: .firstBaseline,
                                              relatedBy: .equal,
                                              toItem: label,
                                              attribute: .firstBaseline,
                                              multiplier: 1,
                                              constant: 2.0))
    } else {

        var constantTop: CGFloat = 6.0
        if bindTo is ProfileExportAccessoryView {
            constantTop = 10.0
        }

        // Top
        constraints.append(NSLayoutConstraint(item: checkbox,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: lastSubview ?? toView,
                                              attribute: (lastSubview != nil) ? .bottom : .top,
                                              multiplier: 1,
                                              constant: constantTop))

    }

    if lastTextField != nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: checkbox,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: lastTextField,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))
    } else if textFieldLabel == nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: checkbox,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: toView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: indent))

    }

    // Trailing
    constraints.append(NSLayoutConstraint(item: toView,
                                          attribute: .trailing,
                                          relatedBy: .greaterThanOrEqual,
                                          toItem: checkbox,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 20))

    // -------------------------------------------------------------------------
    //  Update height value
    // -------------------------------------------------------------------------
    height += 8.0 + checkbox.intrinsicContentSize.height

    return checkbox
}

public func addTextFieldDescription(stringValue: String,
                                    controlSize: NSControl.ControlSize = .regular,
                                    font: NSFont? = nil,
                                    toView: NSView,
                                    lastSubview: NSView?,
                                    lastTextField: NSView?,
                                    height: inout CGFloat,
                                    constraints: inout [NSLayoutConstraint]) -> NSView? {

    let textFieldDescription = NSTextField()

    // -------------------------------------------------------------------------
    //  Create and add TextField Label
    // -------------------------------------------------------------------------
    textFieldDescription.translatesAutoresizingMaskIntoConstraints = false
    textFieldDescription.lineBreakMode = .byWordWrapping
    textFieldDescription.isBordered = false
    textFieldDescription.isBezeled = false
    textFieldDescription.drawsBackground = false
    textFieldDescription.isEditable = false
    textFieldDescription.isSelectable = true
    textFieldDescription.textColor = .labelColor
    textFieldDescription.alignment = .left
    textFieldDescription.stringValue = stringValue
    textFieldDescription.controlSize = controlSize
    textFieldDescription.setContentCompressionResistancePriority(.required, for: .horizontal)
    toView.addSubview(textFieldDescription)

    // -------------------------------------------------------------------------
    //  Add Constraints
    // -------------------------------------------------------------------------
    // Top
    var constantTop: CGFloat = 8.0
    if lastSubview == nil {
        constantTop = 10.0
    } else if controlSize == .small {
        constantTop = 6.0
    }
    constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: lastSubview ?? toView,
                                          attribute: (lastSubview != nil) ? .bottom : .top,
                                          multiplier: 1,
                                          constant: constantTop))

    // Leading
    constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: lastTextField ?? toView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: (lastTextField != nil) ? 0.0 : kPreferencesIndent))

    // Trailing
    constraints.append(NSLayoutConstraint(item: toView,
                                          attribute: .trailing,
                                          relatedBy: .equal,
                                          toItem: textFieldDescription,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 20))

    // -------------------------------------------------------------------------
    //  Update height value
    // -------------------------------------------------------------------------
    height += 20.0 + textFieldDescription.intrinsicContentSize.height

    return textFieldDescription
}

public func addTextFieldLabel(label: String?,
                              placeholderValue: String,
                              controlSize: NSControl.ControlSize = .regular,
                              font: NSFont? = nil,
                              bindTo: Any? = nil,
                              keyPath: String?,
                              toView: NSView,
                              lastSubview: NSView?,
                              lastTextField: NSView?,
                              height: inout CGFloat,
                              constraints: inout [NSLayoutConstraint]) -> NSView? {

    let textFieldLabel = NSTextField()
    if let labelString = label {

        // -------------------------------------------------------------------------
        //  Create and add TextField Label
        // -------------------------------------------------------------------------
        textFieldLabel.translatesAutoresizingMaskIntoConstraints = false
        textFieldLabel.lineBreakMode = .byTruncatingTail
        textFieldLabel.isBordered = false
        textFieldLabel.isBezeled = false
        textFieldLabel.drawsBackground = false
        textFieldLabel.isEditable = false
        textFieldLabel.isSelectable = true
        textFieldLabel.textColor = .labelColor
        textFieldLabel.alignment = .right
        textFieldLabel.stringValue = labelString
        textFieldLabel.controlSize = controlSize
        textFieldLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        toView.addSubview(textFieldLabel)

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldLabel,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: toView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: kPreferencesIndent))
    }

    // -------------------------------------------------------------------------
    //  Create and add TextField
    // -------------------------------------------------------------------------
    let textField = NSTextField()
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.lineBreakMode = .byTruncatingTail
    textField.isBordered = false
    textField.isBezeled = false
    textField.drawsBackground = false
    textField.isEditable = false
    textField.isSelectable = true
    textField.textColor = .labelColor
    textField.alignment = .left
    textField.placeholderString = placeholderValue
    textField.controlSize = controlSize
    if let textFieldFont = font {
        textField.font = textFieldFont
    }
    textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    toView.addSubview(textField)

    // ---------------------------------------------------------------------
    //  Bind TextField to keyPath
    // ---------------------------------------------------------------------
    if let bindKeyPath = keyPath {
        textField.bind(NSBindingName.value,
                       to: bindTo ?? UserDefaults.standard,
                       withKeyPath: bindKeyPath,
                       options: [NSBindingOption.continuouslyUpdatesValue: true, NSBindingOption.nullPlaceholder: placeholderValue])
    }

    // -------------------------------------------------------------------------
    //  Add Constraints
    // -------------------------------------------------------------------------
    // Top
    var constantTop: CGFloat = 8.0
    if lastSubview == nil {
        constantTop = 10.0
    } else if controlSize == .small {
        constantTop = 6.0
    }
    constraints.append(NSLayoutConstraint(item: textField,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: lastSubview ?? toView,
                                          attribute: (lastSubview != nil) ? .bottom : .top,
                                          multiplier: 1,
                                          constant: constantTop))

    if label != nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: textFieldLabel,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 6.0))

        // Baseline
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .firstBaseline,
                                              relatedBy: .equal,
                                              toItem: textFieldLabel,
                                              attribute: .firstBaseline,
                                              multiplier: 1,
                                              constant: 0.0))
    } else {

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: toView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: kPreferencesIndent))
    }

    if lastTextField != nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: lastTextField,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))
    }

    // Trailing
    constraints.append(NSLayoutConstraint(item: toView,
                                          attribute: .trailing,
                                          relatedBy: .equal,
                                          toItem: textField,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 20))

    // -------------------------------------------------------------------------
    //  Update height value
    // -------------------------------------------------------------------------
    height += 20.0 + textField.intrinsicContentSize.height

    return textField
}

public func addTextField(label: String?,
                         placeholderValue: String,
                         controlSize: NSControl.ControlSize = .regular,
                         bindTo: Any? = nil,
                         keyPath: String,
                         toView: NSView,
                         lastSubview: NSView?,
                         lastTextField: NSView?,
                         height: inout CGFloat,
                         constraints: inout [NSLayoutConstraint]) -> NSView? {

    let textFieldLabel = NSTextField()
    if let labelString = label {

        // -------------------------------------------------------------------------
        //  Create and add TextField Label
        // -------------------------------------------------------------------------
        textFieldLabel.translatesAutoresizingMaskIntoConstraints = false
        textFieldLabel.lineBreakMode = .byTruncatingTail
        textFieldLabel.isBordered = false
        textFieldLabel.isBezeled = false
        textFieldLabel.drawsBackground = false
        textFieldLabel.isEditable = false
        textFieldLabel.isSelectable = true
        textFieldLabel.textColor = .labelColor
        textFieldLabel.alignment = .right
        textFieldLabel.stringValue = labelString
        textFieldLabel.controlSize = controlSize
        textFieldLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        toView.addSubview(textFieldLabel)

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldLabel,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: toView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: kPreferencesIndent))
    }

    // -------------------------------------------------------------------------
    //  Create and add TextField
    // -------------------------------------------------------------------------
    let textField = NSTextField()
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.lineBreakMode = .byTruncatingTail
    textField.isBordered = true
    textField.isBezeled = true
    textField.bezelStyle = .squareBezel
    textField.drawsBackground = false
    textField.isEditable = true
    textField.isSelectable = true
    textField.textColor = .labelColor
    textField.alignment = .left
    textField.placeholderString = placeholderValue
    textField.controlSize = controlSize
    textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    toView.addSubview(textField)

    // ---------------------------------------------------------------------
    //  Bind TextField to keyPath
    // ---------------------------------------------------------------------
    textField.bind(NSBindingName.value,
                   to: bindTo ?? UserDefaults.standard,
                   withKeyPath: keyPath,
                   options: [NSBindingOption.continuouslyUpdatesValue: true, NSBindingOption.nullPlaceholder: placeholderValue])

    // -------------------------------------------------------------------------
    //  Add Constraints
    // -------------------------------------------------------------------------
    // Top
    var constantTop: CGFloat = 8.0
    if lastSubview == nil {
        constantTop = 10.0
    } else if controlSize == .small {
        constantTop = 6.0
    }
    constraints.append(NSLayoutConstraint(item: textField,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: lastSubview ?? toView,
                                          attribute: (lastSubview != nil) ? .bottom : .top,
                                          multiplier: 1,
                                          constant: constantTop))

    if label != nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: textFieldLabel,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 6.0))

        // Baseline
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .firstBaseline,
                                              relatedBy: .equal,
                                              toItem: textFieldLabel,
                                              attribute: .firstBaseline,
                                              multiplier: 1,
                                              constant: 0.0))
    } else {

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: toView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: kPreferencesIndent))
    }

    if lastTextField != nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: lastTextField,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))
    }

    // Trailing
    constraints.append(NSLayoutConstraint(item: toView,
                                          attribute: .trailing,
                                          relatedBy: .equal,
                                          toItem: textField,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 20))

    // -------------------------------------------------------------------------
    //  Update height value
    // -------------------------------------------------------------------------
    height += 20.0 + textField.intrinsicContentSize.height

    return textField
}

public func addBox(title: String?,
                   toView: NSView,
                   lastSubview: NSView?,
                   lastTextField: NSView?,
                   height: inout CGFloat,
                   indent: CGFloat,
                   constraints: inout [NSLayoutConstraint]) -> NSBox? {

    let box = NSBox()
    box.translatesAutoresizingMaskIntoConstraints = false

    if let theTitle = title {
        box.title = theTitle
        box.titlePosition = .atTop
    } else {
        box.titlePosition = .noTitle
    }

    toView.addSubview(box)

    // -------------------------------------------------------------------------
    //  Add Constraints
    // -------------------------------------------------------------------------
    // Top
    let constantTop: CGFloat = -4.0
    constraints.append(NSLayoutConstraint(item: box,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: lastSubview ?? toView,
                                          attribute: (lastSubview != nil) ? .bottom : .top,
                                          multiplier: 1,
                                          constant: constantTop))

    if lastTextField != nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: box,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: lastTextField,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))
    } else {

        // Leading
        constraints.append(NSLayoutConstraint(item: box,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: toView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: indent))
    }

    // Trailing
    constraints.append(NSLayoutConstraint(item: toView,
                                          attribute: .trailing,
                                          relatedBy: .equal,
                                          toItem: box,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 20.0))
    /*
     // Height Test
     constraints.append(NSLayoutConstraint(item: box,
     attribute: .height,
     relatedBy: .equal,
     toItem: nil,
     attribute: .notAnAttribute,
     multiplier: 1,
     constant: 80.0))
     */

    // ---------------------------------------------------------------------
    //  Update height value
    // ---------------------------------------------------------------------
    height += constantTop + box.intrinsicContentSize.height

    return box
}

public func addTextField(label: String,
                         placeholderValue: String,
                         controlSize: NSControl.ControlSize = .regular,
                         bindTo: Any?,
                         bindKeyPathCheckbox: String,
                         bindKeyPathTextField: String,
                         toView: NSView,
                         lastSubview: NSView?,
                         lastTextField: NSView?,
                         height: inout CGFloat,
                         indent: CGFloat,
                         constraints: inout [NSLayoutConstraint]) -> NSView? {

    // -------------------------------------------------------------------------
    //  Create and add Label if label string was passed
    // -------------------------------------------------------------------------
    guard let textFieldLabel = setupLabel(string: label, controlSize: controlSize, toView: toView, indent: indent, constraints: &constraints) else { return nil }

    // -------------------------------------------------------------------------
    //  Create and add Checkbox
    // -------------------------------------------------------------------------
    let checkbox = NSButton()
    checkbox.translatesAutoresizingMaskIntoConstraints = false
    checkbox.setButtonType(.switch)
    checkbox.title = ""
    toView.addSubview(checkbox)

    // ---------------------------------------------------------------------
    //  Bind checkbox to keyPath
    // ---------------------------------------------------------------------
    checkbox.bind(NSBindingName.value, to: bindTo ?? UserDefaults.standard, withKeyPath: bindKeyPathCheckbox, options: [NSBindingOption.continuouslyUpdatesValue: true])

    // -------------------------------------------------------------------------
    //  Create and add TextField
    // -------------------------------------------------------------------------
    let textField = NSTextField()
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.lineBreakMode = .byTruncatingTail
    textField.isBordered = true
    textField.isBezeled = true
    textField.bezelStyle = .squareBezel
    textField.drawsBackground = false
    textField.isEditable = true
    textField.isSelectable = true
    textField.textColor = .labelColor
    textField.alignment = .left
    textField.placeholderString = placeholderValue
    textField.controlSize = controlSize
    textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    toView.addSubview(textField)

    // ---------------------------------------------------------------------
    //  Bind TextField to keyPath
    // ---------------------------------------------------------------------
    textField.bind(NSBindingName.value, to: bindTo ?? UserDefaults.standard, withKeyPath: bindKeyPathTextField, options: [.continuouslyUpdatesValue: true, .nullPlaceholder: placeholderValue])

    // ---------------------------------------------------------------------
    //  Bind PopUpButton to checkbox state
    // ---------------------------------------------------------------------
    textField.bind(NSBindingName.enabled, to: bindTo ?? UserDefaults.standard, withKeyPath: bindKeyPathCheckbox, options: [.continuouslyUpdatesValue: true])

    // -------------------------------------------------------------------------
    //  Add Constraints
    // -------------------------------------------------------------------------
    // Top
    var constantTop: CGFloat = 8.0
    if lastSubview is NSButton {
        constantTop = 8.0
    } else if lastSubview is NSTextField {
        constantTop = 5.0
    } else if controlSize == .small {
        constantTop = 6.0
    }
    constraints.append(NSLayoutConstraint(item: textField,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: lastSubview ?? toView,
                                          attribute: (lastSubview != nil) ? .bottom : .top,
                                          multiplier: 1,
                                          constant: constantTop))

    // Checkbox Leading
    constraints.append(NSLayoutConstraint(item: checkbox,
                                          attribute: .leading,
                                          relatedBy: .equal,
                                          toItem: textFieldLabel,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 6.0))

    // Checkbox Center Y
    constraints.append(NSLayoutConstraint(item: checkbox,
                                          attribute: .firstBaseline,
                                          relatedBy: .equal,
                                          toItem: textFieldLabel,
                                          attribute: .firstBaseline,
                                          multiplier: 1,
                                          constant: 0.0))

    // TextField Leading
    constraints.append(NSLayoutConstraint(item: textField,
                                          attribute: .leading,
                                          relatedBy: .equal,
                                          toItem: checkbox,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 0.0))

    // TextField Baseline
    constraints.append(NSLayoutConstraint(item: textField,
                                          attribute: .firstBaseline,
                                          relatedBy: .equal,
                                          toItem: textFieldLabel,
                                          attribute: .firstBaseline,
                                          multiplier: 1,
                                          constant: 0.0))

    if lastTextField != nil {

        // Leading
        constraints.append(NSLayoutConstraint(item: checkbox,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: lastTextField,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))
    }

    // Trailing
    constraints.append(NSLayoutConstraint(item: toView,
                                          attribute: .trailing,
                                          relatedBy: .equal,
                                          toItem: textField,
                                          attribute: .trailing,
                                          multiplier: 1,
                                          constant: 20.0))

    // -------------------------------------------------------------------------
    //  Update height value
    // -------------------------------------------------------------------------
    height += 20.0 + textField.intrinsicContentSize.height

    return checkbox
}
