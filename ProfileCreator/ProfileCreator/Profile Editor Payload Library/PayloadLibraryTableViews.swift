//
//  PayloadLibraryTableViews.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

// MARK: -
// MARK: Protocols
// MAKR: -

protocol PayloadLibraryTableViewDelegate: AnyObject {
    func payloadPlaceholder(atRow: Int, in: PayloadLibraryTableView) -> PayloadPlaceholder?
}

// MARK: -
// MARK: Classes
// MAKR: -

class PayloadLibraryTableViews: NSObject, PayloadLibrarySelectionDelegate {

    // MARK: -
    // MARK: Variables

    let profilePayloadsTableView = PayloadLibraryTableView()
    let profilePayloadsScrollView = OverlayScrollView(frame: NSRect.zero)
    var profilePayloads = [PayloadPlaceholder]()
    var profilePayloadsFiltered = [PayloadPlaceholder]()

    let libraryPayloadsTableView = PayloadLibraryTableView()
    let libraryPayloadsScrollView = OverlayScrollView(frame: NSRect.zero)
    var libraryPayloads = [PayloadPlaceholder]()
    var libraryPayloadsFiltered = [PayloadPlaceholder]()
    var libraryPayloadsCellViews = [PayloadLibraryCellView]()

    var librarySearch = [String: String]()

    private let sortDescriptorTitle = NSSortDescriptor(key: "title", ascending: true)

    private var selectedLibraryTag: PayloadType?
    private var selectedPayloadPlaceholder: PayloadPlaceholder?
    private var generalPayloadPlaceholder: PayloadPlaceholder?

    private weak var profile: Profile?
    private weak var editor: ProfileEditor?
    private weak var librarySplitView: PayloadLibrarySplitView?
    weak var libraryFilter: PayloadLibraryFilter?

    func updateGeneralPlaceholder() {
        if
            let payloadManifestGeneral = ProfilePayloads.shared.appleManifest(forDomainIdentifier: kManifestDomainConfiguration, ofType: .manifestsApple),
            let payloadPlaceholderGeneral = payloadManifestGeneral.placeholder {
            self.generalPayloadPlaceholder = payloadPlaceholderGeneral
        } else {
            Log.shared.error(message: "Failed to get placeholder for the General payload", category: String(describing: self))
        }
    }

    init(profile: Profile, editor: ProfileEditor, splitView: PayloadLibrarySplitView) {
        super.init()

        self.profile = profile
        self.editor = editor
        self.librarySplitView = splitView

        // ---------------------------------------------------------------------
        //  Add and enable the general settings
        // ---------------------------------------------------------------------
        self.updateGeneralPlaceholder()

        self.setupProfilePayloads()
        self.setupLibraryPayloads()

        // ---------------------------------------------------------------------
        //  Setup Notification Observers
        // ---------------------------------------------------------------------
        NotificationCenter.default.addObserver(self, selector: #selector(changePayloadSelected(_:)), name: .changePayloadSelected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadPayloads(_:)), name: .payloadUpdatesAvailable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadPayloads(_:)), name: .payloadUpdatesDownloaded, object: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowDomainAsTitle, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowApplicationsFolderOnly, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.settingsRestoredSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.distributionMethodUpdatedSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.platformsUpdatedSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.scopeUpdatedSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.showSupervisedKeysSelector, options: .new, context: nil)
        profile.settings.addObserver(self, forKeyPath: profile.settings.showUserApprovedKeysSelector, options: .new, context: nil)

        self.reloadTableviews()

        // ---------------------------------------------------------------------
        //  Select the general settings in the editor
        // ---------------------------------------------------------------------
        if let payloadPlaceholderGeneral = self.generalPayloadPlaceholder {
            self.select(payloadPlaceholder: payloadPlaceholderGeneral, in: self.profilePayloadsTableView)
        }
    }

    deinit {
        // ---------------------------------------------------------------------
        //  Remove self as DataSource and Delegate
        // ---------------------------------------------------------------------
        self.libraryPayloadsTableView.dataSource = nil
        self.profilePayloadsTableView.dataSource = nil
        self.libraryPayloadsTableView.delegate = nil
        self.profilePayloadsTableView.delegate = nil

        NotificationCenter.default.removeObserver(self, name: .changePayloadSelected, object: nil)
        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowDomainAsTitle, context: nil)
        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowApplicationsFolderOnly, context: nil)

