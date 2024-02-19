//
//  ProfileEditorTabView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ProfileEditorTab: NSView {

    // MARK: -
    // MARK: Variables

    let borderRight = NSBox(frame: NSRect(x: 250.0, y: 15.0, width: kPreferencesWindowWidth - (20.0 * 2), height: 250.0))
    let borderBottom = NSBox()
    let buttonClose = NSButton()
    let textFieldTitle = NSTextField()
    let textFieldErrorCount = NSTextField()

    var color = NSColor.clear
    let colorSelected = NSColor.controlBackgroundColor
    let colorDeSelected = NSColor.quaternaryLabelColor // NSColor.black.withAlphaComponent(0.08)
    let colorDeSelectedMouseOver = NSColor.tertiaryLabelColor // NSColor.black.withAlphaComponent(0.14)

    var trackingArea: NSTrackingArea?

    @objc var isSelected = false
    let isSelectedSelector: String

    var index: Int {
        if let stackView = self.superview as? NSStackView {
            return stackView.views.firstIndex(of: self) ?? -1
        }
        return -1
    }

    weak var editor: ProfileEditor?

    // MARK: -
    // MARK: Initialization

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(editor: ProfileEditor) {

        // ---------------------------------------------------------------------
        //  Initialize Key/Value Observing Selector Strings
        // ---------------------------------------------------------------------
        self.isSelectedSelector = NSStringFromSelector(#selector(getter: self.isSelected))

        // ---------------------------------------------------------------------
        //  Initialize Superclass
        // ---------------------------------------------------------------------
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()
        self.editor = editor

        // ---------------------------------------------------------------------
        //  Setup TabView
        // ---------------------------------------------------------------------
        self.setupButtonClose(constraints: &constraints)
        self.setupTextFieldTitle(constraints: &constraints)
        self.setupTextFieldErrorCount(constraints: &constraints) // Currently unused
        self.setupBorderBottom(constraints: &constraints)
        self.setupBorderRight(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add Notification Observers
        // ---------------------------------------------------------------------
        self.addObserver(self, forKeyPath: self.isSelectedSelector, options: .new, context: nil)

        // ---------------------------------------------------------------------
        //  Activate layout constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    deinit {
        self.removeObserver(self, forKeyPath: self.isSelectedSelector, context: nil)
    }

    func selectTab() {
        if let editor = self.editor {
            editor.select(tab: self.index)
        }
    }

    // MARK: -
    // MARK: Key/Value Observing Functions

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == self.isSelectedSelector {
            self.borderBottom.isHidden = self.isSelected
            if self.isSelected {
                self.color = self.colorSelected
            } else {
                self.color = self.colorDeSelected
            }
            self.display()
        }
    }

    // MARK: -
    // MARK: Button Functions

    @objc func clicked(button: NSButton) {
        if let editor = self.editor {
            editor.close(tab: self.index)
        }
    }
}

// MARK: -
// MARK: NSView Methods

extension ProfileEditorTab {
    override func draw(_ dirtyRect: NSRect) {
        self.color.set()
        self.bounds.fill()
    }

    override func updateTrackingAreas() {

        // ---------------------------------------------------------------------
        //  Remove previous tracking area if it was set
        // ---------------------------------------------------------------------
        if let trackingArea = self.trackingArea {
            self.removeTrackingArea(trackingArea)
        }

        // ---------------------------------------------------------------------
        //  Create a new tracking area
        // ---------------------------------------------------------------------
        let trackingOptions = NSTrackingArea.Options(rawValue: (NSTrackingArea.Options.mouseEnteredAndExited.rawValue | NSTrackingArea.Options.activeAlways.rawValue))
        self.trackingArea = NSTrackingArea(rect: self.bounds, options: trackingOptions, owner: self, userInfo: nil)

        // ---------------------------------------------------------------------
        //  Add the new tracking area to the button
        // ---------------------------------------------------------------------
        self.addTrackingArea(self.trackingArea!)
    }
}

// MARK: -
// MARK: Mouse Events

extension ProfileEditorTab {
    override func mouseDown(with event: NSEvent) {
        self.selectTab()
    }

    override func mouseEntered(with event: NSEvent) {
        self.buttonClose.isHidden = false
        if !self.isSelected {
            self.color = self.colorDeSelectedMouseOver
            self.display()
        }
    }

    override func mouseExited(with event: NSEvent) {
        self.buttonClose.isHidden = true
        if self.isSelected {
            self.color = self.colorSelected
        } else {
            self.color = self.colorDeSelected
        }
        self.display()
    }
}

