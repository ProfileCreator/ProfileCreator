//
//  ProfileEditor.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class ProfileEditor: NSObject {

    // MARK: -
    // MARK: Variables

    let headerView: ProfileEditorHeaderView
    let scrollViewTabView = OverlayScrollView(frame: NSRect.zero)
    let tabView = NSStackView()
    let buttonAddTab = NSButton()
    let tableView = ProfileEditorTableView()
    let textView = ProfileEditorSourceView()
    let scrollView = OverlayScrollView(frame: NSRect.zero)
    let separator = NSBox(frame: NSRect.zero)
    let settings: ProfileEditorSettings
    let outlineView: ProfileEditorOutlineView
    let outlineViewController = ProfileEditorOutlineViewController()

    var testObserver: Any?

    var constraintsTabView = [NSLayoutConstraint]()
    var constraintTabViewButtonAdd = [NSLayoutConstraint]()

    var constraintScrollViewTopSeparator = NSLayoutConstraint()
    var constraintScrollViewTopTab = NSLayoutConstraint()

    private var editKey: ProfileEditorEditKey?

    public let editorView = NSView()

    private let payloadCellViews = PayloadCellViews()

    private var firstCellView: NSView?
    private var selectedCellView: NSView?

    private var cellViews = [NSTableCellView]()

    public unowned var profile: Profile

    // Since PayloadPlaceholder doesn't inherit NSObject, it can't be made @objc compatible
    @objc public var selectedPayloadPlaceholderUpdated: Bool = false
    public let selectedPayloadPlaceholderUpdatedSelector: String

    var selectedPayloadPlaceholder: PayloadPlaceholder?
    var selectedPayloadIndex = 0
    var selectedPayloadView: EditorViewTag = .profileCreator
    var selectedPayloadViewCustom: EditorViewTag = .profileCreator

    // MARK: -
    // MARK: Initialization

    init(profile: Profile) {

        self.profile = profile
        self.settings = ProfileEditorSettings(profile: profile)
        self.headerView = ProfileEditorHeaderView(profile: profile)
        self.outlineView = self.outlineViewController.outlineView

        // ---------------------------------------------------------------------
        //  Initialize Key/Value Observing Selector Strings
        // ---------------------------------------------------------------------
        self.selectedPayloadPlaceholderUpdatedSelector = NSStringFromSelector(#selector(getter: self.selectedPayloadPlaceholderUpdated))

        super.init()

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.headerView.profileEditor = self
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup EditorView
        // ---------------------------------------------------------------------
        self.setupEditorView(constraints: &constraints)
        self.setupHeaderView(constraints: &constraints)
        self.setupButtonAddTab(constraints: &constraints)
        self.setupTabView(constraints: &constraints)
        self.setupSeparator(constraints: &constraints)
        self.setupTableView(profile: profile, constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Setup TextView
        // ---------------------------------------------------------------------
        self.setupTextView(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Setup Notification Observers
        // ---------------------------------------------------------------------
        profile.settings.addObserver(self, forKeyPath: profile.settings.settingsRestoredSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.disableOptionalKeysSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.showCustomizedKeysSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.showDisabledKeysSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.showHiddenKeysSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.showSupervisedKeysSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.showUserApprovedKeysSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.platformsUpdatedSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.scopeUpdatedSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.distributionMethodUpdatedSelector, options: .new, context: nil)

        UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.payloadEditorShowDisabledKeysSeparator, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.payloadEditorShowKeyAsTitle, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.payloadEditorShowSegmentedControls, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.payloadEditorSyntaxHighlightTheme, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.payloadEditorSyntaxHighlightBackgroundColor, options: .new, context: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTableView(_:)), name: .payloadUpdatesAvailable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSaveProfile(_:)), name: .didSaveProfile, object: nil)
        // NotificationCenter.default.addObserver(self, selector: #selector(self.reloadCellViews(_:)), name: .payloadUpdatesDownloaded, object: nil)

        DistributedNotificationCenter.default().addObserver(self.textView, selector: #selector(self.textView.appearanceChanged(_:)), name: NSNotification.Name("AppleInterfaceThemeChangedNotification"), object: nil)

        // ---------------------------------------------------------------------
        //  Activate layout constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)

        // ---------------------------------------------------------------------
        //  Reload the TableView
        // ---------------------------------------------------------------------
        // self.reloadTableView(updateCellViews: true)
    }

    @objc func didSaveProfile(_ notification: Notification) {
        if self.selectedPayloadPlaceholder?.domain == kManifestDomainConfiguration {
            self.reloadTableView(updateCellViews: true)
        }
    }

    @objc func reloadTableView(_ notification: Notification) {
        self.reloadTableView(updateCellViews: false)
    }

    deinit {
        self.tableView.dataSource = nil
        self.tableView.delegate = nil

        self.profile.settings.removeObserver(self, forKeyPath: profile.settings.settingsRestoredSelector, context: nil)
        self.profile.settings.removeObserver(self, forKeyPath: profile.settings.disableOptionalKeysSelector, context: nil)
        self.profile.settings.removeObserver(self, forKeyPath: profile.settings.showCustomizedKeysSelector, context: nil)
        self.profile.settings.removeObserver(self, forKeyPath: profile.settings.showDisabledKeysSelector, context: nil)
        self.profile.settings.removeObserver(self, forKeyPath: profile.settings.showHiddenKeysSelector, context: nil)
        self.profile.settings.removeObserver(self, forKeyPath: profile.settings.showSupervisedKeysSelector, context: nil)
        self.profile.settings.removeObserver(self, forKeyPath: profile.settings.showUserApprovedKeysSelector, context: nil)
        self.profile.settings.removeObserver(self, forKeyPath: profile.settings.platformsUpdatedSelector, context: nil)
        self.profile.settings.removeObserver(self, forKeyPath: profile.settings.scopeUpdatedSelector, context: nil)
        self.profile.settings.removeObserver(self, forKeyPath: profile.settings.distributionMethodUpdatedSelector, context: nil)

        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.payloadEditorShowDisabledKeysSeparator, context: nil)
        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.payloadEditorShowKeyAsTitle, context: nil)
        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.payloadEditorShowSegmentedControls, context: nil)
        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.payloadEditorSyntaxHighlightTheme, context: nil)
        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.payloadEditorSyntaxHighlightBackgroundColor, context: nil)

        NotificationCenter.default.removeObserver(self, name: .payloadUpdatesAvailable, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didSaveProfile, object: nil)

        DistributedNotificationCenter.default().removeObserver(self.textView, name: NSNotification.Name("AppleInterfaceThemeChangedNotification"), object: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath ?? "" {
        case self.profile.settings.settingsRestoredSelector:
            if let window = self.tableView.window {
                for cellView in self.cellViews {
                    if cellView.allSubviews().contains(where: { $0 == window.firstResponder }), let payloadCellView = cellView as? PayloadCellView {
                        payloadCellView.isEditing = false
                        break
                    }
                }
            }

            self.reloadTableView(updateCellViews: true)
        case self.profile.settings.showDisabledKeysSelector,
             self.profile.settings.showCustomizedKeysSelector,
             self.profile.settings.showHiddenKeysSelector,
             self.profile.settings.showSupervisedKeysSelector,
             self.profile.settings.showUserApprovedKeysSelector,
             self.profile.settings.disableOptionalKeysSelector,
             self.profile.settings.platformsUpdatedSelector,
             self.profile.settings.scopeUpdatedSelector,
             self.profile.settings.distributionMethodUpdatedSelector,
             PreferenceKey.payloadEditorShowDisabledKeysSeparator,
             PreferenceKey.payloadEditorShowKeyAsTitle,
             PreferenceKey.payloadEditorShowSegmentedControls:

            self.reloadTableView(updateCellViews: true)

        case PreferenceKey.payloadEditorSyntaxHighlightTheme,
             PreferenceKey.payloadEditorSyntaxHighlightBackgroundColor:

            if self.selectedPayloadView == .source, let selectedPlaceholder = self.selectedPayloadPlaceholder {
                self.updateSourceView(payloadPlaceholder: selectedPlaceholder)
            }
        default:
            Log.shared.error(message: "Unknown keyPath: \(keyPath ?? "")", category: String(describing: self))
        }
    }

    func reloadTableView(updateCellViews: Bool = false) {
        if updateCellViews, let selectedPayloadPlaceholder = self.selectedPayloadPlaceholder {
            self.cellViews = self.payloadCellViews.cellViews(payloadPlaceholder: selectedPayloadPlaceholder, payloadIndex: self.selectedPayloadIndex, profileEditor: self)
        }
        self.tableView.beginUpdates()
        self.tableView.reloadData()
        self.tableView.endUpdates()
    }

    func updatePayloadSelection(selected: Bool, payload: Payload) {
        self.profile.settings.updatePayloadSelection(selected: selected, payload: payload)
        if let payloadPlaceholder = self.selectedPayloadPlaceholder {
            self.updateSourceView(payloadPlaceholder: payloadPlaceholder)
        }
    }

    func select(view: Int) {
        switch view {
        case EditorViewTag.profileCreator.rawValue:
            self.selectedPayloadView = .profileCreator

            guard self.scrollView.documentView != self.tableView else { return }

            if let selectedPayloadPlaceholder = self.selectedPayloadPlaceholder {
                self.showTabView(payloadPlaceholder: selectedPayloadPlaceholder)
            }

            // self.select(tab: self.selectedPayloadIndex)
            self.reloadTableView(updateCellViews: true)
            self.scrollView.documentView = self.tableView
        case EditorViewTag.source.rawValue:
            self.selectedPayloadView = .source

            guard self.scrollView.documentView != self.textView else { return }

            if let selectedPayloadPlaceholder = self.selectedPayloadPlaceholder {
                self.showTabView(payloadPlaceholder: selectedPayloadPlaceholder)
                self.updateSourceView(payloadPlaceholder: selectedPayloadPlaceholder)
            }

            // self.select(tab: self.selectedPayloadIndex)
            self.scrollView.documentView = self.textView
        case EditorViewTag.outlineView.rawValue:
            self.selectedPayloadView = .outlineView

            guard self.scrollView.documentView != self.outlineView else { return }

            if let selectedPayloadPlaceholder = self.selectedPayloadPlaceholder {
                self.showTabView(payloadPlaceholder: selectedPayloadPlaceholder)
                self.updateOutlineView(payloadPlaceholder: selectedPayloadPlaceholder)
            }

            self.scrollView.documentView = self.outlineView
        default:
            Log.shared.error(message: "Unknown view tag: \(view)", category: String(describing: self))
        }
    }

    func select(payloadPlaceholder: PayloadPlaceholder, ignoreCurrentSelection: Bool) {

        // ---------------------------------------------------------------------
        //  Only update selection if it's not currently selected
        // ---------------------------------------------------------------------
        if ignoreCurrentSelection || self.selectedPayloadPlaceholder != payloadPlaceholder {

            // ---------------------------------------------------------------------
            //  If current placeholder is unknown, and selected placehoder is not
            //  then restore the view that was selected before selecting the unknown.
            // ---------------------------------------------------------------------
            if self.selectedPayloadPlaceholder?.payloadType == .custom {
                if
                    payloadPlaceholder.payloadType != .custom,
                    let editorWindowController = self.scrollView.window?.windowController as? ProfileEditorWindowController {

                    if self.selectedPayloadViewCustom != .source {
                        self.select(view: self.selectedPayloadViewCustom.rawValue)

                        guard let toolbarItem = editorWindowController.toolbarItemView?.toolbarItem as? NSToolbarItemGroup else { return }

                        toolbarItem.setSelected(true, at: self.selectedPayloadView.rawValue)
                    }

                    editorWindowController.toolbarItemView?.toolbarItem?.isEnabled = true
                }
            } else {
                self.selectedPayloadViewCustom = self.selectedPayloadView
            }

            // ---------------------------------------------------------------------
            //  Update the selected placeholder
            // ---------------------------------------------------------------------
            self.selectedPayloadPlaceholder = payloadPlaceholder
            self.setValue(!self.selectedPayloadPlaceholderUpdated, forKeyPath: self.selectedPayloadPlaceholderUpdatedSelector)

            // ---------------------------------------------------------------------
            //  Update the selected payload index
            // ---------------------------------------------------------------------
            self.selectedPayloadIndex = self.profile.settings.viewValuePayloadIndex(forDomainIdentifier: payloadPlaceholder.domainIdentifier, payloadType: payloadPlaceholder.payloadType)

            // ---------------------------------------------------------------------
            //  Update header view
            // ---------------------------------------------------------------------
            self.headerView.select(payloadPlaceholder: payloadPlaceholder)

            // ---------------------------------------------------------------------
            //  If selected placeholder is unknown
            // ---------------------------------------------------------------------
            if payloadPlaceholder.payloadType == .custom {
                if let editorWindowController = self.scrollView.window?.windowController as? ProfileEditorWindowController {

                    if self.selectedPayloadView != .source {
                        self.select(view: EditorViewTag.source.rawValue)

                        guard let toolbarItem = editorWindowController.toolbarItemView?.toolbarItem as? NSToolbarItemGroup else { return }

                        toolbarItem.setSelected(true, at: EditorViewTag.source.rawValue)
                    }

                    editorWindowController.toolbarItemView?.toolbarItem?.isEnabled = false
                }
            }

            if self.selectedPayloadView == .source || payloadPlaceholder.payloadType == .custom {

                // ---------------------------------------------------------------------
                //  Update source view with a xml representation of the payload(s)
                // ---------------------------------------------------------------------
                self.updateSourceView(payloadPlaceholder: payloadPlaceholder)
            } else {

                // ---------------------------------------------------------------------
                //  Reload all payload keys with updateCellVies so the current selection keys are shown
                // ---------------------------------------------------------------------
                self.reloadTableView(updateCellViews: true)
            }

            // ---------------------------------------------------------------------
            //  Show/Hide tab bar if more than one payload is selected
            // ---------------------------------------------------------------------
            self.showTabView(payloadPlaceholder: payloadPlaceholder)
        }
    }

    // MARK: -
    // MARK: KeyView

    func updateKeyViewLoop(window: NSWindow) {
        var previousCellView: PayloadCellView?
        var firstCellView: PayloadCellView?

        for (index, cellView) in self.cellViews.enumerated() {
            guard let payloadCellView = cellView as? PayloadCellView else { continue }

            if payloadCellView.leadingKeyView != nil {
                if let previous = previousCellView {
                    previous.trailingKeyView!.nextKeyView = payloadCellView.leadingKeyView
                } else {
                    firstCellView = payloadCellView
                }
                previousCellView = payloadCellView

                if self.cellViews.count == index + 1 {
                    tableView.nextKeyView = firstCellView?.leadingKeyView
                    payloadCellView.trailingKeyView!.nextKeyView = tableView
                }
            }
        }

        // NOTE: This sometimes crashes, should investigate and check if object exists in the correct window, and why it doesnt sometimes.
        if firstCellView != nil {
            window.initialFirstResponder = firstCellView
            self.firstCellView = firstCellView
        }
    }

    func addKey(forPayloadPlaceholder payloadPlaceholder: PayloadPlaceholder) {
        if self.editKey == nil {
            self.editKey = ProfileEditorEditKey(editor: self)
        }
        self.editKey?.addKey(forPlaceholder: payloadPlaceholder)
    }

    func editKey(_ payloadSubkey: PayloadSubkey, forPayloadPlaceholder payloadPlaceholder: PayloadPlaceholder) {
        if self.editKey == nil {
            self.editKey = ProfileEditorEditKey(editor: self)
        }
        self.editKey?.editKey(payloadSubkey, forPlaceholder: payloadPlaceholder)
    }
}

