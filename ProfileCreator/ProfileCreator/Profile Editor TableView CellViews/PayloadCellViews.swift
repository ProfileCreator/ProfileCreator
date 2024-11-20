//
//  PayloadCellViews.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

class PayloadCellViews {

    // FIXME: Don't know what the best method for storing this is. Using dict for now.
    // FIXME: This variable is supposed to do caching, where if nothung has change in the settings or view settings, then use the same array again.
    // FIXME: Currently nothing is cached.
    var allCellViews = [String: [NSTableCellView]]()

    func cellViews(payloadPlaceholder: PayloadPlaceholder, payloadIndex: Int, profileEditor: ProfileEditor) -> [NSTableCellView] {

        // ---------------------------------------------------------------------
        //  Initialize variables
        // ---------------------------------------------------------------------
        var cellViews = [NSTableCellView]()

        // ---------------------------------------------------------------------
        //  Reset settings cache
        // ---------------------------------------------------------------------
        profileEditor.profile.settings.resetCache()

        let subkeys: [PayloadSubkey]
        if profileEditor.profile.settings.showCustomizedKeys, let overrideSubkeys = payloadPlaceholder.payload.override?.subkeys {
            subkeys = overrideSubkeys
        } else {
            subkeys = payloadPlaceholder.payload.subkeys
        }

        // ---------------------------------------------------------------------
        //  Add all CellViews to load to the cellViews variable
        // ---------------------------------------------------------------------
        self.addCellViews(profile: profileEditor.profile,
                          subkeys: subkeys,
                          payloadIndex: payloadIndex,
                          profileEditor: profileEditor,
                          parentCellViews: nil,
                          cellViews: &cellViews)

        // ---------------------------------------------------------------------
        //  Verify we got an array of PayloadCellViews
        // ---------------------------------------------------------------------
        if var payloadCellViews = cellViews as? [PayloadCellView] {

            // ---------------------------------------------------------------------
            //  Sort required and enabled payloads to the top
            // ---------------------------------------------------------------------
            if payloadCellViews.contains(where: { $0.subkey.segments != nil }) {

                // ---------------------------------------------------------------------
                //  Get all required cellViews
                // ---------------------------------------------------------------------
                var cellViewsRequired = payloadCellViews.filter {
                    ($0.subkey.require == .alwaysNested || ($0.subkey.require == .never && $0.isRequired))
                        && $0.subkey.hidden == .no
                        && !kPayloadSubkeys.contains($0.subkey.key)
                        && $0.subkey.segments == nil
                }

                // ---------------------------------------------------------------------
                //  Get all non-required cellViews
                // ---------------------------------------------------------------------
                // FIXME: This could be done better by just returning all items not in cellViewsRequired.
                payloadCellViews = payloadCellViews.filter {
                    !(($0.subkey.require == .alwaysNested || ($0.subkey.require == .never && $0.isRequired))
                        && $0.subkey.hidden == .no
                        && !kPayloadSubkeys.contains($0.subkey.key)
                        && $0.subkey.segments == nil)
                }

                // ---------------------------------------------------------------------
                //  Find all nested required subkeys and add to cellViewsRequired
                // ---------------------------------------------------------------------
                for subkey in payloadPlaceholder.payload.allSubkeys {
                    if subkey.require == .alwaysNested
                        && subkey.hidden == .no
                        && !kPayloadSubkeys.contains(subkey.key)
                        && subkey.segments == nil
                        && !cellViewsRequired.contains(where: { $0.subkey.keyPath == subkey.keyPath }) {
                        if let cellView = self.cellView(profile: profileEditor.profile, subkey: subkey, payloadIndex: payloadIndex, profileEditor: profileEditor) {
                            cellViewsRequired.append(cellView)
                        }
                    } else if subkey.require == .never
                        && subkey.conditionals.contains(where: { $0.require == .alwaysNested })
                        && subkey.hidden == .no
                        && !kPayloadSubkeys.contains(subkey.key)
                        && subkey.segments == nil
                                && !cellViewsRequired.contains(where: { $0.subkey.keyPath == subkey.keyPath }) {
                        if let cellView = self.cellView(profile: profileEditor.profile, subkey: subkey, payloadIndex: payloadIndex, profileEditor: profileEditor) {
                            if cellView.isRequired {
                                cellViewsRequired.append(cellView)
                            }
                        }
                    }
                }

                // ---------------------------------------------------------------------
                //  Add required cellViews to the top of payloadCellViews
                // ---------------------------------------------------------------------
                if !cellViewsRequired.isEmpty {
                    var index = 0
                    for (cellViewIndex, cellView) in payloadCellViews.enumerated() {
                        if cellView.subkey.segments != nil {
                            break
                        } else if cellView.subkey.require == .always {
                            index = cellViewIndex
                        }
                    }
                    payloadCellViews.insert(contentsOf: cellViewsRequired, at: index == 0 ? 0 : index + 1)
                    cellViews = payloadCellViews
                }
            } else {

                Log.shared.debug(message: "Sorting enabled CellViews to the top", category: String(describing: self))

                // ---------------------------------------------------------------------
                //  Reset settings cache
                // ---------------------------------------------------------------------
                // FIXME: I don't know if this is a leftover or intentional... should be tested and removed if not needed.
                profileEditor.profile.settings.resetCache()

                // ---------------------------------------------------------------------
                //  Duplicate all Dictionaries with both enabled and disabled subviews.
                //  This is done to have the header available both in the enabled and disabled view.
                // ---------------------------------------------------------------------
                for dictionaryCellView in payloadCellViews.filter({ $0 is PayloadCellViewDictionary }) {
                    let childCellViews = payloadCellViews.filter {
                        if let parentCellViews = $0.parentCellViews, parentCellViews.contains(dictionaryCellView) {
                            return true
                        } else {
                            return false
                        }
                    }

                    if childCellViews.contains(where: { $0.isEnabled }) && childCellViews.contains(where: { !$0.isEnabled }), let index = payloadCellViews.firstIndex(of: dictionaryCellView) {
                        if let duplicateCellView = dictionaryCellView.copy() as? PayloadCellViewDictionary {
                            duplicateCellView.enable(!dictionaryCellView.isEnabled)
                            payloadCellViews.insert(duplicateCellView, at: index)
                        } else {
                            Log.shared.error(message: "Failed to copy dictionary cell view", category: String(describing: self))
                        }
                    }
                }

                // ---------------------------------------------------------------------
                //  Sort all enabled cellViews to the beginning of the array
                // ---------------------------------------------------------------------
                //  NOTE
                ////////////////////////////////////////////////////////////////////////
                //  The code below is to keep the current order of cellViews intact.
                //  Previously using this code moved some keys out of order:
                //      let sortedCellViews = payloadCellViews.sorted { $0.isEnabled && !$1.isEnabled }
                //  That cannot happen. If there are any more efficient or simple loops
                //  this code should be updated.
                ////////////////////////////////////////////////////////////////////////
                var sortedCellViews = [PayloadCellView]()
                var disabledCellViews = [PayloadCellView]()
                for cellView in payloadCellViews {
                    if cellView.isEnabled {
                        sortedCellViews.append(cellView)
                    } else {
                        disabledCellViews.append(cellView)
                    }
                }
                sortedCellViews.append(contentsOf: disabledCellViews)

                // ---------------------------------------------------------------------
                //  Get the index of the first disabled subkey
                // ---------------------------------------------------------------------
                Log.shared.debug(message: "Getting index of first disabled CellView", category: String(describing: self))

                if let indexDisabled = sortedCellViews.firstIndex(where: { !$0.isEnabled }) {

                    Log.shared.debug(message: "First disabled CellView index is: \(indexDisabled)", category: String(describing: self))

                    // ---------------------------------------------------------------------
                    //  Update cellViews with the sorted array
                    // ---------------------------------------------------------------------
                    cellViews = sortedCellViews

                    // ---------------------------------------------------------------------
                    //  Insert a separator cellView between the enabled and disabled
                    // ---------------------------------------------------------------------
                    if UserDefaults.standard.bool(forKey: PreferenceKey.payloadEditorShowDisabledKeysSeparator) {
                        let cellView = PayloadCellViewTitle(title: NSLocalizedString("Disabled Keys", comment: ""),
                                                            description: NSLocalizedString("The payload keys below will not be included in the exported profile", comment: "") )
                        cellViews.insert(cellView, at: indexDisabled)
                    }
                }

                if payloadPlaceholder.domain != kManifestDomainConfiguration {

                    // ---------------------------------------------------------------------
                    //  Get all enabled cellViews that are visible
                    //  (This code works because the root manifest subkeys are all required and will always be enabled, even if they aren't shown.)
                    // ---------------------------------------------------------------------
                    let enabledCellViewKeys = sortedCellViews.compactMap { $0.isEnabled ? $0.subkey.key : nil }
                    if enabledCellViewKeys.isEmpty || Array(Set(enabledCellViewKeys).subtracting(kPayloadSubkeys)).isEmpty {

                        // ---------------------------------------------------------------------
                        //  Insert a message cellView at the top with "No Payload Keys Enabled"
                        // ---------------------------------------------------------------------
                        let cellView = PayloadCellViewNoKeys(title: NSLocalizedString("No Payload Keys Enabled", comment: ""), description: "", profile: profileEditor.profile)
                        cellViews.insert(cellView, at: 0)
                    }
                }
            }
        }

        // FIXME: Temporary while testing the local manifests feature
        if payloadPlaceholder.payloadType == .managedPreferencesApplicationsLocal {
            let cellView = PayloadCellViewWarning(message: NSLocalizedString("The local preferences feature is experimental", comment: "") )
            cellViews.insert(cellView, at: 0)
        }

        // ---------------------------------------------------------------------
        //  Add padding cellViews to the top and bottom if the cellViews visible are not empty
        // ---------------------------------------------------------------------
        if !cellViews.isEmpty {
            cellViews.insert(PayloadCellViewPadding(), at: 0)
            cellViews.insert(PayloadCellViewPadding(), at: cellViews.count)
        }

        return cellViews
    }