extension ProfileEditorTab {
    func setupButtonClose(constraints: inout [NSLayoutConstraint]) {
        self.buttonClose.translatesAutoresizingMaskIntoConstraints = false
        self.buttonClose.bezelStyle = .roundRect
        self.buttonClose.setButtonType(.momentaryPushIn)
        self.buttonClose.isBordered = false
        self.buttonClose.isTransparent = false
        self.buttonClose.image = NSImage(named: NSImage.stopProgressTemplateName)
        self.buttonClose.imageScaling = .scaleProportionallyUpOrDown
        self.buttonClose.action = #selector(self.clicked(button:))
        self.buttonClose.target = self
        self.buttonClose.isHidden = true

        // ---------------------------------------------------------------------
        //  Add and to superview
        // ---------------------------------------------------------------------
        self.addSubview(self.buttonClose)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // CenterY
        constraints.append(NSLayoutConstraint(item: self.buttonClose,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.buttonClose,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 6.0))

        // Width
        constraints.append(NSLayoutConstraint(item: self.buttonClose,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: 8.0))

        // Width == Height
        constraints.append(NSLayoutConstraint(item: self.buttonClose,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: self.buttonClose,
                                              attribute: .height,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }

    internal func setupBorderBottom(constraints: inout [NSLayoutConstraint]) {
        self.borderBottom.translatesAutoresizingMaskIntoConstraints = false
        self.borderBottom.boxType = .separator

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.borderBottom)

        // ---------------------------------------------------------------------
        //  Add Constraints
        // ---------------------------------------------------------------------

        // Bottom
        constraints.append(NSLayoutConstraint(item: self.borderBottom,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 0.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.borderBottom,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.borderBottom,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0.0))

    }

    internal func setupBorderRight(constraints: inout [NSLayoutConstraint]) {
        self.borderRight.translatesAutoresizingMaskIntoConstraints = false
        self.borderRight.boxType = .separator

        self.setContentCompressionResistancePriority(.required, for: .vertical)

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.borderRight)

        // ---------------------------------------------------------------------
        //  Add Constraints
        // ---------------------------------------------------------------------

        // Height
        constraints.append(NSLayoutConstraint(item: self.borderRight,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 22.0))

        // Right
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .right,
                                              relatedBy: .equal,
                                              toItem: self.borderRight,
                                              attribute: .right,
                                              multiplier: 1,
                                              constant: 0.5))

        // Top
        constraints.append(NSLayoutConstraint(item: self.borderRight,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 0.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.borderRight,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 0.0))

    }

    func setupTextFieldTitle(constraints: inout [NSLayoutConstraint]) {
        self.textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldTitle.lineBreakMode = .byTruncatingTail
        self.textFieldTitle.isBordered = false
        self.textFieldTitle.isBezeled = false
        self.textFieldTitle.drawsBackground = false
        self.textFieldTitle.isEditable = false
        self.textFieldTitle.isSelectable = false
        self.textFieldTitle.textColor = .labelColor
        self.textFieldTitle.alignment = .center
        self.textFieldTitle.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .small), weight: .regular)
        self.textFieldTitle.stringValue = "Payload"

        // ---------------------------------------------------------------------
        //  Add and to superview
        // ---------------------------------------------------------------------
        self.addSubview(self.textFieldTitle)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // CenterY
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.buttonClose,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 4.0))
    }

    func setupTextFieldErrorCount(constraints: inout [NSLayoutConstraint]) {
        self.textFieldErrorCount.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldErrorCount.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldErrorCount.lineBreakMode = .byTruncatingTail
        self.textFieldErrorCount.isBordered = false
        self.textFieldErrorCount.isBezeled = false
        self.textFieldErrorCount.drawsBackground = false
        self.textFieldErrorCount.isEditable = false
        self.textFieldErrorCount.isSelectable = false
        self.textFieldErrorCount.textColor = .labelColor
        self.textFieldErrorCount.alignment = .center
        self.textFieldErrorCount.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .small), weight: .regular)
        self.textFieldErrorCount.textColor = .systemRed
        self.textFieldErrorCount.stringValue = "0"
        self.textFieldErrorCount.isHidden = true

        // ---------------------------------------------------------------------
        //  Add and to superview
        // ---------------------------------------------------------------------
        self.addSubview(self.textFieldErrorCount)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // CenterY
        constraints.append(NSLayoutConstraint(item: self.textFieldErrorCount,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.textFieldErrorCount,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 4.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldErrorCount,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 6.0))
    }
}