        if let profile = self.profile {
            profile.settings.removeObserver(self, forKeyPath: profile.settings.settingsRestoredSelector, context: nil)
            profile.settings.removeObserver(self, forKeyPath: profile.settings.distributionMethodUpdatedSelector, context: nil)
            profile.settings.removeObserver(self, forKeyPath: profile.settings.platformsUpdatedSelector, context: nil)
            profile.settings.removeObserver(self, forKeyPath: profile.settings.scopeUpdatedSelector, context: nil)
            profile.settings.removeObserver(self, forKeyPath: profile.settings.showSupervisedKeysSelector, context: nil)
            profile.settings.removeObserver(self, forKeyPath: profile.settings.showUserApprovedKeysSelector, context: nil)
        }
    }

    @objc func reloadPayloads(_ notification: Notification) {
        self.updateGeneralPlaceholder()
        self.addProfilePayloads()
        self.updatePayloads()
    }

    func updatePayloads() {
        guard let selectedLibrary = self.selectedLibraryTag else { return }
        self.updateLibraryPayloads(type: selectedLibrary)
        self.restoreFilter(forLibrary: selectedLibrary)
        guard let selectedPlaceholder = self.selectedPayloadPlaceholder else { return }
        self.editor?.select(payloadPlaceholder: selectedPlaceholder, ignoreCurrentSelection: true)
        self.editor?.reloadTableView(updateCellViews: true)
    }

    func updateLibraryPayloads(type: PayloadType) {
        self.libraryPayloads = self.placeholders(type: type) ?? [PayloadPlaceholder]()
        if let librarySplitView = self.librarySplitView {
            librarySplitView.noPayloads(show: self.libraryPayloads.isEmpty, message: StringConstant.noPayloads)
            librarySplitView.noProfilePayloads(show: self.profilePayloads.count == 1)
        }
        self.reloadTableviews()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let profile = self.profile else { return }
        switch keyPath ?? "" {
        case profile.settings.settingsRestoredSelector:
            self.addProfilePayloads()
            if let selectedLibraryTag = self.selectedLibraryTag {
                self.updateLibraryPayloads(type: selectedLibraryTag)
            }
        case PreferenceKey.payloadLibraryShowDomainAsTitle,
             PreferenceKey.payloadLibraryShowApplicationsFolderOnly,
             profile.settings.distributionMethodUpdatedSelector,
             profile.settings.platformsUpdatedSelector,
             profile.settings.scopeUpdatedSelector,
             profile.settings.showSupervisedKeysSelector,
             profile.settings.showUserApprovedKeysSelector:
            if let selectedLibraryTag = self.selectedLibraryTag {
                self.updateLibraryPayloads(type: selectedLibraryTag)
            }
        default:
            Log.shared.error(message: "Unknown KVO keyPath: \(String(describing: keyPath))", category: String(describing: self))
        }
    }

    @objc func search(_ sender: NSSearchField?) {
        if let searchString = sender?.stringValue, let selectedLibraryTag = self.selectedLibraryTag {
            self.set(searchString: searchString, forLibrary: selectedLibraryTag)
            self.reloadTableviews()
        }
    }

    func set(searchString string: String, forLibrary library: PayloadType) {
        self.librarySearch[library.rawValue] = string
    }

    func searchString(forLibrary library: PayloadType) -> String {
        self.librarySearch[library.rawValue] ?? ""
    }

    func filterLibraryPayloads() {
        if
            let selectedLibraryTag = self.selectedLibraryTag,
            let librarySearchString = self.librarySearch[selectedLibraryTag.rawValue]?.lowercased(),
            !librarySearchString.isEmpty {
            self.libraryPayloadsFiltered = self.libraryPayloads.filter {
                $0.title.lowercased().contains(librarySearchString) || $0.domain.lowercased().contains(librarySearchString)
            }
        } else {
            self.libraryPayloadsFiltered = self.libraryPayloads
        }
    }

    func restoreFilter(forLibrary library: PayloadType) {
        if let libraryFilter = self.libraryFilter {
            libraryFilter.searchField.stringValue = self.searchString(forLibrary: library)
        }
    }

    @objc func changePayloadSelected(_ notification: NSNotification?) {
        guard
            let userInfo = notification?.userInfo,
            let payloadPlaceholder = userInfo[NotificationKey.payloadPlaceholder] as? PayloadPlaceholder else { return }

        if self.profilePayloads.contains(payloadPlaceholder) {
            _ = self.move(payloadPlaceholders: [payloadPlaceholder], from: .profilePayloads, to: .libraryPayloads)
        } else {
            _ = self.move(payloadPlaceholders: [payloadPlaceholder], from: .libraryPayloads, to: .profilePayloads)
        }
    }

    private func addLibraryCellViews() {

        self.libraryPayloadsFiltered.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == ComparisonResult.orderedAscending }
        var libraryCellViews = [PayloadLibraryCellView]()

        if self.selectedLibraryTag == .manifestsApple, let selectedPlatforms = self.profile?.settings.platforms {

            // FIXME: I don't like this solution, both filter and forEach will loop and this results in lots of loops.
            //        In the best world only one loop i assume, but need to fix this later.

            // FIXME: This doesn't work correctly when deselecting one

            if selectedPlatforms == Platforms.all {
                let placeholdersAll = self.libraryPayloadsFiltered.filter { $0.payload.platforms == Platforms.all }
                if !placeholdersAll.isEmpty {
                    libraryCellViews.append(PayloadLibraryCellViewGroup(title: "macOS, iOS and tvOS"))
                    placeholdersAll.forEach { libraryCellViews.append(PayloadLibraryCellViewLibrary(payloadPlaceholder: $0)) }
                }
            }

            if selectedPlatforms.contains([.macOS, .iOS]) {
                let placeholdersmacOSiOS = self.libraryPayloadsFiltered.filter { $0.payload.platforms.contains([.macOS, .iOS]) && !libraryCellViews.map { $0.placeholder?.domainIdentifier }.contains($0.payload.domainIdentifier) }
                if !placeholdersmacOSiOS.isEmpty {
                    libraryCellViews.append(PayloadLibraryCellViewGroup(title: "macOS and iOS"))
                    placeholdersmacOSiOS.forEach { libraryCellViews.append(PayloadLibraryCellViewLibrary(payloadPlaceholder: $0)) }
                }
            }

            if selectedPlatforms.contains([.iOS, .tvOS]) {
                let placeholdersIOSTvOS = self.libraryPayloadsFiltered.filter { $0.payload.platforms.contains([.iOS, .tvOS]) && !libraryCellViews.map { $0.placeholder?.domainIdentifier }.contains($0.payload.domainIdentifier) }
                if !placeholdersIOSTvOS.isEmpty {
                    libraryCellViews.append(PayloadLibraryCellViewGroup(title: "iOS and tvOS"))
                    placeholdersIOSTvOS.forEach { libraryCellViews.append(PayloadLibraryCellViewLibrary(payloadPlaceholder: $0)) }
                }
            }

            if !selectedPlatforms.isDisjoint(with: .iOS) {
                let placeholdersiOS = self.libraryPayloadsFiltered.filter { $0.payload.platforms.contains(.iOS) && !libraryCellViews.map { $0.placeholder?.domainIdentifier }.contains($0.payload.domainIdentifier) }
                if !placeholdersiOS.isEmpty {
                    libraryCellViews.append(PayloadLibraryCellViewGroup(title: "iOS"))
                    placeholdersiOS.forEach { libraryCellViews.append(PayloadLibraryCellViewLibrary(payloadPlaceholder: $0)) }
                }
            }

            if !selectedPlatforms.isDisjoint(with: .macOS) {
                let placeholdersmacOS = self.libraryPayloadsFiltered.filter { $0.payload.platforms.contains(.macOS) && !libraryCellViews.map { $0.placeholder?.domainIdentifier }.contains($0.payload.domainIdentifier) }
                if !placeholdersmacOS.isEmpty {
                    libraryCellViews.append(PayloadLibraryCellViewGroup(title: "macOS"))
                    placeholdersmacOS.forEach { libraryCellViews.append(PayloadLibraryCellViewLibrary(payloadPlaceholder: $0)) }
                }
            }

            if !selectedPlatforms.isDisjoint(with: .tvOS) {
                let placeholderstvOS = self.libraryPayloadsFiltered.filter { $0.payload.platforms.contains(.tvOS) && !libraryCellViews.map { $0.placeholder?.domainIdentifier }.contains($0.payload.domainIdentifier) }
                if !placeholderstvOS.isEmpty {
                    libraryCellViews.append(PayloadLibraryCellViewGroup(title: "tvOS"))
                    placeholderstvOS.forEach { libraryCellViews.append(PayloadLibraryCellViewLibrary(payloadPlaceholder: $0)) }
                }
            }
        } else {
            self.libraryPayloadsFiltered.forEach { libraryCellViews.append(PayloadLibraryCellViewLibrary(payloadPlaceholder: $0)) }
        }

        self.libraryPayloadsCellViews = libraryCellViews
    }

    func reloadTableviews() {

        // ---------------------------------------------------------------------
        //  Apply the current search filter
        // ---------------------------------------------------------------------
        self.filterLibraryPayloads()

        // ---------------------------------------------------------------------
        //  Sort both library and profile arrays alphabetically
        // ---------------------------------------------------------------------
        self.addLibraryCellViews()
        self.profilePayloads.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == ComparisonResult.orderedAscending }

        // ---------------------------------------------------------------------
        //  Verify that the "General" payload always is at the top of the profile payloads list
        // ---------------------------------------------------------------------
        if let generalPayloadPlaceholder = self.generalPayloadPlaceholder {
            if let generalIndex = self.profilePayloads.firstIndex(of: generalPayloadPlaceholder) {
                self.profilePayloads.remove(at: generalIndex)
            }
            self.profilePayloads.insert(generalPayloadPlaceholder, at: 0)
        }

        // ---------------------------------------------------------------------
        //  Reload both table views
        // ---------------------------------------------------------------------
        self.profilePayloadsTableView.reloadData()
        self.libraryPayloadsTableView.reloadData()

        // ---------------------------------------------------------------------
        //  Check which table view holds the current selection, and mark it selected
        //  This is different from - (void)selectPlaceholder which also updates editor etc.
        // ---------------------------------------------------------------------
        if let selectedPayloadPlaceholder = self.selectedPayloadPlaceholder {
            if let index = self.profilePayloads.firstIndex(of: selectedPayloadPlaceholder) {
                self.profilePayloadsTableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            } else if let index = self.libraryPayloadsCellViews.firstIndex(where: { $0.placeholder == selectedPayloadPlaceholder }) {
                self.libraryPayloadsTableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            }
        }

        // ---------------------------------------------------------------------
        //  If a filter is active, and no payload is visible show no search matches
        // ---------------------------------------------------------------------
        // ---------------------------------------------------------------------
        //  Check if library payloads is empty, then show "No Payloads" view
        // ---------------------------------------------------------------------
        if let librarySplitView = self.librarySplitView {
            if self.libraryPayloads.isEmpty {
                librarySplitView.noPayloads(show: true, message: StringConstant.noPayloads)
            } else {
                librarySplitView.noPayloads(show: self.libraryPayloadsCellViews.isEmpty, message: StringConstant.noMatch)
            }
            librarySplitView.noProfilePayloads(show: self.profilePayloads.count == 1)
        }
    }

    @objc func addClickedPayload(_ sender: NSMenuItem?) {
        guard let row = sender?.tag else { return }
        if row < self.libraryPayloadsCellViews.count {
            if let cellView = self.libraryPayloadsCellViews[row] as? PayloadLibraryCellViewLibrary, let placeholder = cellView.placeholder {
                _ = self.move(payloadPlaceholders: [placeholder], from: .libraryPayloads, to: .profilePayloads)
            }
        }
    }

    @objc func removeClickedPayload(_ sender: NSMenuItem?) {
        guard let row = sender?.tag else { return }
        if 0 < row, row < self.profilePayloads.count {
            let payloadPlaceholder = self.profilePayloads[row]
            _ = self.move(payloadPlaceholders: [payloadPlaceholder], from: .profilePayloads, to: .libraryPayloads)
        }
    }

    func selectLibrary(type: PayloadType, sender: Any?) {
        if self.selectedLibraryTag != type {
            self.selectedLibraryTag = type
            self.updateLibraryPayloads(type: type)
            self.restoreFilter(forLibrary: type)
        }
    }

    // swiftlint:disable cyclomatic_complexity
    private func placeholders(type: PayloadType) -> [PayloadPlaceholder]? {
        switch type {
        case .custom:
            guard let typeSettings = self.profile?.settings.settings(forType: .custom) else { return nil }
            if let customPlaceholders = ProfilePayloads.shared.customManifestPlaceholders(forType: type, typeSettings: typeSettings) {
                return customPlaceholders.filter { !self.profilePayloads.contains($0) }
            }

        case .managedPreferencesApple:
            if let appleManagedPreferencePlaceholders = ProfilePayloads.shared.managedPreferencePlaceholders(forType: type) {
                return appleManagedPreferencePlaceholders.filter { !self.profilePayloads.contains($0) }
            }

        case .manifestsApple:
            guard let profile = self.profile else { return nil }
            if var manifestPlaceholders = ProfilePayloads.shared.appleManifestPlaceholders(forType: .manifestsApple) {
                manifestPlaceholders = manifestPlaceholders.filter {
                    !$0.payload.distribution.isDisjoint(with: profile.settings.distributionMethod) &&
                    !$0.payload.platforms.isDisjoint(with: profile.settings.platforms) &&
                    !$0.payload.targets.isDisjoint(with: profile.settings.scope)
                }

                if !profile.settings.showSupervisedKeys {
                    manifestPlaceholders = manifestPlaceholders.filter { !$0.payload.supervised }
                }

                if !profile.settings.showUserApprovedKeys {
                    manifestPlaceholders = manifestPlaceholders.filter { !$0.payload.userApproved }
                }

                return manifestPlaceholders.filter { !self.profilePayloads.contains($0) }
            }

        case .managedPreferencesApplications:
            if let applicationManagedPreferencePlaceholders = ProfilePayloads.shared.managedPreferencePlaceholders(forType: type) {
                return applicationManagedPreferencePlaceholders.filter { !self.profilePayloads.contains($0) }
            }

        case .managedPreferencesDeveloper:
            return ProfilePayloads.shared.managedPreferencePlaceholders(forType: type)

        case .managedPreferencesApplicationsLocal:
            if var applicationManagedPreferenceLocalPlaceholders = ProfilePayloads.shared.managedPreferenceLocalPlaceholders(forType: type) {
                if UserDefaults.standard.bool(forKey: PreferenceKey.payloadLibraryShowApplicationsFolderOnly) {
                    applicationManagedPreferenceLocalPlaceholders = applicationManagedPreferenceLocalPlaceholders.filter {
                        guard let managedPreferenceLocalPath = ($0.payload as? PayloadManagedPreferenceLocal)?.appPath else { return false }
                        return managedPreferenceLocalPath.hasPrefix("/Applications")
                    }
                }
                return applicationManagedPreferenceLocalPlaceholders.filter { !self.profilePayloads.contains($0) }
            }
        case .all:
            Log.shared.error(message: "Invalid type: \(type) for function: \(#function)", category: String(describing: self))
        }
        return nil
    }

    // swiftlint:enable cyclomatic_complexity
    private func move(payloadPlaceholders: [PayloadPlaceholder], from: TableViewTag, to: TableViewTag) -> Bool {

        // ---------------------------------------------------------------------
        //  Set whether to enable or disable the payload
        // ---------------------------------------------------------------------
        let selected = to == .profilePayloads

        // ---------------------------------------------------------------------
        //  Loop through all placeholders and move them between the arrays
        // ---------------------------------------------------------------------
        for payloadPlaceholder in payloadPlaceholders {
            if from == TableViewTag.libraryPayloads {

                // Verify all platforms are compatible
                if self.profilePayloads.contains(where: { $0.payload.platforms.isDisjoint(with: payloadPlaceholder.payload.platforms) }) {
                    if let window = self.profilePayloadsTableView.window {
                        let informativeText = NSLocalizedString("The payload type \(payloadPlaceholder.title) is only available on the following platforms:\n\n\(PayloadUtility.string(fromPlatforms: payloadPlaceholder.payload.platforms, separator: ","))\n\nThe profile already contain payloads with platform requirements incompatible with this payload", comment: "")
                        let alert = Alert()
                        alert.showAlert(message: NSLocalizedString("Incompatible Platforms", comment: ""),
                                        informativeText: informativeText,
                                        window: window,
                                        firstButtonTitle: ButtonTitle.ok,
                                        secondButtonTitle: nil,
                                        thirdButtonTitle: nil,
                                        firstButtonState: true,
                                        sender: nil) { _ in }
                    }
                    return false
                }

                // Verify all scopes are compatible
                if self.profilePayloads.contains(where: { $0.payload.targets.isDisjoint(with: payloadPlaceholder.payload.targets) }) {
                    if let window = self.profilePayloadsTableView.window {
                        let informativeText = NSLocalizedString("The payload type \(payloadPlaceholder.title) is only available in the following scope:\n\n\(PayloadUtility.string(fromTargets: payloadPlaceholder.payload.targets, separator: ","))\n\nThe profile already contain payloads with scope requirements incompatible with this payload", comment: "")
                        let alert = Alert()
                        alert.showAlert(message: NSLocalizedString("Incompatible Scope", comment: ""),
                                        informativeText: informativeText,
                                        window: window,
                                        firstButtonTitle: ButtonTitle.ok,
                                        secondButtonTitle: nil,
                                        thirdButtonTitle: nil,
                                        firstButtonState: true,
                                        sender: nil) { _ in }
                    }
                    return false
                }

                self.libraryPayloads = self.libraryPayloads.filter { $0 != payloadPlaceholder }
                self.profilePayloads.append(payloadPlaceholder)
            } else if from == TableViewTag.profilePayloads {
                self.profilePayloads = self.profilePayloads.filter { $0 != payloadPlaceholder }
                if let tag = self.selectedLibraryTag, payloadPlaceholder.payloadType == tag {
                    self.libraryPayloads.append(payloadPlaceholder)
                }
            }

            // ---------------------------------------------------------------------
            //  Post a notification that the payload has changed enabled state
            // ---------------------------------------------------------------------
            NotificationCenter.default.post(name: .didChangePayloadSelected, object: self, userInfo: [NotificationKey.payloadPlaceholder: payloadPlaceholder,
                                                                                                      NotificationKey.payloadSelected: selected ])
        }

        // ---------------------------------------------------------------------
        //  Update the Enabled state for the payload domain
        // ---------------------------------------------------------------------
        for placeholder in payloadPlaceholders {
            self.editor?.updatePayloadSelection(selected: selected, payload: placeholder.payload)
        }

        // ---------------------------------------------------------------------
        //  Reload both TableViews
        // ---------------------------------------------------------------------
        self.reloadTableviews()

        return true
    }

    private func select(payloadPlaceholder: PayloadPlaceholder, in: NSTableView) {

        // ---------------------------------------------------------------------
        //  Update stored selection with payloadPlaceholder
        // ---------------------------------------------------------------------
        self.selectedPayloadPlaceholder = payloadPlaceholder

        // ---------------------------------------------------------------------
        //  Tell editor to show the selected payload
        // ---------------------------------------------------------------------
        if let editor = self.editor {
            editor.select(payloadPlaceholder: payloadPlaceholder, ignoreCurrentSelection: false)
        }
    }

    @objc func tableViewDoubleClick(_ tableView: NSTableView) {
        if tableView.clickedRow == -1 {
            if tableView == self.profilePayloadsTableView, self.profilePayloadsTableView.selectedRow == -1 {
                self.libraryPayloadsTableView.window?.makeFirstResponder(self.libraryPayloadsTableView)
            } else if tableView == self.libraryPayloadsTableView, self.libraryPayloadsTableView.selectedRow == -1 {
                self.profilePayloadsTableView.window?.makeFirstResponder(self.profilePayloadsTableView)
            }
        }
    }

    private func addProfilePayloads() {

        // ---------------------------------------------------------------------
        //  Add all selected placeholders to the profile placeholders array
        // ---------------------------------------------------------------------
        if let profile = self.editor?.profile {

            // Reset
            self.profilePayloads = [PayloadPlaceholder]()

            for (typeInt, typeSettings) in profile.settings.settingsPayload {

                // ---------------------------------------------------------------------
                //  Verify we got a valid type and a non empty settings dict
                // ---------------------------------------------------------------------
                guard let type = PayloadType(rawValue: typeInt) else { continue }

                // ---------------------------------------------------------------------
                //  Loop through all domains and settings for the current type, add all enabled
                // ---------------------------------------------------------------------
                for domainIdentifier in typeSettings.keys where profile.settings.isIncludedInProfile(domainIdentifier: domainIdentifier, type: type) {
                    if type == .custom {
                        if
                            let payloadContent = typeSettings[domainIdentifier],
                            let payload = ProfilePayloads.shared.customManifest(forDomainIdentifier: domainIdentifier, ofType: type, payloadContent: payloadContent),
                            let payloadPlaceholder = payload.placeholder {
                            self.profilePayloads.append(payloadPlaceholder)
                        } else {
                            Log.shared.error(message: "Failed to ge payload and placehoder for unknown payload with content: \(String(describing: typeSettings[domainIdentifier]?.first))", category: String(describing: self))
                        }
                    } else if
                        let payload = ProfilePayloads.shared.payload(forDomainIdentifier: domainIdentifier, type: type),
                        let payloadPlaceholder = payload.placeholder {
                        self.profilePayloads.append(payloadPlaceholder)
                    }
                }
            }

            if
                !self.profilePayloads.contains(where: { $0.domain == kManifestDomainConfiguration }),
                let generalPayloadPlaceholder = self.generalPayloadPlaceholder {
                self.profilePayloads.append(generalPayloadPlaceholder)
            }
        }
    }

    private func setupProfilePayloads() {

        // ---------------------------------------------------------------------
        //  Setup TableView
        // ---------------------------------------------------------------------
        self.profilePayloadsTableView.translatesAutoresizingMaskIntoConstraints = false
        self.profilePayloadsTableView.focusRingType = .none
        self.profilePayloadsTableView.rowSizeStyle = .default
        self.profilePayloadsTableView.floatsGroupRows = false
        self.profilePayloadsTableView.headerView = nil
        self.profilePayloadsTableView.allowsMultipleSelection = false
        self.profilePayloadsTableView.tag = TableViewTag.profilePayloads.rawValue
        self.profilePayloadsTableView.intercellSpacing = NSSize(width: 0, height: 0)
        self.profilePayloadsTableView.registerForDraggedTypes([.payload])
        self.profilePayloadsTableView.dataSource = self
        self.profilePayloadsTableView.delegate = self
        self.profilePayloadsTableView.target = self
        self.profilePayloadsTableView.doubleAction = #selector(self.tableViewDoubleClick(_:))
        self.profilePayloadsTableView.sizeLastColumnToFit()

        // ---------------------------------------------------------------------
        //  Setup TableColumn
        // ---------------------------------------------------------------------
        let tableColumn = NSTableColumn(identifier: .tableColumnProfilePayloads)
        tableColumn.isEditable = false
        self.profilePayloadsTableView.addTableColumn(tableColumn)

        // ---------------------------------------------------------------------
        //  Setup ScrollView
        // ---------------------------------------------------------------------
        self.profilePayloadsScrollView.translatesAutoresizingMaskIntoConstraints = false
        self.profilePayloadsScrollView.documentView = self.profilePayloadsTableView
        self.profilePayloadsScrollView.hasVerticalScroller = true
        self.profilePayloadsScrollView.verticalScroller = OverlayScroller()

        // ---------------------------------------------------------------------
        //  Add all payloads selected in the profile
        // ---------------------------------------------------------------------
        self.addProfilePayloads()
    }

    private func setupLibraryPayloads() {

        // ---------------------------------------------------------------------
        //  Setup TableView
        // ---------------------------------------------------------------------
        self.libraryPayloadsTableView.translatesAutoresizingMaskIntoConstraints = false
        self.libraryPayloadsTableView.focusRingType = .none
        self.libraryPayloadsTableView.rowSizeStyle = .default
        self.libraryPayloadsTableView.floatsGroupRows = true
        self.libraryPayloadsTableView.headerView = nil
        self.libraryPayloadsTableView.allowsMultipleSelection = false
        self.libraryPayloadsTableView.tag = TableViewTag.libraryPayloads.rawValue
        self.libraryPayloadsTableView.intercellSpacing = NSSize(width: 0, height: 0)
        self.libraryPayloadsTableView.registerForDraggedTypes([.payload])
        self.libraryPayloadsTableView.dataSource = self
        self.libraryPayloadsTableView.delegate = self
        self.libraryPayloadsTableView.target = self
        self.libraryPayloadsTableView.doubleAction = #selector(self.tableViewDoubleClick(_:))
        self.libraryPayloadsTableView.sizeLastColumnToFit()

        // ---------------------------------------------------------------------
        //  Setup TableColumn
        // ---------------------------------------------------------------------
        let tableColumn = NSTableColumn(identifier: .tableColumnLibraryPayloads)
        tableColumn.isEditable = false
        self.libraryPayloadsTableView.addTableColumn(tableColumn)

        // ---------------------------------------------------------------------
        //  Setup ScrollView
        // ---------------------------------------------------------------------
        self.libraryPayloadsScrollView.translatesAutoresizingMaskIntoConstraints = false
        self.libraryPayloadsScrollView.documentView = self.libraryPayloadsTableView
        self.libraryPayloadsScrollView.hasVerticalScroller = true
        self.libraryPayloadsScrollView.verticalScroller = OverlayScroller()
    }
}

