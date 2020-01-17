//
//  PayloadCellViewItemPopUpButton.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class EditorComboBox {

    class func withTitles(titles: [String],
                          cellView: NSComboBoxDelegate) -> NSComboBox {

        // ---------------------------------------------------------------------
        //  Create and setup ComboBox
        // ---------------------------------------------------------------------
        let comboBox = NSComboBox()
        comboBox.translatesAutoresizingMaskIntoConstraints = false
        comboBox.target = cellView
        comboBox.delegate = cellView
        comboBox.addItems(withObjectValues: titles)

        return comboBox
    }
}
