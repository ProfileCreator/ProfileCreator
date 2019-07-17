//
//  PayloadCellViewItemCheckbox.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class EditorRadioButton {

    class func withTitle(title: String,
                         index: Int,
                         identifier: NSUserInterfaceItemIdentifier,
                         cellView: RadioButtonsCellView) -> NSButton {

        // ---------------------------------------------------------------------
        //  Create and setup Checkbox
        // ---------------------------------------------------------------------
        let radioButton = PayloadButton()
        radioButton.translatesAutoresizingMaskIntoConstraints = false
        radioButton.setButtonType(.radio)
        radioButton.action = #selector(cellView.clicked(_:))
        radioButton.target = cellView
        radioButton.identifier = identifier
        radioButton.title = title
        radioButton.tag = index

        return radioButton
    }
}
