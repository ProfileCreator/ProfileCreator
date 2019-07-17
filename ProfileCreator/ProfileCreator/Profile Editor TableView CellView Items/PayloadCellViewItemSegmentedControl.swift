//
//  PayloadCellViewItemPopUpButton.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class EditorSegmentedControl {

    class func withSegments(cellView: SegmentedControlCellView) -> NSSegmentedControl {

        // ---------------------------------------------------------------------
        //  Create and setup Checkbox
        // ---------------------------------------------------------------------
        let segmentedControl = PayloadSegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.segmentStyle = .texturedRounded
        segmentedControl.trackingMode = .selectOne
        segmentedControl.action = #selector(cellView.selectSegment(_:))
        segmentedControl.target = cellView

        return segmentedControl
    }
}
