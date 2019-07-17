//
//  PayloadCellViewItems.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class EditorTableView {

    class func scrollView(height: CGFloat, constraints: inout [NSLayoutConstraint], target: NSTableViewDataSource & NSTableViewDelegate, cellView: NSView) -> NSScrollView {

        // ---------------------------------------------------------------------
        //  Create and setup TextField
        // ---------------------------------------------------------------------
        let tableView = NSTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.focusRingType = .none
        tableView.rowSizeStyle = .default
        tableView.floatsGroupRows = false
        tableView.allowsMultipleSelection = false
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.dataSource = target
        tableView.delegate = target
        tableView.target = target
        tableView.allowsColumnReordering = false
        tableView.sizeLastColumnToFit()

        // ---------------------------------------------------------------------
        //  Setup ScrollView
        // ---------------------------------------------------------------------
        let scrollView = NSScrollView(frame: NSRect.zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = true
        cellView.addSubview(scrollView)

        // ---------------------------------------------------------------------
        //  Setup Layout Constraings for ScrollView
        // ---------------------------------------------------------------------

        // Height
        constraints.append(NSLayoutConstraint(item: scrollView,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: height))

        if let payloadCellView = cellView as? PayloadCellView {
            payloadCellView.updateHeight(height)
        }

        return scrollView
    }
}
