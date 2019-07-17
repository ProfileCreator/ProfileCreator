//
//  PayloadCellViewItemCheckbox.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class EditorCheckbox {

    class func title(_ title: String, tag: Int, cellView: CheckboxCellView) -> NSButton {

        // ---------------------------------------------------------------------
        //  Create and setup Checkbox
        // ---------------------------------------------------------------------
        let checkbox = PayloadButton()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.setButtonType(.switch)
        checkbox.action = #selector(cellView.clicked(_:))
        checkbox.target = cellView
        checkbox.title = title
        checkbox.tag = tag

        return checkbox
    }

    class func noTitle(cellView: CheckboxCellView) -> NSButton {

        // ---------------------------------------------------------------------
        //  Create and setup Checkbox
        // ---------------------------------------------------------------------
        let checkbox = PayloadButton()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.setButtonType(.switch)
        checkbox.action = #selector(cellView.clicked(_:))
        checkbox.target = cellView
        checkbox.title = ""

        return checkbox
    }

    class func add(cellView: CheckboxCellView) -> NSButton {
        let checkbox = PayloadButton()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.bezelStyle = .roundRect
        checkbox.setButtonType(.momentaryPushIn)
        checkbox.isBordered = false
        checkbox.isTransparent = false
        checkbox.image = NSImage(named: NSImage.addTemplateName)
        checkbox.imageScaling = .scaleProportionallyDown
        checkbox.action = #selector(cellView.clicked(_:))
        checkbox.target = cellView
        checkbox.title = ""
        checkbox.toolTip = NSLocalizedString("Include payload key in payload.", comment: "")

        return checkbox
    }

    class func remove(cellView: CheckboxCellView) -> NSButton {
        let checkbox = PayloadButton()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.bezelStyle = .roundRect
        checkbox.setButtonType(.momentaryPushIn)
        checkbox.isBordered = false
        checkbox.isTransparent = false
        checkbox.image = NSImage(named: NSImage.stopProgressTemplateName)
        checkbox.imageScaling = .scaleProportionallyDown
        checkbox.action = #selector(cellView.clicked(_:))
        checkbox.target = cellView
        checkbox.title = ""
        checkbox.toolTip = NSLocalizedString("Exclude payload key from payload.", comment: "")

        return checkbox
    }

    class func edit(cellView: CheckboxCellView) -> NSButton {
        let checkbox = PayloadButton()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.bezelStyle = .roundRect
        checkbox.setButtonType(.momentaryPushIn)
        checkbox.isBordered = false
        checkbox.isTransparent = false
        checkbox.image = NSImage(named: "Edit")
        checkbox.imageScaling = .scaleProportionallyDown
        checkbox.action = #selector(cellView.clicked(_:))
        checkbox.target = cellView
        checkbox.title = ""
        checkbox.toolTip = NSLocalizedString("Edit payload key.", comment: "")

        return checkbox
    }
}