    func addCellViews(profile: Profile,
                      subkeys: [PayloadSubkey],
                      payloadIndex: Int,
                      profileEditor: ProfileEditor,
                      parentCellViews: [PayloadCellView]?,
                      cellViews: inout [NSTableCellView] ) {

        var selectedSegmentKeys = [String]()
        var selectedSegmentKeysIgnored = [String]()

        for subkey in subkeys {

            // If any parent is an array, this should not be added by itself, but from the array subkey cellview
            if let parentSubkeys = subkey.parentSubkeys, parentSubkeys.contains(where: { $0.type == .array && $0.rangeMax as? Int != 1 }) { continue }

            // Ignore keys not in the current segment of the segment control
            if selectedSegmentKeysIgnored.contains(subkey.key) { continue }

            // Segments
            // FIXME: This is ugly, need to restructure this code to make it cleaner
            if let segments = subkey.segments {

                if !UserDefaults.standard.bool(forKey: PreferenceKey.payloadEditorShowSegmentedControls) { continue }

                if !segments.keys.isEmpty {
                    let defaultSegment = subkey.rangeListTitles != nil ? subkey.rangeListTitles!.first! : segments.keys.first!
                    // let selectedSegment = profile.settings.getPayloadValue(forKeyPath: subkey.keyPath, domain: subkey.domain, type: subkey.payloadType, payloadIndex: payloadIndex) as? String ?? defaultSegment
                    let selectedSegment = profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) as? String ?? defaultSegment
                    if segments.keys.contains(selectedSegment), let segmentKeys = segments[selectedSegment] {
                        selectedSegmentKeys.append(contentsOf: segmentKeys)
                        for key in segments.keys {
                            if key == selectedSegment { continue }
                            if let ignoredKeys = segments[key]?.compactMap({ $0 }) {
                                selectedSegmentKeysIgnored += ignoredKeys
                            }
                        }
                    }
                }
            }

            var currentCellView: PayloadCellView?

            // Ignore dictionaries that are either the only key at the root, or only contain a single subkey, or is an intermediate dict that will not be exported in an array.
            if subkey.type == .dictionary && ( subkey.isSingleContainer || subkey.isSinglePayloadContent || subkey.parentSubkey?.type == .array ) {
                Log.shared.debug(message: "Hiding container without own settings: \(subkey.keyPath) (\(subkey.isSingleContainer ? "single container" : "single payload content dict"))", category: String(describing: self))
            } else {
                if let cellView = self.cellView(profile: profile,
                                                subkey: subkey,
                                                payloadIndex: payloadIndex,
                                                // typeSettings: typeSettings,
                                                profileEditor: profileEditor) {

                    if let pCellViews = parentCellViews {
                        cellView.parentCellViews = pCellViews
                    }

                    cellViews.append(cellView)

                    currentCellView = cellView
                }
            }

            if subkey.type != subkey.typeInput, subkey.typeInput == .array, subkey.subkeys.count == 1 {
                Log.shared.debug(message: "Hiding array checkbox container: \(subkey.keyPath) subkeys as they are already used in the container view.", category: "")
            } else if !subkey.subkeys.contains(where: { $0.key == ManifestKeyPlaceholder.key }) {

                var pCellViews = parentCellViews ?? [PayloadCellView]()
                if let cCellView = currentCellView {
                    pCellViews.append(cCellView)
                }

                self.addCellViews(profile: profile,
                                  subkeys: subkey.subkeys,
                                  payloadIndex: payloadIndex,
                                  // typeSettings: typeSettings,
                                  profileEditor: profileEditor,
                                  parentCellViews: pCellViews,
                                  cellViews: &cellViews)
            }
        }
    }

    func cellView(profile: Profile,
                  subkey: PayloadSubkey,
                  payloadIndex: Int,
                  profileEditor: ProfileEditor) -> PayloadCellView? {

        // Check if subkey is hidden
        if !profile.settings.showHiddenKeys, (subkey.hidden != .no || ( subkey.domain != kManifestDomainConfiguration && !subkey.enabledDefault && kPayloadSubkeys.contains(subkey.key) ) ) {
            return nil
        }

        // Check if subkey is enabled
        let enabled = profile.settings.isEnabled(subkey, onlyByUser: false, ignoreConditionals: false, payloadIndex: payloadIndex)
        if !profile.settings.showDisabledKeys, !enabled {
            return nil
        }

        // Check if subkey is required
        let required = profile.settings.isRequired(subkey: subkey, ignoreConditionals: false, isEnabledOnlyByUser: false, payloadIndex: payloadIndex)

        // Check if subkey is only available on supervised devices
        if subkey.supervised {
            if !profile.settings.showSupervisedKeys {
                return nil
            } else if ProfilePayloads.platformsSupervised.intersection(subkey.platforms).isDisjoint(with: profile.settings.platforms) {
                return nil
            }
        }

        // Check if subkey is only available on user approved devices
        if subkey.userApproved {
            if !profile.settings.showUserApprovedKeys {
                return nil
            } else if ProfilePayloads.platformsUserApproved.intersection(subkey.platforms).isDisjoint(with: profile.settings.platforms) {
                return nil
            }
        }

        // Check if subkey is available in the selected platforms
        if !profile.settings.isAvailableForSelectedPlatform(subkey: subkey) { return nil }

        // Check if a static view was set
        if let view = subkey.view {
            switch view {
            case "slider":
                if subkey.rangeList?.count ?? 0 <= 20 {
                    return PayloadCellViewSlider(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
                }
            default:
                Log.shared.error(message: "Unknown pfm_view setting: \(view)", category: String(describing: self))
            }
        }

        // If the type is an array with a single item and has specified boolean as an input type, then use an array of checkboxes to display the content
        if subkey.isSingleContainer && ((subkey.type == .array && subkey.typeInput == .bool) || (subkey.type == .integer && subkey.typeInput == .array) ) {
            return PayloadCellViewCheckboxArray(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
        }

        // If it contains a range list, or if range min and max are specified and the range isn't more than rangeListConvertMax, then use a popUpButton instead
        if let rangeList = subkey.rangeList, subkey.typeInput != .bool, ((subkey.rangeMin == nil || subkey.rangeMin == nil) || rangeList.count <= ProfilePayloads.rangeListConvertMax) {
            if subkey.rangeListAllowCustomValue, subkey.typeInput == subkey.type {
                return PayloadCellViewComboBox(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
            } else {
                return PayloadCellViewPopUpButton(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
            }
        }

        // If pfm_segments is specified for the key, use a segmented control.
        if subkey.segments != nil {
            return PayloadCellViewSegmentedControl(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
            /*
            if segmentedControl.segmentedControls.count <= 2 {
                return segmentedControl
            } else {
              return PayloadCellViewPopUpButtonSegments(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
            }
 */
        }

        switch subkey.typeInput {
        case .array:
            if let rangeMax = subkey.rangeMax as? Int, rangeMax == 1 {
                return PayloadCellViewDictionary(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
            } else {
                return PayloadCellViewTableView(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
            }
        case .string:
            if subkey.rangeMax != nil {
                return PayloadCellViewTextView(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
            } else {
                return PayloadCellViewTextField(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
            }
        case .bool:
            if subkey.rangeListTitles != nil {
                return PayloadCellViewRadioButtons(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
            } else {
                return PayloadCellViewCheckbox(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
            }
        case .integer, .float:
            return PayloadCellViewTextFieldNumber(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
        // case .float:
        //    return PayloadCellViewSlider(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
        case .date:
            return PayloadCellViewDatePicker(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
        case .data:
            return PayloadCellViewFile(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
        case .dictionary:
            if subkey.subkeys.contains(where: { $0.key == ManifestKeyPlaceholder.key }) {
                return PayloadCellViewTableView(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
            } else {
                return PayloadCellViewDictionary(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: profileEditor)
            }
        default:
            Log.shared.error(message: "Unknown PayloadValueType: \(subkey.typeInput) for subkey: \(subkey.keyPath)", category: String(describing: self))
        }
        return nil
    }
}
