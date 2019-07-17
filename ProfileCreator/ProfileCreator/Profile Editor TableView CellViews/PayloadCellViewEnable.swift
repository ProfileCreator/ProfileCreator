//
//  PayloadCellViewEnable.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

enum CheckboxCellViewTag: Int {
    case add
    case remove
    case edit
}

class PayloadCellViewEnable: NSTableCellView, CheckboxCellView {

    unowned var cellView: PayloadCellView
    unowned var subkey: PayloadSubkey
    unowned var editor: ProfileEditor
    unowned var profile: Profile

    // MARK: -
    // MARK: Instance Variables

    var checkbox: NSButton?
    var buttonEdit: NSButton?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(cellView: PayloadCellView, payloadIndex: Int, editor: ProfileEditor) {

        self.cellView = cellView
        self.subkey = cellView.subkey
        self.editor = editor
        self.profile = editor.profile

        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup Custom View Content
        // ---------------------------------------------------------------------
        let enabled = cellView.isEnabled
        if enabled {
            self.checkbox = EditorCheckbox.remove(cellView: self)
            self.setupCheckboxRemove(constraints: &constraints)
        } else {
            self.checkbox = EditorCheckbox.add(cellView: self)
            self.setupCheckboxAdd(constraints: &constraints)
        }

        // self.buttonEdit = EditorCheckbox.edit(cellView: self)
        // self.setupCheckboxEdit(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Set Required (also if it's a dictionary without the value as key)
        // ---------------------------------------------------------------------
        if !(subkey is PayloadManagedPreferenceLocalSubkey) {
            if profile.settings.isRequired(subkey: cellView.subkey, ignoreConditionals: false, payloadIndex: payloadIndex) ||
                ( cellView.subkey.type == .dictionary && cellView.subkey.typeInput == cellView.subkey.type && !cellView.subkey.subkeys.contains(where: {
                    $0.key == ManifestKeyPlaceholder.key || ( $0.type != .dictionary && self.profile.settings.isRequired(subkey: $0, ignoreConditionals: false, payloadIndex: payloadIndex))
                })) {
                self.checkbox?.isHidden = true
            }
        }

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: -
    // MARK: CheckboxCellView Functions

    func clicked(_ checkbox: NSButton) {

        // NOTE: This method of tags only works because the cellviews are recreated on each reload.
        //       To increase efficiency they should probably be reused, and if that happens this has to be updated
        // editor.updateViewSettings(value: checkbox.state == .on ? true : false, key: SettingsKey.enabled, subkey: subkey)

        switch checkbox.tag {
        case CheckboxCellViewTag.add.rawValue:
            self.profile.settings.setViewValue(enabled: true, forSubkey: self.subkey, payloadIndex: self.editor.selectedPayloadIndex)
        case CheckboxCellViewTag.remove.rawValue:
            self.profile.settings.setViewValue(enabled: false, forSubkey: self.subkey, payloadIndex: self.editor.selectedPayloadIndex)
        case CheckboxCellViewTag.edit.rawValue:
            guard let selectedPayloadPlaceholder = self.editor.selectedPayloadPlaceholder else { return }
            self.editor.editKey(self.subkey, forPayloadPlaceholder: selectedPayloadPlaceholder)
            return
        default:
            Log.shared.error(message: "Unknown button tag: \(checkbox.tag)", category: String(describing: self))
        }

        self.editor.reloadTableView(updateCellViews: true)
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewEnable {

    private func setupCheckboxRemove(constraints: inout [NSLayoutConstraint]) {
        guard let checkbox = self.checkbox else { return }

        // ---------------------------------------------------------------------
        //  Set Checkbox Tag
        // ---------------------------------------------------------------------
        checkbox.tag = CheckboxCellViewTag.remove.rawValue

        // ---------------------------------------------------------------------
        //  Add Checkbox to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(checkbox)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        var topConstant: CGFloat = 3.3

        if self.subkey.typeInput == .bool {
            topConstant = 3.6
        }

        // Top
        constraints.append(NSLayoutConstraint(item: checkbox,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: topConstant))

        // Center X
        constraints.append(NSLayoutConstraint(item: checkbox,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerX,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }

    private func setupCheckboxAdd(constraints: inout [NSLayoutConstraint]) {
        guard let checkbox = self.checkbox else { return }

        // ---------------------------------------------------------------------
        //  Set Checkbox Tag
        // ---------------------------------------------------------------------
        checkbox.tag = CheckboxCellViewTag.add.rawValue

        // ---------------------------------------------------------------------
        //  Add Checkbox to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(checkbox)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        var topConstant: CGFloat = 3.2

        if self.subkey.typeInput == .bool {
            topConstant = 4.0
        }

        // Top
        constraints.append(NSLayoutConstraint(item: checkbox,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: topConstant))

        // Center X
        constraints.append(NSLayoutConstraint(item: checkbox,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerX,
                                              multiplier: 1.0,
                                              constant: 0))
    }

    private func setupCheckboxEdit(constraints: inout [NSLayoutConstraint]) {
        guard
            let checkbox = self.checkbox,
            let buttonEdit = self.buttonEdit else { return }

        // ---------------------------------------------------------------------
        //  Set Checkbox Tag
        // ---------------------------------------------------------------------
        buttonEdit.tag = CheckboxCellViewTag.edit.rawValue

        // ---------------------------------------------------------------------
        //  Add Checkbox to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(buttonEdit)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: buttonEdit,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: checkbox,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 5.0))

        // Center X
        constraints.append(NSLayoutConstraint(item: buttonEdit,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerX,
                                              multiplier: 1.0,
                                              constant: 0))
    }
}
