//
//  PreferencesEditor.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import Highlightr

class PreferencesEditor: PreferencesItem {

    // MARK: -
    // MARK: Variables

    let identifier: NSToolbarItem.Identifier = .preferencesEditor
    let toolbarItem: NSToolbarItem
    let view: PreferencesView

    // MARK: -
    // MARK: Initialization

    init(sender: PreferencesWindowController) {

        // ---------------------------------------------------------------------
        //  Create the toolbar item
        // ---------------------------------------------------------------------
        self.toolbarItem = NSToolbarItem(itemIdentifier: identifier)
        self.toolbarItem.image = NSImage(named: NSImage.preferencesGeneralName)
        self.toolbarItem.label = NSLocalizedString("Editor", comment: "")
        self.toolbarItem.paletteLabel = self.toolbarItem.label
        self.toolbarItem.toolTip = self.toolbarItem.label
        self.toolbarItem.target = sender
        self.toolbarItem.action = #selector(sender.toolbarItemSelected(_:))

        // ---------------------------------------------------------------------
        //  Create the preferences view
        // ---------------------------------------------------------------------
        self.view = PreferencesEditorView()
    }
}

class PreferencesEditorView: NSView, PreferencesView {

    // MARK: -
    // MARK: Variables

    var height: CGFloat = 0.0

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: NSRect.zero)

        self.translatesAutoresizingMaskIntoConstraints = false

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()
        var lastSubview: NSView?

        // ---------------------------------------------------------------------
        //  Add Preferences "Editor"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Editor", comment: ""),
                                controlSize: .regular,
                                withSeparator: true,
                                toView: self,
                                lastSubview: nil,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Disabled Keys Separator", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.payloadEditorShowDisabledKeysSeparator,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Segmented Controls", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.payloadEditorShowSegmentedControls,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Payload Key as Title", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.payloadEditorShowKeyAsTitle,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add Preferences "XML"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("XML", comment: ""),
                                controlSize: .regular,
                                withSeparator: true,
                                toView: self,
                                lastSubview: lastSubview,
                                height: &self.height,
                                constraints: &constraints)

        if let highlightr = Highlightr() {
            lastSubview = addPopUpButton(label: NSLocalizedString("Syntax Highlight Theme:", comment: ""),
                                         titles: highlightr.availableThemes().sorted(),
                                         bindTo: UserDefaults.standard,
                                         bindKeyPath: PreferenceKey.payloadEditorSyntaxHighlightTheme,
                                         toView: self,
                                         lastSubview: lastSubview,
                                         lastTextField: nil,
                                         height: &self.height,
                                         indent: kPreferencesIndent,
                                         constraints: &constraints)
        }

        lastSubview = addColorWell(label: NSLocalizedString("Background Color:", comment: ""),
                                   bindTo: UserDefaults.standard,
                                   bindKeyPath: PreferenceKey.payloadEditorSyntaxHighlightBackgroundColor,
                                   toView: self,
                                   lastSubview: lastSubview,
                                   lastTextField: lastSubview,
                                   height: &self.height,
                                   indent: kPreferencesIndent,
                                   constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add constraints to last view
        // ---------------------------------------------------------------------
        // Bottom
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: lastSubview,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 20))

        self.height += 20.0

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }
}
