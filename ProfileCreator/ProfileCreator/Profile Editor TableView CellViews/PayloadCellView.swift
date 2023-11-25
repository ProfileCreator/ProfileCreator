//
//  PayloadCellViewProtocol.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellView: NSTableCellView, NSCopying {

    // MARK: -
    // MARK: PayloadCellView Variables

    var height: CGFloat = 0.0
    var row = -1

    unowned var subkey: PayloadSubkey
    unowned var profileEditor: ProfileEditor
    unowned var profile: Profile

    var textFieldDescription: NSTextField?
    var textFieldFooter: NSTextField?
    var textFieldTitle: NSTextField?
    var textFieldMessage: NSTextField?

    var imageViewDocumentation: NSButton?
    var imageViewSubstitutionVariables: NSButton?
    var boxNote: BoxView?

    var leadingKeyView: NSView?
    var trailingKeyView: NSView?
    var isRequired = false
    var isEnabled = false
    var isExcludedArray: [[String: Any]]?
    var isEditing = false
    var payloadIndex: Int
    var parentCellViews: [PayloadCellView]?
    var valueInfoProcessor: ValueInfoProcessor?
    var valueImportProcessor: ValueImportProcessor?
    var allowedFileTypes: [String]?
    var deprecatedString: String?

    var cellViewConstraints = [NSLayoutConstraint]()
    var indent: Int = 0

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(subkey: PayloadSubkey, payloadIndex: Int, enabled: Bool, required: Bool, editor: ProfileEditor) {

        // ---------------------------------------------------------------------
        //  Initialize required variables
        // ---------------------------------------------------------------------
        self.subkey = subkey
        self.profile = editor.profile
        self.profileEditor = editor
        self.payloadIndex = payloadIndex
        self.isEnabled = enabled
        self.isRequired = required
        self.allowedFileTypes = subkey.allowedFileTypes ?? [kUTTypeItem as String]
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Initialize excluded array
        // ---------------------------------------------------------------------
        self.isExcludedArray = editor.profile.settings.isExcludedArray(subkey: subkey, payloadIndex: payloadIndex)

        // ---------------------------------------------------------------------
        //  Get Indent
        // ---------------------------------------------------------------------
        self.indent = subkey.parentSubkeys?.filter { ($0.type == .dictionary && (!$0.isSingleContainer && !$0.isSinglePayloadContent) && $0.hidden == .no) }.count ?? 0

        // ---------------------------------------------------------------------
        //  Setup Static View Content
        // ---------------------------------------------------------------------
        if let textFieldTitle = EditorTextField.title(profile: self.profile, subkey: subkey, indent: self.indent, constraints: &self.cellViewConstraints, cellView: self) {
            self.textFieldTitle = textFieldTitle
        }

        if let textFieldDescription = EditorTextField.description(profile: self.profile, subkey: subkey, indent: self.indent, constraints: &self.cellViewConstraints, cellView: self) {
            self.textFieldDescription = textFieldDescription
        }

        if let textFieldMessage = EditorTextField.message(profile: self.profile, subkey: subkey, payloadIndex: payloadIndex, indent: self.indent, constraints: &self.cellViewConstraints, cellView: self) {
            self.textFieldMessage = textFieldMessage
        }

        if let documentationURL = subkey.documentationURL {
            let documentationButton = NSButton()
            documentationButton.translatesAutoresizingMaskIntoConstraints = false
            documentationButton.image = NSImage(named: "DocumentationDeSelected")
            documentationButton.alternateImage = NSImage(named: "Documentation")
            documentationButton.toolTip = documentationURL.absoluteString
            documentationButton.bezelStyle = .texturedRounded
            documentationButton.setButtonType(.momentaryChange)
            documentationButton.isBordered = false
            documentationButton.isTransparent = false
            documentationButton.target = self
            documentationButton.action = #selector(self.clickedDocumentation(_:))
            documentationButton.imageScaling = .scaleProportionallyUpOrDown
            documentationButton.imagePosition = .imageOnly

            self.imageViewDocumentation = documentationButton

            // ---------------------------------------------------------------------
            //  Add text field to cell view
            // ---------------------------------------------------------------------
            self.addSubview(documentationButton)

            // ---------------------------------------------------------------------
            //  Setup Layout Constraings for TextField
            // ---------------------------------------------------------------------
            let indentValue: CGFloat = 8.0 + (16.0 * CGFloat(self.indent))

            // Leading
            self.cellViewConstraints.append(NSLayoutConstraint(item: documentationButton,
                                                               attribute: .leading,
                                                               relatedBy: .equal,
                                                               toItem: self,
                                                               attribute: .leading,
                                                               multiplier: 1.0,
                                                               constant: indentValue + 1.0))

            // Width
            self.cellViewConstraints.append(NSLayoutConstraint(item: documentationButton,
                                                               attribute: .width,
                                                               relatedBy: .equal,
                                                               toItem: nil,
                                                               attribute: .notAnAttribute,
                                                               multiplier: 1.0,
                                                               constant: 12.0))

            // Width == Height
            self.cellViewConstraints.append(NSLayoutConstraint(item: documentationButton,
                                                               attribute: .width,
                                                               relatedBy: .equal,
                                                               toItem: documentationButton,
                                                               attribute: .height,
                                                               multiplier: 1.0,
                                                               constant: 0.0))
        }

        if subkey.substitutionVariables != nil {
            let svButton = NSButton()
            svButton.translatesAutoresizingMaskIntoConstraints = false
            svButton.image = NSImage(named: "SubstitutionVariablesDeSelected")
            svButton.alternateImage = NSImage(named: "SubstitutionVariables")
            // svButton.toolTip = documentationURL.absoluteString
            svButton.bezelStyle = .texturedRounded
            svButton.setButtonType(.momentaryChange)
            svButton.isBordered = false
            svButton.isTransparent = false
            svButton.target = self
            svButton.action = #selector(self.clickedSubstitutionVariables(_:))
            svButton.imageScaling = .scaleProportionallyUpOrDown
            svButton.imagePosition = .imageOnly

            self.imageViewSubstitutionVariables = svButton

            // ---------------------------------------------------------------------
            //  Add text field to cell view
            // ---------------------------------------------------------------------
            self.addSubview(svButton)

            // ---------------------------------------------------------------------
            //  Setup Layout Constraings for TextField
            // ---------------------------------------------------------------------
            let indentValue: CGFloat = 8.0 + (16.0 * CGFloat(self.indent))

            // Leading
            self.cellViewConstraints.append(NSLayoutConstraint(item: svButton,
                                                               attribute: .leading,
                                                               relatedBy: .equal,
                                                               toItem: self.imageViewDocumentation ?? self,
                                                               attribute: self.imageViewDocumentation != nil ? .trailing : .leading,
                                                               multiplier: 1.0,
                                                               constant: self.imageViewDocumentation != nil ? 5.0 : indentValue + 1.0))

            // Width
            self.cellViewConstraints.append(NSLayoutConstraint(item: svButton,
                                                               attribute: .width,
                                                               relatedBy: .equal,
                                                               toItem: nil,
                                                               attribute: .notAnAttribute,
                                                               multiplier: 1.0,
                                                               constant: 12.0))

            // Width == Height
            self.cellViewConstraints.append(NSLayoutConstraint(item: svButton,
                                                               attribute: .width,
                                                               relatedBy: .equal,
                                                               toItem: svButton,
                                                               attribute: .height,
                                                               multiplier: 1.0,
                                                               constant: 0.0))
        }

        if let box = EditorBox.with(profile: self.profile, subkey: subkey, indent: self.indent, constraints: &self.cellViewConstraints, cellView: self) {
            self.boxNote = box
        }

        if let textFieldFooter = EditorTextField.footer(profile: self.profile, subkey: subkey, indent: self.indent, constraints: &self.cellViewConstraints, cellView: self) {
            self.textFieldFooter = textFieldFooter
        }

        // ---------------------------------------------------------------------
        //  Add value import processor if set
        // ---------------------------------------------------------------------
        if let valueImportProcessorIdentifier = subkey.valueImportProcessor, let valueImportProcessor = ValueImportProcessors.shared.processor(withIdentifier: valueImportProcessorIdentifier) {
            self.valueImportProcessor = valueImportProcessor
        }

        // ---------------------------------------------------------------------
        //  Add value info processor if set
        // ---------------------------------------------------------------------
        if let valueInfoProcessorIdentifier = subkey.valueInfoProcessor, let valueInfoProcessor = ValueInfoProcessors.shared.processor(withIdentifier: valueInfoProcessorIdentifier) {
            self.valueInfoProcessor = valueInfoProcessor
        }

        // ---------------------------------------------------------------------
        //  Add spacing to bottom
        // ---------------------------------------------------------------------
        self.updateHeight(6.0)
    }

    // MARK: -
    // MARK: PayloadCellView Methods

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = PayloadCellView(subkey: self.subkey, payloadIndex: self.payloadIndex, enabled: self.isEnabled, required: self.isRequired, editor: self.profileEditor)
        return copy
    }

    func updateHeight(_ height: CGFloat) {
        self.height += height
    }

    func enable(_ enable: Bool) {
        fatalError("This function: \(#function) should never be called on the superclass.")
    }

    func indentValue() -> CGFloat {
        8.0 + (16.0 * CGFloat(self.indent))
    }

    @objc func clickedDocumentation(_ button: NSButton) {
        guard let urlString = button.toolTip, let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    @objc func clickedSubstitutionVariables(_ button: NSButton) {
        let popOver = PayloadCellViewPopOver(frame: button.frame)
        popOver.showSubstitutionVariables(for: self.subkey, inView: self)
    }

    @objc func toggleTitle(sender: NSGestureRecognizer) {
        if let toolTip = self.textFieldTitle?.toolTip {
            if self.subkey.platformsDeprecated != .none || self.subkey.appDeprecated != nil {
                let attributedTitle = self.profile.settings.attributedTitleString(forSubkey: self.subkey, cellView: self)
                let attributedTitleKey = self.profile.settings.attributedTitleKeyString(forSubkey: self.subkey, cellView: self)

                // FIXME: This should be made easier and more lightweight. Like using a tag to know what string to show for example.

                if
                    let attributesOfFirstCharacter = self.textFieldTitle?.attributedStringValue.attributes(at: 0, effectiveRange: nil),
                    let firstCharacterColorRaw = attributesOfFirstCharacter[.foregroundColor] as? NSColor,
                    let firstCharacterSanitizedColor = firstCharacterColorRaw.usingColorSpace(.genericRGB),
                    let firstCharacterColorHex = firstCharacterSanitizedColor.colorCode(type: .hex),
                    let blackColor = NSColor.black.usingColorSpace(.genericRGB),
                    let blackColorHex = blackColor.colorCode(type: .hex) {
                    if firstCharacterColorHex == blackColorHex {
                        self.textFieldTitle?.attributedStringValue = attributedTitleKey
                    } else {
                        self.textFieldTitle?.attributedStringValue = attributedTitle
                    }
                }

            } else {
                if toolTip == self.textFieldTitle?.stringValue {
                    self.textFieldTitle?.textColor = self.textFieldTitle?.textColor == .brown ? .labelColor : .brown
                } else {
                    self.textFieldTitle?.toolTip = self.textFieldTitle?.stringValue
                    self.textFieldTitle?.stringValue = toolTip
                    self.textFieldTitle?.textColor = toolTip == self.subkey.key ? .brown : .labelColor
                }

                if self.isEnabled, self.isExcludedArray != nil {
                    if let titleTextColor = self.textFieldTitle?.textColor {
                        self.textFieldTitle?.textColor = titleTextColor.withAlphaComponent(0.3)
                    }
                }
            }
        }
    }

    func showAlert(withError error: Error) {
        self.showAlert(withMessage: error.localizedDescription)
    }

    func showAlert(withMessage message: String) {
        guard let window = self.window else { return }
        let alert = NSAlert()
        alert.messageText = message
        alert.beginSheetModal(for: window) { _ in }
    }

    func showPrompt(withMessage message: String, informativeText: String, firstButton: String = ButtonTitle.ok, secondButton: String? = nil, thirdButton: String? = nil, returnValue: @escaping (NSApplication.ModalResponse) -> Void) {
        guard let window = self.window else { return }
        let alert = Alert()
        alert.showAlert(message: message,
                        informativeText: informativeText,
                        window: window,
                        firstButtonTitle: firstButton,
                        secondButtonTitle: secondButton,
                        thirdButtonTitle: thirdButton,
                        firstButtonState: true,
                        sender: nil,
                        returnValue: returnValue)
    }
}

