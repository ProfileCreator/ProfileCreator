//
//  PayloadCellViewTextView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewTextView: PayloadCellView, ProfileCreatorCellView, NSTextFieldDelegate {

    // MARK: -
    // MARK: Instance Variables

    var valueDefault: String?
    var scrollView: OverlayScrollView?
    var textView: NSTextView?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(subkey: PayloadSubkey, payloadIndex: Int, enabled: Bool, required: Bool, editor: ProfileEditor) {
        super.init(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: editor)

        // ---------------------------------------------------------------------
        //  Setup Custom View Content
        // ---------------------------------------------------------------------
        self.scrollView = EditorTextView.scrollView(string: "", visibleRows: 4, constraints: &self.cellViewConstraints, cellView: self)
        self.textView = self.scrollView?.documentView as? NSTextView
        self.setupScrollView()

        // ---------------------------------------------------------------------
        //  Setup Footer
        // ---------------------------------------------------------------------
        super.setupFooter(belowCustomView: self.scrollView)

        // ---------------------------------------------------------------------
        //  Set Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.valueDefault as? String {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Set Placeholder Value
        // ---------------------------------------------------------------------
        self.textView?.string = self.profile.settings.placeholderString(forSubkey: subkey, isRequired: self.isRequired, payloadIndex: payloadIndex) ?? ""

        // ---------------------------------------------------------------------
        //  Set Value
        // ---------------------------------------------------------------------
        var valueString = ""
        if let value = self.profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) as? String {
            valueString = value
        } else if let valueDefault = self.valueDefault {
            valueString = valueDefault
        }
        self.textView?.string = valueString

        // ---------------------------------------------------------------------
        //  Set TextColor (red if not matching format)
        // ---------------------------------------------------------------------
        if let format = subkey.format, !valueString.matches(format) {
            self.textView?.textColor = .systemRed
        } else {
            self.textView?.textColor = .labelColor
        }

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.scrollView
        self.trailingKeyView = self.scrollView

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.textView?.isEditable = enable
    }
}

// MARK: -
// MARK: NSTextViewDelegate Functions

extension PayloadCellViewTextView: NSTextViewDelegate {

    func textDidChange(_ notification: Notification) {
        self.isEditing = true
        if let textView = notification.object as? NSTextView {
            if let format = subkey.format, !textView.string.matches(format) {
                self.textView?.textColor = .systemRed
            } else {
                self.textView?.textColor = .labelColor
            }
            self.profile.settings.setValue(textView.string, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
        }
    }

    func textDidEndEditing(_ notification: Notification) {
        if self.isEditing {
            self.isEditing = false
            if let textView = notification.object as? NSTextView {
                if let format = subkey.format, !textView.string.matches(format) {
                    self.textView?.textColor = .systemRed
                } else {
                    self.textView?.textColor = .labelColor
                }
                self.profile.settings.setValue(textView.string, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
            }
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewTextView {

    private func setupScrollView() {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        guard let scrollView = self.scrollView else { return }
        self.addSubview(scrollView)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Below
        self.addConstraints(forViewBelow: scrollView)

        // Leading
        self.addConstraints(forViewLeading: scrollView)

        // Trailing
        self.addConstraints(forViewTrailing: scrollView)
    }
}