extension PayloadLibraryTableViews: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.profilePayloadsTableView {
            return self.profilePayloads.count
        } else if tableView == self.libraryPayloadsTableView {
            return self.libraryPayloadsCellViews.count
        }
        return 0
    }

    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {

        if tableView == self.profilePayloadsTableView && rowIndexes.contains(0) {

            // -----------------------------------------------------------------
            //  Do not allow drag drop with General settings (at index 0)
            // -----------------------------------------------------------------
            return false
        }

        var selectedPayloadPlaceholders = [PayloadPlaceholder]()
        if tableView == self.profilePayloadsTableView {
            selectedPayloadPlaceholders = self.profilePayloads.objectsAtIndexes(indexes: rowIndexes)
        } else if tableView == self.libraryPayloadsTableView {
            if let selectedCellViews = self.libraryPayloadsCellViews.objectsAtIndexes(indexes: rowIndexes) as? [PayloadLibraryCellViewLibrary] {
                selectedPayloadPlaceholders = selectedCellViews.compactMap { $0.placeholder }
            }
        }

        do {
            let encodedData = try JSONEncoder().encode(selectedPayloadPlaceholders)
            pboard.clearContents()
            pboard.declareTypes([.payload], owner: nil)
            pboard.setData(encodedData, forType: .payload)
        } catch {
            Log.shared.error(message: "Failed to encode payload placeholder with error: \(error)", category: String(describing: self))
        }

        return true
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if let infoSource = info.draggingSource as? NSTableView, tableView == infoSource || dropOperation == .on {
            return NSDragOperation()
        } else {
            tableView.setDropRow(-1, dropOperation: .on)
            return .copy
        }
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        if let data = info.draggingPasteboard.data(forType: .payload) {
            do {
                let payloadPlaceholders = try JSONDecoder().decode([PayloadPlaceholder].self, from: data)
                if tableView == self.profilePayloadsTableView {
                    return self.move(payloadPlaceholders: payloadPlaceholders, from: .libraryPayloads, to: .profilePayloads)
                } else if tableView == self.libraryPayloadsTableView {
                    return self.move(payloadPlaceholders: payloadPlaceholders, from: .profilePayloads, to: .libraryPayloads)
                }
            } catch {
                Log.shared.error(message: "Failed to decode dropped item: \(info)", category: String(describing: self))
            }
        }
        return false
    }
}

