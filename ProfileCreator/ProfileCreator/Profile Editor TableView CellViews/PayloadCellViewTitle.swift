//
//  PayloadCellViewPadding.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewTitle: NSTableCellView, ProfileCreatorCellView {

    // MARK: -
    // MARK: PayloadCellView Variables

    var height: CGFloat = 0.0
    var textFieldTitle: NSTextField?
    var textFieldDescription: NSTextField?
    var separatorTop: NSBox?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(title titleString: String?, description descriptionString: String?) {
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup Static View Content
        // ---------------------------------------------------------------------
        if let title = titleString, !title.isEmpty {
            self.setupTextField(title: title, constraints: &constraints)
        }

        if let description = descriptionString, !description.isEmpty {
            self.setupTextField(description: description, constraints: &constraints)
        }

        let separatorLeft = NSBox(frame: NSRect(x: 250.0, y: 15.0, width: kPreferencesWindowWidth - (20.0 + 20.0), height: 250.0))
        separatorLeft.translatesAutoresizingMaskIntoConstraints = false
        separatorLeft.boxType = .separator
        self.setup(separator: separatorLeft, alignment: .left, constraints: &constraints)

        let separatorRight = NSBox(frame: NSRect(x: 250.0, y: 15.0, width: kPreferencesWindowWidth - (20.0 + 20.0), height: 250.0))
        separatorRight.translatesAutoresizingMaskIntoConstraints = false
        separatorRight.boxType = .separator
        self.setup(separator: separatorRight, alignment: .right, constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add spacing to bottom
        // ---------------------------------------------------------------------
        self.updateHeight(14.0)

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    convenience init(payload: Payload) {
        self.init(title: payload.title, description: payload.description)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    func updateHeight(_ height: CGFloat) {
        self.height += height
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewTitle {

    private func setupTextField(title: String, constraints: inout [NSLayoutConstraint]) {

        let textFieldTitle = NSTextField()
        textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        textFieldTitle.lineBreakMode = .byWordWrapping
        textFieldTitle.isBordered = false
        textFieldTitle.isBezeled = false
        textFieldTitle.drawsBackground = false
        textFieldTitle.isEditable = false
        textFieldTitle.isSelectable = false
        textFieldTitle.textColor = .labelColor
        textFieldTitle.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
        textFieldTitle.stringValue = title
        textFieldTitle.alignment = .center
        textFieldTitle.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        self.textFieldTitle = textFieldTitle

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(textFieldTitle)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: 8.0))
        self.updateHeight(8 + textFieldTitle.intrinsicContentSize.height)

        // Center X
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerX,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 8.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))
    }

    private func setupTextField(description: String, constraints: inout [NSLayoutConstraint]) {

        let textFieldDescription = NSTextField()
        textFieldDescription.translatesAutoresizingMaskIntoConstraints = false
        textFieldDescription.lineBreakMode = .byWordWrapping
        textFieldDescription.isBordered = false
        textFieldDescription.isBezeled = false
        textFieldDescription.drawsBackground = false
        textFieldDescription.isEditable = false
        textFieldDescription.isSelectable = false
        textFieldDescription.textColor = .labelColor
        textFieldDescription.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
        textFieldDescription.stringValue = description
        textFieldDescription.alignment = .center
        textFieldDescription.font = NSFont.systemFont(ofSize: 15, weight: .ultraLight)
        self.textFieldDescription = textFieldDescription

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(textFieldDescription)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        if let textFieldTitle = self.textFieldTitle {
            constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: textFieldTitle,
                                                  attribute: .bottom,
                                                  multiplier: 1.0,
                                                  constant: 6.0))
            self.updateHeight(6 + textFieldDescription.intrinsicContentSize.height)
        } else {
            constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: self,
                                                  attribute: .top,
                                                  multiplier: 1.0,
                                                  constant: 8.0))
            self.updateHeight(8 + textFieldDescription.intrinsicContentSize.height)
        }

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 8.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textFieldDescription,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))
    }

    private func setup(separator: NSBox, alignment: NSLayoutConstraint.Attribute, constraints: inout [NSLayoutConstraint]) {

        guard let textFieldTitle = self.textFieldTitle else { return }

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(separator)

        // Center Y
        constraints.append(NSLayoutConstraint(item: separator,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 0.0))

        if alignment == .left {

            // Leading
            constraints.append(NSLayoutConstraint(item: separator,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: self,
                                                  attribute: .leading,
                                                  multiplier: 1,
                                                  constant: 8.0))

            // Trailing
            constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: separator,
                                                  attribute: .trailing,
                                                  multiplier: 1,
                                                  constant: 8.0))
        } else {

            // Leading
            constraints.append(NSLayoutConstraint(item: separator,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: textFieldTitle,
                                                  attribute: .trailing,
                                                  multiplier: 1,
                                                  constant: 8.0))

            // Trailing
            constraints.append(NSLayoutConstraint(item: separator,
                                                  attribute: .trailing,
                                                  relatedBy: .equal,
                                                  toItem: self,
                                                  attribute: .trailing,
                                                  multiplier: 1,
                                                  constant: 8.0))

        }
    }
}
