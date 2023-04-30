//
//  PayloadCellViewProtocols.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

protocol ProfileCreatorCellView {
    var height: CGFloat { get set }

    func addSubview(_ subview: NSView)
}

@objc protocol CheckboxCellView {
    func clicked(_ checkbox: NSButton)
}

@objc protocol RadioButtonsCellView {
    func clicked(_ radioButton: NSButton)
}

@objc protocol SegmentedControlCellView {
    func selectSegment(_ segmentedControl: NSSegmentedControl)
}

@objc protocol PopUpButtonCellView {
    func selected(_ popUpButton: NSPopUpButton)
}

@objc protocol DatePickerCellView {
    func selectDate(_ datePicker: NSDatePicker)
}

@objc protocol SliderCellView {
    func selected(_ slider: NSSlider)
}

@objc protocol TableViewCellView: AnyObject, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {

}