extension PayloadLibraryTableViews: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if tableView == self.profilePayloadsTableView {
            return 40
        } else if tableView == self.libraryPayloadsTableView {

            // Group Rows
            if self.libraryPayloadsCellViews[row] is PayloadLibraryCellViewGroup {
                return 20
            } else {
                return 32
            }
        }
        return 1
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == self.profilePayloadsTableView {
            return PayloadLibraryCellViewProfile(payloadPlaceholder: self.profilePayloads[row], profile: self.profile)
        } else if tableView == self.libraryPayloadsTableView, let cellView = self.libraryPayloadsCellViews[row] as? NSTableCellView {
            return cellView
        }
        return nil
    }

    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        tableView == self.libraryPayloadsTableView && self.libraryPayloadsCellViews[row] is PayloadLibraryCellViewGroup
    }

    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {

        // ---------------------------------------------------------------------
        //  Ignore Empty Selections
        // ---------------------------------------------------------------------
        if proposedSelectionIndexes.isEmpty {
            return IndexSet(integer: -1)

            // ---------------------------------------------------------------------
            //  Ignore Groups Row Selections
            // ---------------------------------------------------------------------
        } else if tableView == self.libraryPayloadsTableView, let row = proposedSelectionIndexes.first, self.libraryPayloadsCellViews[row] is PayloadLibraryCellViewGroup {
            return IndexSet(integer: -1)
        }
        return proposedSelectionIndexes
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tableView = notification.object as? NSTableView,
            !tableView.selectedRowIndexes.isEmpty {
            if tableView == self.profilePayloadsTableView {
                self.libraryPayloadsTableView.deselectAll(self)
                self.select(payloadPlaceholder: self.profilePayloads[tableView.selectedRow], in: tableView)
            } else if tableView == self.libraryPayloadsTableView {
                self.profilePayloadsTableView.deselectAll(self)
                if let cellView = self.libraryPayloadsCellViews[tableView.selectedRow] as? PayloadLibraryCellViewLibrary, let placeholder = cellView.placeholder {
                    self.select(payloadPlaceholder: placeholder, in: tableView)
                }
            }
        }
    }
}

