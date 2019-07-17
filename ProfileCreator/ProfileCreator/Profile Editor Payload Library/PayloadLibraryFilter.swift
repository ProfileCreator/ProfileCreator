//
//  PayloadLibraryFilter.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class PayloadLibraryFilter {

    // MARK: -
    // MARK: Variables

    let view = NSView()
    let searchField = NSSearchField()

    init() {

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup View
        // ---------------------------------------------------------------------
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .vertical)
        self.view.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .vertical)

        // ---------------------------------------------------------------------
        //  Create and setup SearchField
        // ---------------------------------------------------------------------
        self.searchField.translatesAutoresizingMaskIntoConstraints = false
        self.searchField.controlSize = .small
        self.searchField.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        self.searchField.placeholderString = NSLocalizedString("Filter Payloads", comment: "")
        self.searchField.sendsSearchStringImmediately = true
        setupSearchField(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    func setActionTarget(tableViews: PayloadLibraryTableViews?) {
        if let payloadLibraryTableViews = tableViews {
            self.searchField.target = payloadLibraryTableViews
            self.searchField.action = #selector(payloadLibraryTableViews.search(_:))
        }
    }
}

extension PayloadLibraryFilter {
    func setupSearchField(constraints: inout [NSLayoutConstraint]) {

        // ---------------------------------------------------------------------
        //  Add SearchField to view
        // ---------------------------------------------------------------------
        self.view.addSubview(self.searchField)

        // ---------------------------------------------------------------------
        //  Setup constraints for SearchField
        // ---------------------------------------------------------------------
        // Center Y
        constraints.append(NSLayoutConstraint(item: self.searchField,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.view,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: -1))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.searchField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.view,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 5))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.view,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.searchField,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 5))

    }
}
