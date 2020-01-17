//
//  PayloadCellViewItemDatePicker.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class EditorSlider {

    class func slider(cellView: PayloadCellView & SliderCellView) -> NSSlider {

        // ---------------------------------------------------------------------
        //  Create and setup Slider
        // ---------------------------------------------------------------------
        let slider = NSSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.sliderType = .linear
        slider.tickMarkPosition = .below
        slider.target = cellView
        slider.action = #selector(cellView.selected(_:))

        return slider
    }
}