// MARK: -
// MARK: NSTableViewDataSource

extension ProfileEditor: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        self.cellViews.count
    }
}

// MARK: -
// MARK: NSTableViewDelegate

extension ProfileEditor: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if let cellView = self.cellViews[row] as? ProfileCreatorCellView {
            return cellView.height
        }
        return 1
    }

    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {

        // If the row is the first or last, use the view settings for the row below and above respectively
        var rowNumber: Int
        if row == 0 {
            rowNumber = row + 1
        } else if row == (self.cellViews.count - 1) {
            rowNumber = row - 1
        } else {
            rowNumber = row
        }

        // Get the CellView for the row
        guard let cellView = self.cellViews[rowNumber] as? PayloadCellView else { return }

        // If the CellView is a segmented control, use the the view settings for the row below or above
        if cellView is PayloadCellViewSegmentedControl {

            var segmentRowNumber: Int

            // If this is the last view, use the view above
            if row == 1 {
                segmentRowNumber = row - 1
            } else if row == (self.cellViews.count - 2) {
                segmentRowNumber = (0 <= (row - 3)) ? row - 3 : 0
            } else {
                segmentRowNumber = row + 1
            }

            guard segmentRowNumber < self.cellViews.count, let previousCellView = self.cellViews[segmentRowNumber] as? PayloadCellView else { return }
            if !previousCellView.isEnabled {
                rowView.backgroundColor = .quaternaryLabelColor
            }

            cellView.enable(cellView.isEnabled)
        }

        if !cellView.isEnabled {
            rowView.backgroundColor = .quaternaryLabelColor
        }

        cellView.enable(cellView.isEnabled)
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier == .tableColumnPayload {
            // FIXME: Should maybe not be done here?
            if
                self.cellViews.count == row + 1,
                let window = tableView.window {
                self.updateKeyViewLoop(window: window)
            }
            return self.cellViews[row]
        } else if tableColumn?.identifier == .tableColumnPayloadEnableLeading {
            if let cellView = self.cellViews[row] as? PayloadCellView {
                return PayloadCellViewEnable(cellView: cellView, payloadIndex: self.selectedPayloadIndex, editor: self)
            }
        }
        return nil
    }
}