extension PayloadLibraryTableViews: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        NSDragOperation.copy
    }
}

// -----------------------------------------------------------------------------
//  Used by the "No Payloads" view
// -----------------------------------------------------------------------------
extension PayloadLibraryTableViews: NSDraggingDestination {
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // FIXME - Here forcing a focus ring would fit, haven't looked into how to yet.
        return NSDragOperation.copy
    }

    func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        true
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if
            let data = sender.draggingPasteboard.data(forType: .payload),
            let sourceTableView = sender.draggingSource as? NSTableView {
            do {
                let payloadPlaceholders = try JSONDecoder().decode([PayloadPlaceholder].self, from: data)
                if sourceTableView == self.profilePayloadsTableView {
                    return self.move(payloadPlaceholders: payloadPlaceholders, from: .profilePayloads, to: .libraryPayloads)
                } else if sourceTableView == self.libraryPayloadsTableView {
                    return self.move(payloadPlaceholders: payloadPlaceholders, from: .libraryPayloads, to: .profilePayloads)
                }
            } catch {
                Log.shared.error(message: "Failed to decode dropped payload placeholder items with error: \(error)", category: String(describing: self))
            }
        }
        return false
    }
}

extension PayloadLibraryTableViews: PayloadLibraryTableViewDelegate {
    func payloadPlaceholder(atRow row: Int, in tableView: PayloadLibraryTableView) -> PayloadPlaceholder? {
        if tableView == self.profilePayloadsTableView, row < self.profilePayloads.count {
            return self.profilePayloads[row]
        } else if tableView == self.libraryPayloadsTableView, row < self.libraryPayloadsCellViews.count, let cellView = self.libraryPayloadsCellViews[row] as? PayloadLibraryCellViewLibrary {
            return cellView.placeholder
        }
        return nil
    }
}

