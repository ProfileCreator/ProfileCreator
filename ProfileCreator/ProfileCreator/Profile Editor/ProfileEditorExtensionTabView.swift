//
//  ProfileEditorExtensionTabView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileEditor {

    @objc func buttonClickedAddTab(_ button: NSButton) {
        Log.shared.debug(message: "Button clicked: Add Tab", category: String(describing: self))
        self.addTab(addSettings: true)
    }

    func addTab(addSettings: Bool) {

        Log.shared.debug(message: "Add tab (with settings: \(addSettings))", category: String(describing: self))

        guard let payloadPlaceholder = self.selectedPayloadPlaceholder else { return }

        // Add default settings
        if addSettings {
            if self.profile.settings.settingsEmptyCount(forDomainIdentifier: payloadPlaceholder.domainIdentifier, type: payloadPlaceholder.payloadType) != 0 {
                if let lastTab = self.tabView.views.last, let lastTabIndex = self.tabView.views.firstIndex(of: lastTab) {
                    self.select(tab: lastTabIndex)
                }
                if let window = self.tableView.window {
                    Alert().showAlert(message: NSLocalizedString("You already have an empty payload.", comment: ""),
                                      informativeText: NSLocalizedString("Configure the empty payload to be able to add a new payload.", comment: ""),
                                      window: window,
                                      firstButtonTitle: ButtonTitle.ok,
                                      secondButtonTitle: nil,
                                      thirdButtonTitle: nil,
                                      firstButtonState: true,

                                      sender: self) { _ in }
                }
                return
            }
            self.profile.settings.setSettingsDefault(forPayload: payloadPlaceholder.payload)
            self.profile.settings.setPayloadEnabled(self.profile.settings.isEnabled(payloadPlaceholder.payload), payload: payloadPlaceholder.payload)
        }

        // Add tab
        let newTab = ProfileEditorTab(editor: self)
        self.tabView.addView(newTab, in: .trailing)
        if addSettings, let newTabIndex = self.tabView.views.firstIndex(of: newTab) {
            self.select(tab: newTabIndex)

            // FIXME: This is clunky and resource heavy for what it does, should use a notification maybe, or just upadte the specific cellview not BOTH table views
            if let editorWindowController = self.scrollView.window?.windowController as? ProfileEditorWindowController,
                let libraryTableViews = editorWindowController.splitView.librarySplitView?.tableViews {
                libraryTableViews.reloadTableviews()
            }
        }
        self.showTabView(true)
    }

    func select(tab payloadIndex: Int) {

        Log.shared.debug(message: "Select tab: \(payloadIndex)", category: String(describing: self))

        for (tabIndex, view) in self.tabView.views.enumerated() {
            guard let tabView = view as? ProfileEditorTab else { continue }
            tabView.setValue(tabIndex == payloadIndex, forKeyPath: tabView.isSelectedSelector)
        }

        // Don't do anything if tab is already selected
        if payloadIndex == self.selectedPayloadIndex {
            Log.shared.debug(message: "Selected tab is already selected, will not update contents.", category: String(describing: self))
            return
        } else { self.selectedPayloadIndex = payloadIndex }

        // ---------------------------------------------------------------------
        //  Save currently selected payload index if the payload source can have multiple
        // ---------------------------------------------------------------------
        if let currentPlaceholder = self.selectedPayloadPlaceholder, !currentPlaceholder.payload.unique {
            self.profile.settings.setViewValue(payloadIndex: self.selectedPayloadIndex, forDomainIdentifier: currentPlaceholder.domainIdentifier, payloadType: currentPlaceholder.payloadType)
        }

        switch self.selectedPayloadView {
        case .profileCreator:
            self.reloadTableView(updateCellViews: true)
        case .source:
            if let selectedPlaceholder = self.selectedPayloadPlaceholder {
                self.updateSourceView(payloadPlaceholder: selectedPlaceholder)
            }
        case .outlineView:
            Swift.print("Add code for outlineView")
        }
    }

    func close(tab payloadIndex: Int) {

        Log.shared.debug(message: "Close tab: \(payloadIndex)", category: String(describing: self))

        guard let payloadPlaceholder = self.selectedPayloadPlaceholder else { return }

        if self.tabView.views.count <= payloadIndex {
            Log.shared.error(message: "Cannot remove tab at index: \(payloadIndex). Out of range", category: String(describing: self))
            return
        }

        self.tabView.removeView(self.tabView.views[payloadIndex])

        // Assert not 0 in views
        self.profile.settings.removeSettings(forDomainIdentifier: payloadPlaceholder.domainIdentifier, type: payloadPlaceholder.payloadType, payloadIndex: payloadIndex)

        // ----------------------------------------------------------------------------------------------------------------------
        //  If the currently selected tab sent the close notification, calculate and send what tab to select after it has closed
        // ----------------------------------------------------------------------------------------------------------------------
        if payloadIndex == self.selectedPayloadIndex {
            if self.tabView.views.count <= payloadIndex {
                self.select(tab: self.tabView.views.count - 1)
            } else {
                self.select(tab: payloadIndex)
                self.reloadTableView(updateCellViews: true)
            }
        } else if payloadIndex < self.selectedPayloadIndex, self.selectedPayloadIndex - 1 < self.tabView.views.count {
            self.select(tab: self.selectedPayloadIndex - 1)
        } else {
            Log.shared.error(message: "Unhandled tab index, this has to be fixed", category: String(describing: self))
            Log.shared.error(message: "payloadIndex: \(payloadIndex)", category: String(describing: self))
            Log.shared.error(message: "self.selectedPayloadIndex: \(self.selectedPayloadIndex)", category: String(describing: self))
            Log.shared.error(message: "self.tabView.views.count: \(self.tabView.views.count)", category: String(describing: self))
        }

        // FIXME: This is clunky and resource heavy for what it does, should use a notification maybe, or just upadte the specific cellview not BOTH table views
        if let editorWindowController = self.scrollView.window?.windowController as? ProfileEditorWindowController,
            let libraryTableViews = editorWindowController.splitView.librarySplitView?.tableViews {
            libraryTableViews.reloadTableviews()
        }

        // Hide
        if self.tabView.views.count == 1 {
            self.select(tab: 0)
            self.showTabView(false)
        }
    }

    func updateTabViewCount(payloadPlaceholder: PayloadPlaceholder) {

        Log.shared.debug(message: "Update tab count for payload: \(payloadPlaceholder.domain) type: \(payloadPlaceholder.payloadType)", category: String(describing: self))

        // Update tab count to matching settings
        var payloadPlaceholderSettingsCount = self.profile.settings.settingsCount(forDomainIdentifier: payloadPlaceholder.domainIdentifier, type: payloadPlaceholder.payloadType)

        // If 0 is returned, make it 1 as it can't be 0
        if payloadPlaceholderSettingsCount == 0 { payloadPlaceholderSettingsCount = 1 }
        Log.shared.debug(message: "Settings count: \(payloadPlaceholderSettingsCount)", category: String(describing: self))

        // Get current tabs in tab view
        var tabCount = self.tabView.views.count
        Log.shared.debug(message: "Tab count: \(payloadPlaceholderSettingsCount)", category: String(describing: self))

        if tabCount != payloadPlaceholderSettingsCount {
            if payloadPlaceholderSettingsCount < tabCount {
                while payloadPlaceholderSettingsCount < tabCount {
                    if let lastView = self.tabView.views.last {
                        self.tabView.removeView(lastView)
                    } else {
                        Log.shared.error(message: "Failed to get last view in stackview, should not happen.", category: String(describing: self))
                        tabCount = 99 // Setting 99 to exit the loop
                    }
                    tabCount = self.tabView.views.count
                }
            } else if tabCount < payloadPlaceholderSettingsCount {
                while tabCount < payloadPlaceholderSettingsCount {
                    self.addTab(addSettings: false)
                    tabCount = self.tabView.views.count
                }
            }
        }
    }

    func showTabView(_ show: Bool) {
        if show {
            self.editorView.addSubview(self.scrollViewTabView)
            // self.editorView.addSubview(self.tabView)

            // Reconnect tableview
            NSLayoutConstraint.deactivate([self.constraintScrollViewTopSeparator])
            NSLayoutConstraint.activate([self.constraintScrollViewTopTab])

            // Add TabView
            NSLayoutConstraint.activate(self.constraintsTabView)
        } else {
            self.scrollViewTabView.removeFromSuperview()
            // self.tabView.removeFromSuperview()

            // Reconnect tableview to top
            NSLayoutConstraint.deactivate([self.constraintScrollViewTopTab])
            NSLayoutConstraint.activate([self.constraintScrollViewTopSeparator])
        }
    }

    func showTabView(payloadPlaceholder: PayloadPlaceholder) {

        Log.shared.debug(message: "Show tab view for payload: \(payloadPlaceholder.domain) type: \(payloadPlaceholder.payloadType)", category: String(describing: self))

        if !payloadPlaceholder.payload.unique {
            self.selectedPayloadIndex = profile.settings.viewValuePayloadIndex(forDomainIdentifier: payloadPlaceholder.domainIdentifier, payloadType: payloadPlaceholder.payloadType)

            Log.shared.debug(message: "Saved payload index for payload: \(payloadPlaceholder.domainIdentifier) type: \(payloadPlaceholder.payloadType) is: \(self.selectedPayloadIndex)", category: String(describing: self))

            self.showTabViewButtonAdd(true)
            self.updateTabViewCount(payloadPlaceholder: payloadPlaceholder)
            if self.profile.settings.settingsCount(forDomainIdentifier: payloadPlaceholder.domainIdentifier, type: payloadPlaceholder.payloadType) < 2 {
                self.showTabView(false)
            } else if !self.editorView.subviews.contains(self.tabView) {
                self.showTabView(true)
            }

            self.select(tab: self.selectedPayloadIndex)
        } else {
            self.selectedPayloadIndex = 0
            self.showTabViewButtonAdd(false)
            self.showTabView(false)
        }
    }

    func showTabViewButtonAdd(_ show: Bool) {
        if show {
            if !self.editorView.subviews.contains(self.buttonAddTab) {
                self.editorView.addSubview(self.buttonAddTab)
                NSLayoutConstraint.activate(self.constraintTabViewButtonAdd)
            }
        } else {
            self.buttonAddTab.removeFromSuperview()
        }
    }

}