// MARK: -
// MARK: Setup NSLayoytConstraints

extension PayloadCellView {
    private func setup(view: NSView, belowView: NSView, spacing: CGFloat = 4.0) {

        // Top
        self.cellViewConstraints.append(NSLayoutConstraint(item: view,
                                                           attribute: .top,
                                                           relatedBy: .equal,
                                                           toItem: belowView,
                                                           attribute: .bottom,
                                                           multiplier: 1.0,
                                                           constant: spacing))
    }

    func setupFooter(belowCustomView customView: NSView?) {

        guard let view = customView ?? self.textFieldDescription ?? self.textFieldTitle else { return }

        // ---------------------------------------------------------------------
        //  Setup Footer if it is set
        // ---------------------------------------------------------------------
        if let imageViewDocumentation = self.imageViewDocumentation {
            self.setup(view: imageViewDocumentation, belowView: self.textFieldMessage ?? view, spacing: 5.0)
            self.updateHeight(5.0 + 14.0)
        }

        if let imageViewSubstitutionVariables = self.imageViewSubstitutionVariables {
            self.setup(view: imageViewSubstitutionVariables, belowView: self.textFieldMessage ?? view, spacing: 5.0)
            if self.imageViewDocumentation == nil {
                self.updateHeight(5.0 + 14.0)
            }
        }

        if let textFieldFooter = self.textFieldFooter {
            self.setup(view: textFieldFooter, belowView: self.textFieldMessage ?? view)
            if self.imageViewDocumentation == nil, self.imageViewSubstitutionVariables == nil {
                self.updateHeight(4.0 + 14.0)
            }
        }

        let previousView = self.textFieldFooter ?? self.imageViewDocumentation ?? view

        if let textFieldMessage = self.textFieldMessage {
            self.setup(view: textFieldMessage, belowView: previousView)
            self.updateHeight(4.0 + textFieldMessage.intrinsicContentSize.height)
        }

        if let boxNote = self.boxNote {
            self.setup(view: boxNote, belowView: self.textFieldMessage ?? previousView, spacing: 10.0)
            self.updateHeight(10.0 + boxNote.fittingSize.height)
        }
    }
}

