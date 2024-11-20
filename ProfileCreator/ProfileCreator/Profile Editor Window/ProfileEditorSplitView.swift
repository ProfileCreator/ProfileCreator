//
//  ProfileEditorSplitView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ProfileEditorSplitView: NSSplitView {

    // MARK: -
    // MARK: Variables

    var editor: ProfileEditor?
    let editorView = NSView()

    var librarySplitView: PayloadLibrarySplitView?

    let libraryFilter = PayloadLibraryFilter()
    var libraryFilterConstraints = [NSLayoutConstraint]()
    var libraryMenuConstraints = [NSLayoutConstraint]()

    let libraryView = NSView()
    let libraryViewLine = NSBox()

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(profile: Profile) {
        self.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup SplitView
        // ---------------------------------------------------------------------
        self.identifier = NSUserInterfaceItemIdentifier(rawValue: "ProfileEditorWindowSplitView-ID")
        self.translatesAutoresizingMaskIntoConstraints = false
        self.dividerStyle = .thin
        self.isVertical = true
        self.delegate = self

        // ---------------------------------------------------------------------
        //  Add subviews to splitview
        // ---------------------------------------------------------------------
        let editor = ProfileEditor(profile: profile)
        self.editor = editor

        let librarySplitView = PayloadLibrarySplitView(profile: profile, editor: editor)
        self.librarySplitView = librarySplitView

        librarySplitView.tableViews?.libraryFilter = self.libraryFilter
        self.libraryFilter.setActionTarget(tableViews: librarySplitView.tableViews)

        // ---------------------------------------------------------------------
        //  Add subviews to splitview
        // ---------------------------------------------------------------------
        setupSplitViewLibrary(constraints: &constraints)
        setupSplitViewEditor(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Activate layout constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    // MARK: -
    // MARK: Instance Functions

    public func showLibraryMenu(view: NSView, show: Bool) {
        if show {
            if self.libraryView.subviews.contains(self.libraryFilter.view) { self.libraryFilter.view.removeFromSuperview() }
            if self.libraryView.subviews.contains(self.libraryViewLine) { self.libraryViewLine.removeFromSuperview() }
            self.libraryView.addSubview(view)
            if self.libraryMenuConstraints.isEmpty {
                self.setupLibraryMenu(view: view)
            }
            NSLayoutConstraint.activate(self.libraryMenuConstraints)
        } else {
            if self.libraryView.subviews.contains(view) { view.removeFromSuperview() }
            self.libraryView.addSubview(self.libraryFilter.view)
            self.libraryView.addSubview(self.libraryViewLine)
            NSLayoutConstraint.activate(self.libraryFilterConstraints)
        }
    }

    // MARK: -
    // MARK: Setup Layout Constraints

    private func setupLibraryMenu(view: NSView) {

        guard let librarySplitView = self.librarySplitView else {
            // TODO: Proper Logging
            return
        }

        // Height
        self.libraryMenuConstraints.append(NSLayoutConstraint(item: view,
                                                              attribute: .height,
                                                              relatedBy: .equal,
                                                              toItem: nil,
                                                              attribute: .notAnAttribute,
                                                              multiplier: 1,
                                                              constant: 27))

        // Top
        self.libraryMenuConstraints.append(NSLayoutConstraint(item: librarySplitView,
                                                              attribute: .bottom,
                                                              relatedBy: .equal,
                                                              toItem: view,
                                                              attribute: .top,
                                                              multiplier: 1,
                                                              constant: 0))

        // Leading
        self.libraryMenuConstraints.append(NSLayoutConstraint(item: view,
                                                              attribute: .leading,
                                                              relatedBy: .equal,
                                                              toItem: self.libraryView,
                                                              attribute: .leading,
                                                              multiplier: 1,
                                                              constant: 0))

        // Trailing
        self.libraryMenuConstraints.append(NSLayoutConstraint(item: view,
                                                              attribute: .trailing,
                                                              relatedBy: .equal,
                                                              toItem: self.libraryView,
                                                              attribute: .trailing,
                                                              multiplier: 1,
                                                              constant: 0))

        // Bottom
        self.libraryMenuConstraints.append(NSLayoutConstraint(item: view,
                                                              attribute: .bottom,
                                                              relatedBy: .equal,
                                                              toItem: self.libraryView,
                                                              attribute: .bottom,
                                                              multiplier: 1,
                                                              constant: 0))

    }

    private func setupSplitViewEditor(constraints: inout [NSLayoutConstraint]) {

        guard let editor = self.editor else {
            // TODO: Proper Logging
            return
        }

        self.addSubview(editor.editorView)
        self.setHoldingPriority(NSLayoutConstraint.Priority.defaultLow, forSubviewAt: 1)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Width
        constraints.append(NSLayoutConstraint(item: editor.editorView,
                                              attribute: .width,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: (kEditorTableViewColumnPayloadWidth + (kEditorTableViewColumnPaddingWidth * 2))))
    }

    private func setupSplitViewLibrary(constraints: inout [NSLayoutConstraint]) {

        guard let librarySplitView = self.librarySplitView else {
            // TODO: Proper Logging
            return
        }

        // ---------------------------------------------------------------------
        //  Setup Library View
        // ---------------------------------------------------------------------
        self.libraryView.translatesAutoresizingMaskIntoConstraints = false

        // ---------------------------------------------------------------------
        //  Add constraints for Library View
        // ---------------------------------------------------------------------
        // Width Min
        constraints.append(NSLayoutConstraint(item: self.libraryView,
                                              attribute: .width,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 150))

        // Width Max
        constraints.append(NSLayoutConstraint(item: self.libraryView,
                                              attribute: .width,
                                              relatedBy: .lessThanOrEqual,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 300))

        // ---------------------------------------------------------------------
        //  Add Library SplitView to Library View
        // ---------------------------------------------------------------------
        self.libraryView.addSubview(librarySplitView)

        // ---------------------------------------------------------------------
        //  Add constraints for Library SplitView
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: librarySplitView,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.libraryView,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 0))

        // Leading
        constraints.append(NSLayoutConstraint(item: librarySplitView,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.libraryView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: librarySplitView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.libraryView,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0))

        // ---------------------------------------------------------------------
        //  Setup and add separator line between SplitView and Filter
        // ---------------------------------------------------------------------
        self.libraryViewLine.translatesAutoresizingMaskIntoConstraints = false
        self.libraryViewLine.boxType = .separator
        self.libraryView.addSubview(self.libraryViewLine)

        // ---------------------------------------------------------------------
        //  Add constraints for Library SplitView
        // ---------------------------------------------------------------------
        // Top
        self.libraryFilterConstraints.append(NSLayoutConstraint(item: librarySplitView,
                                                                attribute: .bottom,
                                                                relatedBy: .equal,
                                                                toItem: self.libraryViewLine,
                                                                attribute: .top,
                                                                multiplier: 1,
                                                                constant: 0))

        // Leading
        self.libraryFilterConstraints.append(NSLayoutConstraint(item: self.libraryViewLine,
                                                                attribute: .leading,
                                                                relatedBy: .equal,
                                                                toItem: self.libraryView,
                                                                attribute: .leading,
                                                                multiplier: 1,
                                                                constant: 0))

        // Trailing
        self.libraryFilterConstraints.append(NSLayoutConstraint(item: self.libraryViewLine,
                                                                attribute: .trailing,
                                                                relatedBy: .equal,
                                                                toItem: self.libraryView,
                                                                attribute: .trailing,
                                                                multiplier: 1,
                                                                constant: 0))

        // ---------------------------------------------------------------------
        //  Add Library Filter to Library View
        // ---------------------------------------------------------------------
        self.libraryView.addSubview(self.libraryFilter.view)

        // ---------------------------------------------------------------------
        //  Add constraints for Library Filter
        // ---------------------------------------------------------------------
        // Height
        self.libraryFilterConstraints.append(NSLayoutConstraint(item: self.libraryFilter.view,
                                                                attribute: .height,
                                                                relatedBy: .equal,
                                                                toItem: nil,
                                                                attribute: .notAnAttribute,
                                                                multiplier: 1,
                                                                constant: 27))

        // Top
        self.libraryFilterConstraints.append(NSLayoutConstraint(item: self.libraryViewLine,
                                                                attribute: .bottom,
                                                                relatedBy: .equal,
                                                                toItem: self.libraryFilter.view,
                                                                attribute: .top,
                                                                multiplier: 1,
                                                                constant: 0))

        // Leading
        self.libraryFilterConstraints.append(NSLayoutConstraint(item: self.libraryFilter.view,
                                                                attribute: .leading,
                                                                relatedBy: .equal,
                                                                toItem: self.libraryView,
                                                                attribute: .leading,
                                                                multiplier: 1,
                                                                constant: 0))

        // Trailing
        self.libraryFilterConstraints.append(NSLayoutConstraint(item: self.libraryFilter.view,
                                                                attribute: .trailing,
                                                                relatedBy: .equal,
                                                                toItem: self.libraryView,
                                                                attribute: .trailing,
                                                                multiplier: 1,
                                                                constant: 0))

        // Bottom
        self.libraryFilterConstraints.append(NSLayoutConstraint(item: self.libraryFilter.view,
                                                                attribute: .bottom,
                                                                relatedBy: .equal,
                                                                toItem: self.libraryView,
                                                                attribute: .bottom,
                                                                multiplier: 1,
                                                                constant: 0))

        constraints.append(contentsOf: self.libraryFilterConstraints)

        self.addSubview(self.libraryView)
        self.setHoldingPriority((NSLayoutConstraint.Priority(rawValue: NSLayoutConstraint.Priority.RawValue(Int(NSLayoutConstraint.Priority.defaultLow.rawValue) + 1))), forSubviewAt: 0)
    }

}

