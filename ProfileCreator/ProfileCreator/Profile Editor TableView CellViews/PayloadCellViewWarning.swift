//
//  PayloadCellViewPadding.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewWarning: NSTableCellView, ProfileCreatorCellView {

    // MARK: -
    // MARK: PayloadCellView Variables

    var height: CGFloat = 0.0
    var textFieldMessage: NSTextField?
    let separatorTop = NSBox()
    let separatorBottom = NSBox()

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message messageString: String?) {
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup Static View Content
        // ---------------------------------------------------------------------
        if let message = messageString, !description.isEmpty {
            self.setupTextField(message: message, constraints: &constraints)
        }

        self.separatorTop.translatesAutoresizingMaskIntoConstraints = false
        self.separatorTop.boxType = .separator
        self.setup(separator: self.separatorTop, alignment: .top, constraints: &constraints)

        self.separatorBottom.translatesAutoresizingMaskIntoConstraints = false
        self.separatorBottom.boxType = .separator
        self.setup(separator: self.separatorBottom, alignment: .bottom, constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add spacing to bottom
        // ---------------------------------------------------------------------
        self.updateHeight(12.0)

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    func updateHeight(_ height: CGFloat) {
        self.height += height
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewWarning {

    private func setupTextField(message: String, constraints: inout [NSLayoutConstraint]) {

        let textFieldMessage = NSTextField()
        textFieldMessage.translatesAutoresizingMaskIntoConstraints = false
        textFieldMessage.lineBreakMode = .byWordWrapping
        textFieldMessage.isBordered = false
        textFieldMessage.isBezeled = false
        textFieldMessage.drawsBackground = false
        textFieldMessage.isEditable = false
        textFieldMessage.isSelectable = false
        textFieldMessage.textColor = .systemRed
        textFieldMessage.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
        textFieldMessage.stringValue = message
        textFieldMessage.alignment = .center
        textFieldMessage.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        self.textFieldMessage = textFieldMessage

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(textFieldMessage)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: textFieldMessage,
                                                attribute: .top,
                                                relatedBy: .equal,
                                                toItem: self.separatorTop,
                                                attribute: .top,
                                                multiplier: 1.0,
                                                constant: 4.0))
        self.updateHeight(4.0 + textFieldMessage.intrinsicContentSize.height)

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldMessage,
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
                                              toItem: textFieldMessage,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))
    }

    private func setup(separator: NSBox, alignment: NSLayoutConstraint.Attribute, constraints: inout [NSLayoutConstraint]) {

        guard let textFieldMessage = self.textFieldMessage else { return }

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(separator)

        switch alignment {
        case .top:

            // Top
            constraints.append(NSLayoutConstraint(item: separator,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: self,
                                                  attribute: .top,
                                                  multiplier: 1,
                                                  constant: 12.0))

            self.height += 12.0 + separator.intrinsicContentSize.height

            // Leading
            constraints.append(NSLayoutConstraint(item: self,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: separator,
                                                  attribute: .leading,
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

        case .bottom:

            // Bottom
            constraints.append(NSLayoutConstraint(item: separator,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: textFieldMessage,
                                                  attribute: .bottom,
                                                  multiplier: 1,
                                                  constant: 4.0))

            self.height += 12.0 + separator.intrinsicContentSize.height

            // Leading
            constraints.append(NSLayoutConstraint(item: self,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: separator,
                                                  attribute: .leading,
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

        default:
            Log.shared.error(message: "Unhandled alignment: \(alignment)", category: String(describing: self))
        }
    }
}
