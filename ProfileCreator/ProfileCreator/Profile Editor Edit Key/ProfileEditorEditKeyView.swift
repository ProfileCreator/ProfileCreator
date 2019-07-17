//
//  ProfileEditorEditKeyView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class ProfileEditorEditKeyView: NSView {

    // MARK: -
    // MARK: Constant Variables

    let buttonSave = NSButton()
    let buttonCancel = NSButton()

    let editorWindow: NSWindow

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(payloadSubkey: PayloadSubkey?, payloadPlaceholder: PayloadPlaceholder, editorWindow: NSWindow) {
        self.editorWindow = editorWindow

        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup Views
        // ---------------------------------------------------------------------
        self.setupView(constraints: &constraints)
        self.setupButtonSave(constraints: &constraints)
        self.setupButtonCancel(constraints: &constraints)

        if let subkey = payloadSubkey {
            Swift.print("Current Dictionary: \(subkey.dictionary)")
        }

        // ---------------------------------------------------------------------
        //  Activate layout constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: -
    // MARK: Actions

    @objc func clicked(_ button: NSButton) {
        guard let sheetWindow = self.window else { return }
        if button.title == ButtonTitle.save {
            self.editorWindow.endSheet(sheetWindow, returnCode: .OK)
            return
        }
        self.editorWindow.endSheet(sheetWindow, returnCode: .cancel)
    }

    // MARK: -
    // MARK: Setup

    func setupView(constraints: inout [NSLayoutConstraint]) {
        self.translatesAutoresizingMaskIntoConstraints = false

        // Width
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: 600.0))

        // Height
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: 300.0))
    }

    func setupButtonCancel(constraints: inout [NSLayoutConstraint]) {
        self.buttonCancel.translatesAutoresizingMaskIntoConstraints = false
        self.buttonCancel.bezelStyle = .rounded
        self.buttonCancel.setButtonType(.momentaryPushIn)
        self.buttonCancel.isBordered = true
        self.buttonCancel.isTransparent = false
        self.buttonCancel.title = ButtonTitle.cancel
        self.buttonCancel.target = self
        self.buttonCancel.action = #selector(self.clicked(_:))
        self.buttonCancel.sizeToFit()

        // ---------------------------------------------------------------------
        //  Add Button to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.buttonCancel)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.buttonSave,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.buttonCancel,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 6.0))

        // Center Y
        constraints.append(NSLayoutConstraint(item: self.buttonCancel,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.buttonSave,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }

    func setupButtonSave(constraints: inout [NSLayoutConstraint]) {
        self.buttonSave.translatesAutoresizingMaskIntoConstraints = false
        self.buttonSave.bezelStyle = .rounded
        self.buttonSave.setButtonType(.momentaryPushIn)
        self.buttonSave.isBordered = true
        self.buttonSave.isTransparent = false
        self.buttonSave.title = ButtonTitle.save
        self.buttonSave.keyEquivalent = "\r"
        self.buttonSave.target = self
        self.buttonSave.action = #selector(self.clicked(_:))
        self.buttonSave.sizeToFit()

        // ---------------------------------------------------------------------
        //  Add Button to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.buttonSave)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.buttonSave,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 12.0))

        // Top
        constraints.append(NSLayoutConstraint(item: self.buttonSave,
                                              attribute: .top,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: 16.0))

        // Bottom
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self.buttonSave,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 12.0))

        // Width
        constraints.append(NSLayoutConstraint(item: self.buttonSave,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: self.buttonCancel,
                                              attribute: .width,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }
}