// MARK: -
// MARK: Add NSLayoytConstraints

extension PayloadCellView {
    func addConstraints(forViewBelow viewBelow: NSView) {
        if let textFieldDescription = self.textFieldDescription {
            self.cellViewConstraints.append(NSLayoutConstraint(item: viewBelow,
                                                               attribute: .top,
                                                               relatedBy: .equal,
                                                               toItem: textFieldDescription,
                                                               attribute: .bottom,
                                                               multiplier: 1.0,
                                                               constant: 7.0))

            self.updateHeight(7.0 + viewBelow.intrinsicContentSize.height)
        } else if let textFieldTitle = self.textFieldTitle {
            self.cellViewConstraints.append(NSLayoutConstraint(item: viewBelow,
                                                               attribute: .top,
                                                               relatedBy: .equal,
                                                               toItem: textFieldTitle,
                                                               attribute: .bottom,
                                                               multiplier: 1.0,
                                                               constant: 7.0))

            self.updateHeight(7.0 + viewBelow.intrinsicContentSize.height)
        } else {
            self.cellViewConstraints.append(NSLayoutConstraint(item: viewBelow,
                                                               attribute: .top,
                                                               relatedBy: .equal,
                                                               toItem: self,
                                                               attribute: .top,
                                                               multiplier: 1.0,
                                                               constant: 3.0))

            self.updateHeight(3.0 + viewBelow.intrinsicContentSize.height)
        }
    }

