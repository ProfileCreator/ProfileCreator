//
//  PayloadCellViewDatePicker.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewSegmentedControl: PayloadCellView, ProfileCreatorCellView, SegmentedControlCellView {

    // MARK: -
    // MARK: Instance Variables

    var segmentedControls = [NSSegmentedControl]()
    var valueDefault: String?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(subkey: PayloadSubkey, payloadIndex: Int, enabled: Bool, required: Bool, editor: ProfileEditor) {
        super.init(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: editor)

        // ---------------------------------------------------------------------
        //  Clear out all previous views as we will not need them, but we need to be a PayloadCellView so this was easiest. Could rework this if more views like this special view is introduced.
        // ---------------------------------------------------------------------
        if let textFieldTitle = self.textFieldTitle {
            textFieldTitle.removeFromSuperview()
            self.textFieldTitle = nil
        }

        if let textFieldDescription = self.textFieldDescription {
            textFieldDescription.removeFromSuperview()
            self.textFieldDescription = nil
        }

        if let textFieldMessage = self.textFieldMessage {
            textFieldMessage.removeFromSuperview()
            self.textFieldMessage = nil
        }

        self.height = 0
        self.cellViewConstraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup Custom View Content
        // ---------------------------------------------------------------------
        guard let segments = subkey.segments else { return }
        self.setupSegmentedControls(withSegments: segments) // (segmentedControl: segmentedControl)

        // ---------------------------------------------------------------------
        //  Set Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.valueDefault as? String {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Set Value
        // ---------------------------------------------------------------------
        var value = self.valueDefault
        if let payloadValue = self.profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) as? String {
            value = payloadValue
        }

        // ---------------------------------------------------------------------
        //  Select the current segment
        // ---------------------------------------------------------------------
        segmentLoop: for segmentedControl in self.segmentedControls {
            for index in 0..<segmentedControl.segmentCount where segmentedControl.label(forSegment: index) == value {
                if #available(OSX 10.13, *) {
                    segmentedControl.selectSegment(withTag: index)
                } else {
                    segmentedControl.setSelected(true, forSegment: index)
                }
                break segmentLoop
            }
        }

        if !self.segmentedControls.contains(where: { -1 < $0.selectedSegment }) {
            if #available(OSX 10.13, *) {
                self.segmentedControls.first!.selectSegment(withTag: 0)
            } else {
                self.segmentedControls.first!.setSelected(true, forSegment: 0)
            }
        }

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.segmentedControls.first
        self.trailingKeyView = self.segmentedControls.last

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)

        // ---------------------------------------------------------------------
        //  Add spacing to bottom
        // ---------------------------------------------------------------------
        self.updateHeight(17.0)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.segmentedControls.forEach { $0.isEnabled = true }
    }

    func selectSegment(_ segmentedControl: NSSegmentedControl) {
        if let selectedSegment = segmentedControl.label(forSegment: segmentedControl.selectedSegment) {
            self.profile.settings.setValue(selectedSegment, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
            self.profileEditor.reloadTableView(updateCellViews: true)
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewSegmentedControl {

    private func setupSegmentedControls(withSegments segments: [String: [String]]) {

        var currentSegmentedControl: NSSegmentedControl = EditorSegmentedControl.withSegments(cellView: self)
        self.setup(segmentedControl: currentSegmentedControl, below: nil)

        var currentSegmentIndex = 0
        let segmentTitles = subkey.rangeListTitles ?? Array(segments.keys)

        for title in segmentTitles {

            currentSegmentedControl.segmentCount += 1
            currentSegmentedControl.setLabel(title, forSegment: currentSegmentIndex)
            if #available(OSX 10.13, *) {
                currentSegmentedControl.setTag(currentSegmentIndex, forSegment: currentSegmentIndex)
            }

            if kEditorTableViewColumnPayloadWidth < currentSegmentedControl.intrinsicContentSize.width {

                currentSegmentedControl.segmentCount -= 1
                self.updateHeight(currentSegmentedControl.intrinsicContentSize.height)
                let nextSegmentedControl = EditorSegmentedControl.withSegments(cellView: self)
                self.setup(segmentedControl: nextSegmentedControl, below: currentSegmentedControl)
                currentSegmentedControl = nextSegmentedControl
                currentSegmentIndex = 0
                currentSegmentedControl.segmentCount += 1
                currentSegmentedControl.setLabel(title, forSegment: currentSegmentIndex)
/*
                let developerMenu = NSMenu(title: NSLocalizedString("Developer", comment: ""))
                let developerMenuItem = NSMenuItem(title: NSLocalizedString("Developer", comment: ""), action: nil, keyEquivalent: "")
                /*
                currentSegmentedControl.submenu = developerMenu
                */
                let developerMenuItemReloadPayloadManifests = NSMenuItem(title: NSLocalizedString("Reload Payload Manifest", comment: ""), action: nil, keyEquivalent: "r")
                developerMenuItemReloadPayloadManifests.keyEquivalentModifierMask = [.option, .command]
                developerMenu.addItem(developerMenuItemReloadPayloadManifests)

                currentSegmentedControl.setMenu(developerMenu, forSegment: currentSegmentIndex)
                if #available(OSX 10.13, *) {
                    currentSegmentedControl.setShowsMenuIndicator(true, forSegment: currentSegmentIndex)
                    // currentSegmentedControl.showsMenuIndicator(forSegment: currentSegmentIndex)
                } else {
                    // currentSegmentedControl.setShowsMenuIndicator(true, forSegment: currentSegmentIndex)
                }
 */

                if #available(OSX 10.13, *) {
                    currentSegmentedControl.setTag(currentSegmentIndex, forSegment: currentSegmentIndex)
                }
            }

            currentSegmentIndex += 1
        }

        if 1 < self.segmentedControls.count {
            let maxSegments = Int((Double(segmentTitles.count) / Double(self.segmentedControls.count)).rounded(.up))
            var remainingSegmentTitles = segmentTitles
            var segmentedControl = self.segmentedControls[0]
            segmentedControl.segmentCount = maxSegments <= remainingSegmentTitles.count ? maxSegments : remainingSegmentTitles.count
            if #available(OSX 10.13, *) {
                segmentedControl.segmentDistribution = .fillEqually
            } else {
                // Fallback on earlier versions
            }
            var segmentIndex = 0
            var counter = 0
            for title in segmentTitles {
                segmentedControl.setLabel(title, forSegment: counter)
                if #available(OSX 10.13, *) {
                    segmentedControl.setTag(counter, forSegment: counter)
                }

                remainingSegmentTitles.removeFirst()

                if counter == (maxSegments - 1) && segmentIndex < self.segmentedControls.count - 1 {
                    counter = 0
                    segmentIndex += 1
                    segmentedControl = self.segmentedControls[segmentIndex]

                    segmentedControl.segmentCount = maxSegments <= remainingSegmentTitles.count ? maxSegments : remainingSegmentTitles.count
                    if #available(OSX 10.13, *) {
                        segmentedControl.segmentDistribution = .fillEqually
                    } else {
                        // Fallback on earlier versions
                    }
                } else {
                    counter += 1
                }

            }

            // Leading
            self.cellViewConstraints.append(NSLayoutConstraint(item: self.segmentedControls.first!,
                                                               attribute: .leading,
                                                               relatedBy: .equal,
                                                               toItem: self,
                                                               attribute: .leading,
                                                               multiplier: 1.0,
                                                               constant: 7.0))

            // Trailing
            self.cellViewConstraints.append(NSLayoutConstraint(item: self,
                                                               attribute: .trailing,
                                                               relatedBy: .equal,
                                                               toItem: self.segmentedControls.first!,
                                                               attribute: .trailing,
                                                               multiplier: 1.0,
                                                               constant: 7.0))
        } else {

            // Center X
            self.cellViewConstraints.append(NSLayoutConstraint(item: self.segmentedControls.first!,
                                                               attribute: .centerX,
                                                               relatedBy: .equal,
                                                               toItem: self,
                                                               attribute: .centerX,
                                                               multiplier: 1.0,
                                                               constant: 0.0))
            /*
            // Leading
            self.cellViewConstraints.append(NSLayoutConstraint(item: self.segmentedControls.first!,
                                                               attribute: .leading,
                                                               relatedBy: .greaterThanOrEqual,
                                                               toItem: self,
                                                               attribute: .leading,
                                                               multiplier: 1.0,
                                                               constant: 7.0))
            
            // Trailing
            self.cellViewConstraints.append(NSLayoutConstraint(item: self.segmentedControls.first!,
                                                               attribute: .trailing,
                                                               relatedBy: .greaterThanOrEqual,
                                                               toItem: segmentedControl,
                                                               attribute: .trailing,
                                                               multiplier: 1.0,
                                                               constant: 7.0))
             */
        }

        self.updateHeight(currentSegmentedControl.intrinsicContentSize.height)

    }

    private func setup(segmentedControl: NSSegmentedControl, below: NSSegmentedControl?) {

        // ---------------------------------------------------------------------
        //  Add SegmentedControl to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(segmentedControl)
        self.segmentedControls.append(segmentedControl)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        if let segmentedControlAbove = below {

            // Top
            self.cellViewConstraints.append(NSLayoutConstraint(item: segmentedControl,
                                                               attribute: .top,
                                                               relatedBy: .equal,
                                                               toItem: segmentedControlAbove,
                                                               attribute: .bottom,
                                                               multiplier: 1.0,
                                                               constant: 1.0))

            // Leading
            self.cellViewConstraints.append(NSLayoutConstraint(item: segmentedControl,
                                                               attribute: .leading,
                                                               relatedBy: .equal,
                                                               toItem: segmentedControlAbove,
                                                               attribute: .leading,
                                                               multiplier: 1.0,
                                                               constant: 0.0))

            // Trailing
            self.cellViewConstraints.append(NSLayoutConstraint(item: segmentedControl,
                                                               attribute: .trailing,
                                                               relatedBy: .equal,
                                                               toItem: segmentedControlAbove,
                                                               attribute: .trailing,
                                                               multiplier: 1.0,
                                                               constant: 0.0))
        } else {

            // Top
            self.cellViewConstraints.append(NSLayoutConstraint(item: segmentedControl,
                                                               attribute: .top,
                                                               relatedBy: .equal,
                                                               toItem: self,
                                                               attribute: .top,
                                                               multiplier: 1.0,
                                                               constant: 8.0))

            self.updateHeight(8.0)
        }
    }
}
