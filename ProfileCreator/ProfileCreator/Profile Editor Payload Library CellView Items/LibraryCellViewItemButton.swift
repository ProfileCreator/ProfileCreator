//
//  LibraryCellViewItemButton.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class LibraryButton {

    class func toggle(image: NSImage?,
                      width: CGFloat,
                      indent: CGFloat,
                      constraints: inout [NSLayoutConstraint],
                      cellView: PayloadLibraryCellView) -> NSButton {

        // ---------------------------------------------------------------------
        //  Create and setup Button
        // ---------------------------------------------------------------------
        let button = NSButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .regularSquare
        button.setButtonType(.momentaryChange)
        button.isBordered = false
        button.isTransparent = false
        button.imagePosition = .imageOnly
        button.image = image
        // NSImage(named: NSImageNameAddTemplate)
        // FIXME: HIGHLIFTS!
        // button.target = cellView
        // button.action = #selector(cellView.togglePayload(_:))
        button.sizeToFit()
        button.setContentHuggingPriority(NSLayoutConstraint.Priority.defaultHigh, for: .horizontal)
        button.isHidden = true

        // ---------------------------------------------------------------------
        //  Add ImageView to cell view
        // ---------------------------------------------------------------------
        cellView.addSubview(button)

        // ---------------------------------------------------------------------
        //  Setup Layout Constraings for text field
        // ---------------------------------------------------------------------
        // Leading
        constraints.append(NSLayoutConstraint(item: button,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: cellView,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: indent))

        // Center Y
        constraints.append(NSLayoutConstraint(item: button,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: cellView,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Width
        constraints.append(NSLayoutConstraint(item: button,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: width))

        // Height == Width
        constraints.append(NSLayoutConstraint(item: button,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: button,
                                              attribute: .width,
                                              multiplier: 1.0,
                                              constant: 0.0))

        return button
    }
}