class PayloadLibraryTableView: NSTableView {

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: NSRect.zero)
    }

    // -------------------------------------------------------------------------
    //  Override menu(for event:) to show a contextual menu
    // -------------------------------------------------------------------------
    override func menu(for event: NSEvent) -> NSMenu? {

        guard let tableViewTag = TableViewTag(rawValue: self.tag) else { return nil }

        // ---------------------------------------------------------------------
        //  Get row that was clicked
        // ---------------------------------------------------------------------
        let point = self.convert(event.locationInWindow, from: nil)
        let row = self.row(at: point)
        if row < 0 { return nil }

        // ---------------------------------------------------------------------
        //  Verify a PayloadPlaceholder was clicked, else don't return a menu
        // ---------------------------------------------------------------------
        guard
            let delegate = self.delegate as? PayloadLibraryTableViews,
            let clickedPayloadPlaceholder = delegate.payloadPlaceholder(atRow: row, in: self),
            clickedPayloadPlaceholder.domain != kManifestDomainConfiguration else {
                return nil
        }

        // ---------------------------------------------------------------------
        //  Create menu
        // ---------------------------------------------------------------------
        let menu = NSMenu()

        // ---------------------------------------------------------------------
        //  Add item: "Edit"
        // ---------------------------------------------------------------------
        let menuItemAddRemove = NSMenuItem()
        menuItemAddRemove.isEnabled = true
        menuItemAddRemove.target = self.delegate
        menuItemAddRemove.tag = row
        if tableViewTag == .profilePayloads, let tableViewDelegate = self.delegate as? PayloadLibraryTableViews {
            menuItemAddRemove.title = NSLocalizedString("Remove", comment: "") + " \"\(clickedPayloadPlaceholder.title)\" " + NSLocalizedString("from Profile", comment: "")
            menuItemAddRemove.action = #selector(tableViewDelegate.removeClickedPayload(_:))
        } else if tableViewTag == .libraryPayloads, let tableViewDelegate = self.delegate as? PayloadLibraryTableViews {
            menuItemAddRemove.title = NSLocalizedString("Add", comment: "") + " \"\(clickedPayloadPlaceholder.title)\" " + NSLocalizedString("to Profile", comment: "")
            menuItemAddRemove.action = #selector(tableViewDelegate.addClickedPayload(_:))
        }

        //
        menu.addItem(menuItemAddRemove)

        // ---------------------------------------------------------------------
        //  Return menu
        // ---------------------------------------------------------------------
        return menu
    }

}
