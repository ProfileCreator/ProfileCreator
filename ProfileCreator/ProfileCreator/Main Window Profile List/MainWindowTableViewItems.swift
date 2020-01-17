//
//  MainWindowTableViewItems.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class MainWindowTableViewCellView {

    var title: String?
    var identifier: UUID?

    func cellView(title: String, identifier: UUID, payloadCount: Int, errorCount: Int, versionFormatSupported: Bool) -> NSTableCellView {

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()
        self.title = title
        self.identifier = identifier

        // ---------------------------------------------------------------------
        //  Create new CellView instance
        // ---------------------------------------------------------------------
        let cellView = NSTableCellView()

        // ---------------------------------------------------------------------
        //  Create and add TextField Title
        // ---------------------------------------------------------------------
        let textFieldTitle = NSTextField()
        textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        textFieldTitle.lineBreakMode = .byTruncatingTail
        textFieldTitle.isBordered = false
        textFieldTitle.isBezeled = false
        textFieldTitle.drawsBackground = false
        textFieldTitle.isEditable = false
        textFieldTitle.font = NSFont.boldSystemFont(ofSize: 12)
        textFieldTitle.textColor = versionFormatSupported ? .labelColor : .secondaryLabelColor
        textFieldTitle.alignment = .left
        textFieldTitle.stringValue = title
        setup(textFieldTitle: textFieldTitle, cellView: cellView, constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Create and add TextField Description
        // ---------------------------------------------------------------------
        let textFieldDescription = NSTextField()
        textFieldDescription.translatesAutoresizingMaskIntoConstraints = false
        textFieldDescription.lineBreakMode = .byTruncatingTail
        textFieldDescription.isBordered = false
        textFieldDescription.isBezeled = false
        textFieldDescription.drawsBackground = false
        textFieldDescription.isEditable = false
        textFieldDescription.font = NSFont.systemFont(ofSize: 10)
        textFieldDescription.textColor = .secondaryLabelColor
        textFieldDescription.alignment = .left
        if versionFormatSupported {
        if payloadCount == 1 {
            textFieldDescription.stringValue = NSLocalizedString("\(payloadCount) Payload", comment: "")
        } else {
            textFieldDescription.stringValue = NSLocalizedString("\(payloadCount) Payloads", comment: "")
        }
        } else {
            textFieldDescription.stringValue = NSLocalizedString("Legacy Save Format", comment: "")
            textFieldDescription.textColor = .systemRed
        }
        setup(textFieldDescription: textFieldDescription, textFieldTitle: textFieldTitle, cellView: cellView, constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)

        return cellView
    }

    // MARK: -
    // MARK: Setup Layout Constraints

    func setup(textFieldTitle: NSTextField, cellView: NSTableCellView, constraints: inout [NSLayoutConstraint]) {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        cellView.addSubview(textFieldTitle)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Top
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: cellView,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 2))

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: cellView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 11))

        // Trailing
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: cellView,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 6))
    }

    func setup(textFieldDescription: NSTextField, textFieldTitle: NSTextField, cellView: NSTableCellView, constraints: inout [NSLayoutConstraint]) {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        cellView.addSubview(textFieldDescription)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Top
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: textFieldTitle,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 1))

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: textFieldTitle,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0))
    }
}