// MARK: -
// MARK: Subclasses to enable FirstResponder and KeyView

class PayloadButton: NSButton {
    override var acceptsFirstResponder: Bool { self.isEnabled }
    override var canBecomeKeyView: Bool { self.isEnabled }

    // Provide some margin on the button so it's not right up against the border of the cell
    override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize

        size.height += 10

        return size
    }
}

class PayloadPopUpButton: NSPopUpButton {
    override var acceptsFirstResponder: Bool { self.isEnabled }
    override var canBecomeKeyView: Bool { self.isEnabled }
}

class PayloadSegmentedControl: NSSegmentedControl {
    override var acceptsFirstResponder: Bool { self.isEnabled }
    override var canBecomeKeyView: Bool { self.isEnabled }
}

class PayloadTextField: NSTextField {
    override var acceptsFirstResponder: Bool { self.isEditable }
    override var canBecomeKeyView: Bool { self.isEditable }

    let trackingOptions = NSTrackingArea.Options(rawValue: (NSTrackingArea.Options.mouseEnteredAndExited.rawValue | NSTrackingArea.Options.activeAlways.rawValue))

    var substitutionVariables = [NSRange: [String: [String: String]]]()

    // MARK: -
    // MARK: NSControl/NSResponder Methods

    override func mouseEntered(with event: NSEvent) {
        guard let trackingArea = event.trackingArea, let userData = trackingArea.userInfo as? [String: Any] else {
            return
        }
        if let popOver = userData["popOver"] as? PayloadCellViewPopOver {
            popOver.showSubstitutionVariable(inView: self)
        }
    }

