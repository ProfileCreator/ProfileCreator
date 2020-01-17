//
//  PreferencesPayloads.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PreferencesPayloads: PreferencesItem {

    // MARK: -
    // MARK: Variables

    let identifier: NSToolbarItem.Identifier = .preferencesPayloads
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
        self.toolbarItem.label = NSLocalizedString("Payloads", comment: "")
        self.toolbarItem.paletteLabel = self.toolbarItem.label
        self.toolbarItem.toolTip = self.toolbarItem.label
        self.toolbarItem.target = sender
        self.toolbarItem.action = #selector(sender.toolbarItemSelected(_:))

        // ---------------------------------------------------------------------
        //  Create the preferences view
        // ---------------------------------------------------------------------
        self.view = PreferencesPayloadManifestsView()
    }
}

class PreferencesPayloadManifestsView: NSView, PreferencesView {

    // MARK: -
    // MARK: Variables

    var height: CGFloat = 0.0
    var buttonCheckForUpdates: NSButton?
    var buttonDownloadUpdates: NSButton?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()
        var lastSubview: NSView?
        var lastTextField: NSView?

        // ---------------------------------------------------------------------
        //  Add Preferences "Payload Library"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Payload Library", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: nil,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Custom", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.payloadLibraryShowCustom,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Apple Domains", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.payloadLibraryShowDomainsApple,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Apple Managed Preferences", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.payloadLibraryShowManagedPreferencesApple,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Application Managed Preferences", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.payloadLibraryShowManagedPreferencesApplications,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Application Managed Preferences Local", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.payloadLibraryShowManagedPreferencesApplicationsLocal,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add Preferences "Payload Library Display Settings"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Payload Library Display Settings", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: lastSubview,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Domain as Title", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.payloadLibraryShowDomainAsTitle,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Local Preferences For Applications Only", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.payloadLibraryShowApplicationsFolderOnly,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add Preferences "Payload Manifests"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Payload Manifests", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: lastSubview,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Automatically check for updates (on launch)", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.payloadManifestsAutomaticallyCheckForUpdates,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Automatically download available updates", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.payloadManifestsAutomaticallyDownloadUpdates,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addSeparator(toView: self,
                                   lastSubview: lastSubview,
                                   height: &self.height,
                                   topIndent: 20.0,
                                   constraints: &constraints)

        let buttonCheckForUpdatesLabel = self.lastUpdateString(forDate: UserDefaults.standard.value(forKey: PreferenceKey.payloadManifestsUpdatesLastCheck) as? Date ?? Date())
        lastSubview = addButton(label: buttonCheckForUpdatesLabel,
                                title: NSLocalizedString("Check Now", comment: ""),
                                bindToEnabled: nil,
                                bindKeyPathEnabled: nil,
                                target: self,
                                selector: #selector(self.checkNow(_:)),
                                toView: self,
                                lastSubview: lastSubview,
                                lastTextField: nil,
                                height: &self.height,
                                indent: kPreferencesIndent,
                                constraints: &constraints)
        lastTextField = lastSubview
        if let buttonCheck = lastSubview as? NSButton {
            self.buttonCheckForUpdates = buttonCheck
        }

        lastSubview = addButton(label: nil,
                                title: NSLocalizedString("Update", comment: ""),
                                bindToEnabled: UserDefaults.standard,
                                bindKeyPathEnabled: PreferenceKey.payloadManifestsUpdatesAvailable,
                                target: self,
                                selector: #selector(self.updateNow(_:)),
                                toView: self,
                                lastSubview: lastSubview,
                                lastTextField: lastTextField,
                                height: &self.height,
                                indent: kPreferencesIndent,
                                constraints: &constraints)
        if let buttonDownload = lastSubview as? NSButton {
            self.buttonDownloadUpdates = buttonDownload
        }

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

    func lastUpdateString(forDate date: Date?) -> String {
        if let lastCheckDate = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            let dateString = dateFormatter.string(from: lastCheckDate)
            return NSLocalizedString("Last check was \(dateString)", comment: "")
        }
        return NSLocalizedString("Never Checked", comment: "")
    }

    @objc func checkNow(_ button: NSButton) {
        self.checkUpdates(downloadUpdates: false)
    }

    func checkUpdates(downloadUpdates: Bool) {
        guard let buttonCheck = self.buttonCheckForUpdates else { return }
        buttonCheck.isEnabled = false
        Log.shared.debug(message: "Fetching manifest repository index...", category: String(describing: self))
        ManifestRepositories.shared.fetchIndexes(ignoreCache: true) { result in
            buttonCheck.isEnabled = true
            if case let .success(updates) = result {
                Log.shared.debug(message: "Manifest repository has the following available updates: \(updates)", category: String(describing: self))
                UserDefaults.standard.setValue(Date(), forKey: PreferenceKey.payloadManifestsUpdatesLastCheck)
                UserDefaults.standard.setValue(!updates.isEmpty, forKey: PreferenceKey.payloadManifestsUpdatesAvailable)

                if !updates.isEmpty {
                    NotificationCenter.default.post(name: .payloadUpdatesAvailable, object: self, userInfo: nil)
                    if downloadUpdates {
                        self.downloadUpdates()
                    } else {
                        // FIXME: Show PopUp Button that updates are available
                    }
                }
            } else if case let .failure(error) = result {

                // FIXME:  Write error to error string or show some error icon with this as the tooltip etc.
                Log.shared.error(message: "Fetching manifest repository index failed with error: \(error)", category: String(describing: self))
            }
        }
    }

    @objc func updateNow(_ button: NSButton) {
        self.downloadUpdates()
    }

    func downloadUpdates() {
        guard let buttonDownload = self.buttonDownloadUpdates else { return }
        buttonDownload.isEnabled = false
        Log.shared.debug(message: "Downloading manifest repository items...", category: String(describing: self))
        ManifestRepositories.shared.downloadUpdates { result in
            buttonDownload.isEnabled = true
            if case .success(_) = result {
                UserDefaults.standard.setValue(false, forKey: PreferenceKey.payloadManifestsUpdatesAvailable)
                NotificationCenter.default.post(name: .payloadUpdatesDownloaded, object: self, userInfo: nil)
                self.checkUpdates(downloadUpdates: false)
                // FIXME: Show PopUp Button that x updates were installed
            } else if case let .failure(error) = result {
                // Write error to error string or show some error icon with this as the tooltip etc.
                Log.shared.error(message: "Downloading manifest repository items failed with error: \(error)", category: String(describing: self))
            }
        }
    }
}
