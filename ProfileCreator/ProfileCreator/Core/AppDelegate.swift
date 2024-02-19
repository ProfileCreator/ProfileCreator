//
//  AppDelegate.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: -
    // MARK: Variables

    let mainWindowController: MainWindowController
    let preferencesWindowController: PreferencesWindowController

    @IBOutlet private weak var checkForUpdateMenuItem: NSMenuItem!

    // MARK: -
    // MARK: Initialization

    override init() {

        // ---------------------------------------------------------------------
        //  Initialize value transformers
        // ---------------------------------------------------------------------
        ValueTransformer.setValueTransformer(HexColorTransformer(), forName: HexColorTransformer.name)

        // ---------------------------------------------------------------------
        //  Set key 'PayloadManifestsUpdatesAvailable' to false
        // ---------------------------------------------------------------------
        UserDefaults.standard.setValue(false, forKey: PreferenceKey.payloadManifestsUpdatesAvailable)

        self.mainWindowController = MainWindowController()
        self.preferencesWindowController = PreferencesWindowController()

        super.init()
    }

    // MARK: -
    // MARK: NSApplicationDelegate Methods

    func payloadTypesEnabled() -> [PayloadType] {
        var payloadTypes: [PayloadType] = [.manifestsApple,
                                           .managedPreferencesApple,
                                           .managedPreferencesApplications]
        #if DEBUG
            payloadTypes.append(.managedPreferencesDeveloper)
        #endif
        if UserDefaults.standard.bool(forKey: PreferenceKey.payloadLibraryShowManagedPreferencesApplicationsLocal) {
            payloadTypes.append(.managedPreferencesApplicationsLocal)
        }
        return payloadTypes
    }

    func applicationWillFinishLaunching(_ notification: Notification) {

        // ---------------------------------------------------------------------
        //  Register user defaults
        // ---------------------------------------------------------------------
        Log.shared.info(message: "Registering defaults…", category: String(describing: self))
        self.registerDefaults()

        // ---------------------------------------------------------------------
        //  Initialize application menus
        // ---------------------------------------------------------------------
        Log.shared.info(message: "Configuring menu items…", category: String(describing: self))
        self.configureMenuItems()

        // ---------------------------------------------------------------------
        //  Initialize profile payloads
        // ---------------------------------------------------------------------
        Log.shared.info(message: "Initializing payloads…", category: String(describing: self))
        ProfilePayloads.shared.initializePayloads(ofType: self.payloadTypesEnabled())

        // ---------------------------------------------------------------------
        //  Check and set all preferences triggered by application launch
        // ---------------------------------------------------------------------
        Log.shared.info(message: "Checking launch preferences…", category: String(describing: self))
        self.checkLaunchPreferences()

        // ---------------------------------------------------------------------
        //  Show main window
        // ---------------------------------------------------------------------
        if let mainWindow = self.mainWindowController.window {
            mainWindow.makeKeyAndOrderFront(self)

            if 0 < ProfileController.sharedInstance.profileLoadErrorCount {
                self.showLoadError(inWindow: mainWindow, oldVersionCount: ProfileController.sharedInstance.profileLoadErrorCount)
            }
        }
    }

    private func showLoadError(inWindow window: NSWindow, oldVersionCount: Int) {
        let alert = Alert()
        let alertMessage = NSLocalizedString("New save format introduced in Beta 5.", comment: "")
        let alertInformativeText = NSLocalizedString("You have \(oldVersionCount) saved \(oldVersionCount == 1 ? "profile" : "profiles") that \(oldVersionCount == 1 ? "is" : "are") too old for this version of ProfileCreator.\n\nTo move the \(oldVersionCount == 1 ? "profile" : "profiles") to this version you need to export a .mobileconfig using Beta 4 and import it using drag and drop or selecting File -> Import.\n\nThis is because of a breaking change needed to make profile import possible. You can read more about this in the Beta 5 release notes.", comment: "")

        Log.shared.error(message: alertMessage, category: String(describing: self))
        Log.shared.error(message: alertInformativeText, category: String(describing: self))

        alert.showAlert(message: alertMessage, informativeText: alertInformativeText, window: window, firstButtonTitle: ButtonTitle.ok, secondButtonTitle: "Open Save Folder", thirdButtonTitle: "Download Beta 4", firstButtonState: true, sender: self) { response in
            switch response {
            case .alertSecondButtonReturn:
                if let saveFolderURL = URL(applicationDirectory: .profiles) {
                    NSWorkspace.shared.open(saveFolderURL)
                }
            case .alertThirdButtonReturn:
                if let githubURL = URL(string: "https://github.com/erikberglund/ProfileCreator/releases/tag/v0.1-beta.4") {
                    NSWorkspace.shared.open(githubURL)
                }
            default:
                return
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.activate(ignoringOtherApps: false)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            if let mainWindow = self.mainWindowController.window {
                mainWindow.makeKeyAndOrderFront(self)
                NSApplication.shared.activate(ignoringOtherApps: false)
            }
            return false
        } else {
            return true
        }
    }

    // MARK: -
    // MARK: Initialization

    func registerDefaults() {

        // ---------------------------------------------------------------------
        //  Get URL to application default settings
        // ---------------------------------------------------------------------
        guard let defaultSettingsURL = Bundle.main.url(forResource: "DefaultPreferences", withExtension: "plist") else {
            Log.shared.error(message: "No bundle defaults file found")
            return
        }

        // ---------------------------------------------------------------------
        //  Register default settings with UserDefaults
        // ---------------------------------------------------------------------
        if let defaultSettings = NSDictionary(contentsOf: defaultSettingsURL) as? [String: Any] {
            UserDefaults.standard.register(defaults: defaultSettings)
        }
    }

    func checkLaunchPreferences() {

        // ---------------------------------------------------------------------
        //  If key 'PayloadManifestsAutomaticallyCheckForUpdates' is true, run payload updates check
        // ---------------------------------------------------------------------
        if UserDefaults.standard.bool(forKey: PreferenceKey.payloadManifestsAutomaticallyCheckForUpdates) {
            if let manifestsView = self.preferencesWindowController.preferencesPayloads?.view as? PreferencesPayloadManifestsView {
                manifestsView.checkUpdates(downloadUpdates: UserDefaults.standard.bool(forKey: PreferenceKey.payloadManifestsAutomaticallyDownloadUpdates))
            }
        }
    }

    // ---------------------------------------------------------------------
    //  Handle file opens
    // ---------------------------------------------------------------------
    func application(_ application: NSApplication, open urls: [URL]) {
        self.open(urls, sender: application)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        self.open(filenames.compactMap { URL(fileURLWithPath: $0) }, sender: sender)
    }

    func open(_ urls: [URL], sender: NSApplication) {
        // FIXME: Not Implemented
        Log.shared.debug(message: "NOT IMPLEMENTED - Opening URLS: \(urls) from application: \(sender)", category: String(describing: self))
    }

    func configureMenuItems() {

        // ---------------------------------------------------------------------
        //  Show the developer menu item if enabled
        // ---------------------------------------------------------------------
        self.showMenuDeveloper(UserDefaults.standard.bool(forKey: PreferenceKey.showDeveloperMenu))

        // ---------------------------------------------------------------------
        //  Hide the 'Check For Updates...' menu item if non Mac App Store distribution
        // ---------------------------------------------------------------------
        #if !SPARKLE
        self.checkForUpdateMenuItem.isEnabled = false
        self.checkForUpdateMenuItem.isHidden = true
        #endif
    }

    func showMenuDeveloper(_ show: Bool) {

        // ---------------------------------------------------------------------
        //  Get main menu
        // ---------------------------------------------------------------------
        guard let mainMenu = NSApplication.shared.mainMenu else { return }

        let isDisplayed = mainMenu.items.contains { $0.title == NSLocalizedString("Developer", comment: "") }

        if show, !isDisplayed {
            let developerMenu = NSMenu(title: NSLocalizedString("Developer", comment: ""))
            let developerMenuItem = NSMenuItem(title: NSLocalizedString("Developer", comment: ""), action: nil, keyEquivalent: "")
            developerMenuItem.submenu = developerMenu

            let developerMenuItemReloadPayloadManifests = NSMenuItem(title: NSLocalizedString("Reload Payload Manifest", comment: ""), action: #selector(self.menuItemReloadPayloadManifests(_:)), keyEquivalent: "r")
            developerMenuItemReloadPayloadManifests.keyEquivalentModifierMask = [.option, .command]
            developerMenu.addItem(developerMenuItemReloadPayloadManifests)

            let developerMenuItemShowPayloadManifest = NSMenuItem(title: NSLocalizedString("Show Payload Manifest", comment: ""), action: #selector(self.menuItemShowPayloadManifest(_:)), keyEquivalent: "")
            developerMenu.addItem(developerMenuItemShowPayloadManifest)

            let developerMenuItemShowPayloadManifestInFinder = NSMenuItem(title: NSLocalizedString("Show Payload Manifest in Finder", comment: ""), action: #selector(self.menuItemShowPayloadManifestInFinder(_:)), keyEquivalent: "")
            developerMenu.addItem(developerMenuItemShowPayloadManifestInFinder)

            mainMenu.addItem(developerMenuItem)
        } else if isDisplayed {
            let developerMenuIndex = mainMenu.indexOfItem(withTitle: "Developer")
            if 0 <= developerMenuIndex {
                mainMenu.removeItem(at: developerMenuIndex)
            }
        }
    }

    // MARK: -
    // MARK: NSMenuItem Actions

    @IBAction private func menuItemMainWindow(_ menuItem: NSMenuItem?) {
        self.mainWindowController.window?.makeKeyAndOrderFront(self)
    }

    @IBAction private func menuItemPreferences(_ menuItem: NSMenuItem?) {
        self.preferencesWindowController.window?.makeKeyAndOrderFront(self)
    }

    @IBAction private func menuItemDuplicate(_ menuItem: NSMenuItem?) {
        guard let currentWindowController = NSApplication.shared.keyWindow?.windowController else { return }
        if let mainWindowController = currentWindowController as? MainWindowController {
            let mainWindowTableViewController = mainWindowController.splitView.tableViewController
            if let identifier = mainWindowTableViewController.profileIdentifiers(atIndexes: mainWindowTableViewController.tableView.selectedRowIndexes)?.first {
                ProfileController.sharedInstance.duplicateProfile(withIdentifier: identifier, promptWindow: mainWindowController.window)
            }
        } else if let profileEditorWindowController = currentWindowController as? ProfileEditorWindowController {
            ProfileController.sharedInstance.duplicateProfile(withIdentifier: profileEditorWindowController.profile.identifier, promptWindow: profileEditorWindowController.window)
        }
    }

    @IBAction private func menuItemExport(_ menuItem: NSMenuItem?) {
        guard let currentWindowController = NSApplication.shared.keyWindow?.windowController else { return }
        if let mainWindowController = currentWindowController as? MainWindowController {
            let mainWindowTableViewController = mainWindowController.splitView.tableViewController
            if let identifiers = mainWindowTableViewController.profileIdentifiers(atIndexes: mainWindowTableViewController.tableView.selectedRowIndexes) {
                ProfileController.sharedInstance.exportProfiles(withIdentifiers: identifiers, promptWindow: mainWindowController.window)
            }
        } else if let profileEditorWindowController = currentWindowController as? ProfileEditorWindowController {
            ProfileController.sharedInstance.exportProfile(withIdentifier: profileEditorWindowController.profile.identifier, promptWindow: profileEditorWindowController.window)
        }
    }

    @objc func menuItemReloadPayloadManifests(_ menuItem: NSMenuItem?) {
        ProfilePayloads.shared.updateManifests()
        NotificationCenter.default.post(name: .payloadUpdatesDownloaded, object: self, userInfo: nil)
    }

    @objc func menuItemShowPayloadManifest(_ menuItem: NSMenuItem?) {
        guard let keyWindow = NSApplication.shared.keyWindow else { return }
        guard let profileEditorWindowController = keyWindow.windowController as? ProfileEditorWindowController else { return }
        guard let profileEditor = profileEditorWindowController.splitView.editor else { return }
        profileEditor.updateSourceViewManifest()
    }

    @objc func menuItemShowPayloadManifestInFinder(_ menuItem: NSMenuItem?) {
        guard let keyWindow = NSApplication.shared.keyWindow else { return }
        guard let profileEditorWindowController = keyWindow.windowController as? ProfileEditorWindowController else { return }
        guard let profileEditor = profileEditorWindowController.splitView.editor else { return }
        guard let manifestURL = profileEditor.selectedPayloadPlaceholder?.payload.manifestURL else { return }
        NSWorkspace.shared.selectFile(manifestURL.path, inFileViewerRootedAtPath: "")
    }

    // MARK: -
    // MARK: NSMenuItem Validations

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let menuItemIdentifier = menuItem.identifier else { return true }
        switch menuItemIdentifier {
        case .menuItemDuplicate,
             .menuItemExport:
            return self.validateMenuItemRequiresSingleSelection()
        default:
            return true
        }
    }

    func validateMenuItemRequiresSingleSelection() -> Bool {
        guard let currentWindowController = NSApplication.shared.keyWindow?.windowController else { return false }
        if let mainWindowController = currentWindowController as? MainWindowController {
            return mainWindowController.splitView.tableViewController.selectedProfileIdentitifers?.count == 1
        } else if currentWindowController is ProfileEditorWindowController {
            return true
        }
        return false
    }
}