    override func mouseExited(with event: NSEvent) {
        guard let trackingArea = event.trackingArea, let userData = trackingArea.userInfo as? [String: Any] else {
            return
        }
        if let popOver = userData["popOver"] as? PayloadCellViewPopOver {
            popOver.popOver.close()
        }
    }

    func boundingRectForCharacterRange(range: NSRange) -> CGRect? {
        let textStorage = NSTextStorage(attributedString: self.attributedStringValue)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: intrinsicContentSize)
        textContainer.lineFragmentPadding = 0.0
        layoutManager.addTextContainer(textContainer)

        var glyphRange = NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        let glyphRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        return self.increaseRect(rect: glyphRect, byPercentage: 0.2)
    }

    func increaseRect(rect: CGRect, byPercentage percentage: CGFloat) -> CGRect {
        // let adjustmentWidth = (rect.width * percentage) / 2.0
        let adjustmentHeight = (rect.height * percentage) / 2.0
        return rect.insetBy(dx: 0.0, dy: -adjustmentHeight)
    }

    override func updateTrackingAreas() {
        // ---------------------------------------------------------------------
        //  Remove previous tracking areas if it was set
        // ---------------------------------------------------------------------
        self.trackingAreas.forEach { self.removeTrackingArea($0) }

        // ---------------------------------------------------------------------
        //  Update all tracking areas
        // ---------------------------------------------------------------------
        for (range, subVars) in self.substitutionVariables {
            guard let rect = self.boundingRectForCharacterRange(range: range) else {
                continue
            }
            if let key = subVars.keys.first, let info = subVars[key] {
                let popOver = PayloadCellViewPopOver(frame: rect, animates: false)
                popOver.popOver.contentViewController = PayloadCellViewPopOverViewController(variable: key, info: info)
                self.addTrackingArea(NSTrackingArea(rect: rect, options: trackingOptions, owner: self, userInfo: ["popOver": popOver]))
            }
        }
    }
}

class PayloadTextView: NSTextView {
    override var acceptsFirstResponder: Bool { self.isEditable }
    override var canBecomeKeyView: Bool { self.isEditable }

    // swiftlint:disable:next prohibited_super_call
    override func doCommand(by selector: Selector) {
        if selector == #selector(insertTab(_:)) {
            self.window?.selectNextKeyView(nil)
        } else if selector == #selector(insertBacktab(_:)) {
            self.window?.selectPreviousKeyView(nil)
        } else {
            super.doCommand(by: selector)
        }
    }
}

class ProfileEditorTableView: NSTableView {
    override var acceptsFirstResponder: Bool { false }
    override var canBecomeKeyView: Bool { false }
}