    func addConstraints(forViewLeading viewLeading: NSView) {
        self.cellViewConstraints.append(NSLayoutConstraint(item: viewLeading,
                                                           attribute: .leading,
                                                           relatedBy: .equal,
                                                           toItem: self,
                                                           attribute: .leading,
                                                           multiplier: 1.0,
                                                           constant: self.indentValue()))
    }

    func addConstraints(forViewTrailing viewTrailing: NSView) {
        self.cellViewConstraints.append(NSLayoutConstraint(item: self,
                                                           attribute: .trailing,
                                                           relatedBy: .equal,
                                                           toItem: viewTrailing,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 8.0))
    }
}

// MARK: -
// MARK: Update NSLayoytConstraints

extension PayloadCellView {
    func updateConstraints(forViewLeadingTitle viewLeading: NSView) {

        guard let textFieldTitle = self.textFieldTitle else { return }

        // ---------------------------------------------------------------------
        //  Update the textFields preferredMaxLayoutWidht so no text will be clipped
        // ---------------------------------------------------------------------
        let currentHeight = textFieldTitle.intrinsicContentSize.height
        textFieldTitle.preferredMaxLayoutWidth -= viewLeading.intrinsicContentSize.width
        if currentHeight < textFieldTitle.intrinsicContentSize.height {
            self.height += (textFieldTitle.intrinsicContentSize.height - currentHeight)
        }

        // ---------------------------------------------------------------------
        //  Remove current leading constraint from TextField Title
        // ---------------------------------------------------------------------
        self.cellViewConstraints = self.cellViewConstraints.filter {
            if let firstItem = $0.firstItem as? NSTextField, firstItem == self.textFieldTitle, $0.firstAttribute == .leading {
                return false
            } else {
                return true
            }
        }

        // Leading
        self.cellViewConstraints.append(NSLayoutConstraint(item: textFieldTitle,
                                                           attribute: .leading,
                                                           relatedBy: .equal,
                                                           toItem: viewLeading,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 6.0))

        // Baseline
        self.cellViewConstraints.append(NSLayoutConstraint(item: textFieldTitle,
                                                           attribute: .firstBaseline,
                                                           relatedBy: .equal,
                                                           toItem: viewLeading,
                                                           attribute: .firstBaseline,
                                                           multiplier: 1.0,
                                                           constant: 3.0))

        let heightDifference = viewLeading.intrinsicContentSize.height - textFieldTitle.intrinsicContentSize.height
        if 0 < heightDifference {
            self.updateHeight(heightDifference)
        }
    }
}
