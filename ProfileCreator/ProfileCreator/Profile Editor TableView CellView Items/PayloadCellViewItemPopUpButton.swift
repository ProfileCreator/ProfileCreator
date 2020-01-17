//
//  PayloadCellViewItemPopUpButton.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class EditorPopUpButton {

    class func withTitles(titles: [String],
                          cellView: PopUpButtonCellView) -> NSPopUpButton {

        // ---------------------------------------------------------------------
        //  Create and setup Checkbox
        // ---------------------------------------------------------------------
        let popUpButton = PayloadPopUpButton()
        popUpButton.translatesAutoresizingMaskIntoConstraints = false
        popUpButton.action = #selector(cellView.selected(_:))
        popUpButton.target = cellView
        popUpButton.addItems(withTitles: titles)

        return popUpButton
    }
}