extension ProfileEditorSplitView: NSSplitViewDelegate {

    /*
     ///////////////////////////////////////////////////////////////////////////////
     ////////////                        WARNING                        ////////////
     ///////////////////////////////////////////////////////////////////////////////

     Don't use any of the following NSSPlitView delegate methods as they don't
     work with AutoLayout.

     splitView:constrainMinCoordinate:ofSubviewAt:
     splitView:constrainMaxCoordinate:ofSubviewAt:
     splitView:resizeSubviewsWithOldSize:
     splitView:shouldAdjustSizeOfSubview:

     https://developer.apple.com/library/mac/releasenotes/AppKit/RN-AppKitOlderNotes/#10_8AutoLayout
     */

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {

        // ---------------------------------------------------------------------
        //  Allow left view (SIDEBAR) to be collapsed
        // ---------------------------------------------------------------------
        // if subview == splitView.subviews.first && splitView.subviews.contains(self.tableViewController.scrollView) {
        return true
        // }
        // return false
    }

    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {

        // ---------------------------------------------------------------------
        //  Hide left divider if left view is collapsed
        // ---------------------------------------------------------------------
        // TODO: Use this if we add a button to show/hide the sidebar. For now, leave the divider visible
        /*
         if dividerIndex == 0 {
         return splitView.isSubviewCollapsed(splitView.subviews.first!)
         }
         */
        return false
    }
}
