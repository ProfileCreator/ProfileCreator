//
//  PreferencesEditor.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class PreferencesLibrary: PreferencesItem {

    // MARK: -
    // MARK: Variables

    let identifier: NSToolbarItem.Identifier = .preferencesLibrary
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
        self.toolbarItem.label = NSLocalizedString("Library", comment: "")
        self.toolbarItem.paletteLabel = self.toolbarItem.label
        self.toolbarItem.toolTip = self.toolbarItem.label
        self.toolbarItem.target = sender
        self.toolbarItem.action = #selector(sender.toolbarItemSelected(_:))

        // ---------------------------------------------------------------------
        //  Create the preferences view
        // ---------------------------------------------------------------------
        self.view = PreferencesLibraryView()
    }
}

class PreferencesLibraryView: NSView, PreferencesView {

    // MARK: -
    // MARK: Variables

    var height: CGFloat = 0.0
    let checkbox = NSButton(checkboxWithTitle: "Test Checkbox", target: nil, action: nil)

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
        var lastTextField: NSView?

        // ---------------------------------------------------------------------
        //  Add Preferences "Profile Library Path"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Profile Library Path", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: nil,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addTextFieldLabel(label: nil,
                                        placeholderValue: "~/Library/Application Support/ProfileCreator/Profiles",
                                        bindTo: UserDefaults.standard,
                                        keyPath: PreferenceKey.profileLibraryPath,
                                        toView: self,
                                        lastSubview: lastSubview,
                                        lastTextField: lastTextField,
                                        height: &self.height,
                                        constraints: &constraints)
        lastTextField = lastSubview

        lastSubview = addButton(label: nil,
                                title: ButtonTitle.choose,
                                bindToEnabled: nil,
                                bindKeyPathEnabled: nil,
                                target: self,
                                selector: #selector(self.chooseLibraryPath(_:)),
                                toView: self,
                                lastSubview: lastSubview,
                                lastTextField: lastTextField,
                                height: &self.height,
                                indent: kPreferencesIndent,
                                constraints: &constraints)

        lastSubview = addButton(label: nil,
                                title: NSLocalizedString("Restore Defaults", comment: ""),
                                bindToEnabled: nil,
                                bindKeyPathEnabled: nil,
                                target: self,
                                selector: #selector(self.restoreDefaultLibrary(_:)),
                                toView: self,
                                lastSubview: lastSubview,
                                lastTextField: lastSubview,
                                height: &self.height,
                                indent: kPreferencesIndent,
                                constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add Preferences "Profile Group Library Path"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Profile Group Library Path", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: lastSubview,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addTextFieldLabel(label: nil,
                                        placeholderValue: "~/Library/Application Support/ProfileCreator/Groups",
                                        bindTo: UserDefaults.standard,
                                        keyPath: PreferenceKey.profileLibraryGroupPath,
                                        toView: self,
                                        lastSubview: lastSubview,
                                        lastTextField: lastTextField,
                                        height: &self.height,
                                        constraints: &constraints)
        lastTextField = lastSubview

        lastSubview = addButton(label: nil,
                                title: ButtonTitle.choose,
                                bindToEnabled: nil,
                                bindKeyPathEnabled: nil,
                                target: self,
                                selector: #selector(self.chooseLibraryGroupPath(_:)),
                                toView: self,
                                lastSubview: lastSubview,
                                lastTextField: lastTextField,
                                height: &self.height,
                                indent: kPreferencesIndent,
                                constraints: &constraints)

        lastSubview = addButton(label: nil,
                                title: NSLocalizedString("Restore Defaults", comment: ""),
                                bindToEnabled: nil,
                                bindKeyPathEnabled: nil,
                                target: self,
                                selector: #selector(self.restoreDefaultLibraryGroup(_:)),
                                toView: self,
                                lastSubview: lastSubview,
                                lastTextField: lastSubview,
                                height: &self.height,
                                indent: kPreferencesIndent,
                                constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add Preferences "Configuration Files"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Profile Library Configuration Files", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: lastSubview,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addPopUpButton(label: NSLocalizedString("File Name Format", comment: ""),
                                     titles: [ProfileLibraryFileNameFormat.payloadUUID, ProfileLibraryFileNameFormat.payloadIdentifier],
                                     bindTo: UserDefaults.standard,
                                     bindKeyPath: PreferenceKey.profileLibraryFileNameFormat,
                                     toView: self,
                                     lastSubview: lastSubview,
                                     lastTextField: nil,
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

    @objc func restoreDefaultLibrary(_ button: NSButton) {
        if let userApplicationSupport = URL(applicationDirectory: .applicationSupport) {
            let profileLibraryURL = userApplicationSupport.appendingPathComponent("Profiles", isDirectory: true)
            let profileLibraryPathCurrent = UserDefaults.standard.string(forKey: PreferenceKey.profileLibraryPath)

            guard profileLibraryURL.path != profileLibraryPathCurrent else { return }

            UserDefaults.standard.setValue(profileLibraryURL.path, forKey: PreferenceKey.profileLibraryPath)
            if let window = button.window, let oldPath = profileLibraryPathCurrent, !self.shouldMoveProfiles(fromPath: oldPath, window: window) {
                ProfileController.sharedInstance.loadSavedProfiles()
                NotificationCenter.default.post(name: .didChangePayloadLibrary, object: self, userInfo: nil)
            }
        }
    }

    @objc func restoreDefaultLibraryGroup(_ button: NSButton) {
        if let userApplicationSupport = URL(applicationDirectory: .applicationSupport) {
            let profileLibraryGroupURL = userApplicationSupport.appendingPathComponent("Groups", isDirectory: true)
            let profileLibraryGroupPathCurrent = UserDefaults.standard.string(forKey: PreferenceKey.profileLibraryGroupPath)

            guard profileLibraryGroupURL.path != profileLibraryGroupPathCurrent else { return }

            UserDefaults.standard.setValue(profileLibraryGroupURL.path, forKey: PreferenceKey.profileLibraryGroupPath)
            if let window = button.window, let oldPath = profileLibraryGroupPathCurrent, !self.shouldMoveProfileGroups(fromPath: oldPath, window: window) {
                NotificationCenter.default.post(name: .didChangePayloadLibraryGroup, object: self, userInfo: nil)
            }
        }
    }

    @objc func chooseLibraryGroupPath(_ button: NSButton) {

        let currentProfileLibraryGroupPath = UserDefaults.standard.string(forKey: PreferenceKey.profileLibraryGroupPath)

        // ---------------------------------------------------------------------
        //  Setup open dialog
        // ---------------------------------------------------------------------
        let openPanel = NSOpenPanel()
        openPanel.prompt = NSLocalizedString("Select Folder", comment: "")
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false

        if let window = button.window {
            openPanel.beginSheetModal(for: window) { response in
                if response == .OK, let url = openPanel.urls.first {
                    Log.shared.info(message: "Updating profile library group path to: \(url.path)", category: String(describing: self))
                    UserDefaults.standard.setValue(url.path, forKey: PreferenceKey.profileLibraryGroupPath)
                    if let oldPath = currentProfileLibraryGroupPath {
                        if !self.shouldMoveProfileGroups(fromPath: oldPath, window: window) {
                            NotificationCenter.default.post(name: .didChangePayloadLibraryGroup, object: self, userInfo: nil)
                        }
                    }
                } else {
                    NotificationCenter.default.post(name: .didChangePayloadLibraryGroup, object: self, userInfo: nil)
                }
            }
        }

    }

    @objc func chooseLibraryPath(_ button: NSButton) {

        let currentProfileLibraryPath = UserDefaults.standard.string(forKey: PreferenceKey.profileLibraryPath)

        // ---------------------------------------------------------------------
        //  Setup open dialog
        // ---------------------------------------------------------------------
        let openPanel = NSOpenPanel()
        openPanel.prompt = NSLocalizedString("Select Folder", comment: "")
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false

        if let window = button.window {
            openPanel.beginSheetModal(for: window) { response in
                if response == .OK, let url = openPanel.urls.first {
                    Log.shared.info(message: "Updating profile library path to: \(url.path)", category: String(describing: self))
                    UserDefaults.standard.setValue(url.path, forKey: PreferenceKey.profileLibraryPath)
                    if let oldPath = currentProfileLibraryPath {
                        if !self.shouldMoveProfiles(fromPath: oldPath, window: window) {
                            ProfileController.sharedInstance.loadSavedProfiles()
                            NotificationCenter.default.post(name: .didChangePayloadLibrary, object: self, userInfo: nil)
                        }
                    }
                } else {
                    ProfileController.sharedInstance.loadSavedProfiles()
                    NotificationCenter.default.post(name: .didChangePayloadLibrary, object: self, userInfo: nil)
                }
            }
        }
    }

    func shouldMoveProfileGroups(fromPath: String, window: NSWindow) -> Bool {

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fromPath, isDirectory: &isDirectory), isDirectory.boolValue else {
            Log.shared.error(message: "Old library group path did not exist at: \(fromPath)", category: String(describing: self))
            return false
        }

        let profileLibraryGroupURL = URL(fileURLWithPath: fromPath)
        var profileGroupURLs = [URL]()

        // ---------------------------------------------------------------------
        //  Put all items from current profile group directory into an array
        // ---------------------------------------------------------------------
        if let enumerator = FileManager.default.enumerator(at: profileLibraryGroupURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: { url, error -> Bool in
            Log.shared.error(message: "Directory enumeration error at: \(url), \(error)", category: String(describing: self))
            return true
        }), let currentProfileGroupURLs = enumerator.allObjects as? [URL] {
            profileGroupURLs = currentProfileGroupURLs
        }

        // ---------------------------------------------------------------------
        //  Remove all items that doesn't have the FileExtension.group extension
        // ---------------------------------------------------------------------
        profileGroupURLs = profileGroupURLs.filter { $0.pathExtension == FileExtension.group }

        if profileGroupURLs.isEmpty {
            Log.shared.info(message: "No profile groups were stored in the old library path", category: String(describing: self))
            return false
        }

        guard let profileGroupDirectoryURL = URL(applicationDirectory: .groupLibrary) else {
            Log.shared.error(message: "No profile library group directory was found", category: String(describing: self))
            return false
        }

        let alert = Alert()
        alert.showAlert(message: NSLocalizedString("Move existing groups?", comment: ""),
                        informativeText: NSLocalizedString("You have \(profileGroupURLs.count) groups at your old library path.\n\nDo you want to move or copy them to the new library path?", comment: ""),
                        window: window,
                        firstButtonTitle: NSLocalizedString("Don't Move", comment: ""),
                        secondButtonTitle: ButtonTitle.move,
                        thirdButtonTitle: ButtonTitle.copy,
                        firstButtonState: true,
                        sender: nil) { response in
                            switch response {
                            case .alertFirstButtonReturn:
                                NotificationCenter.default.post(name: .didChangePayloadLibraryGroup, object: self, userInfo: nil)
                            case .alertSecondButtonReturn:
                                self.moveProfileGroups(profileGroupURLs, toURL: profileGroupDirectoryURL)
                            case .alertThirdButtonReturn:
                                self.copyProfileGroups(profileGroupURLs, toURL: profileGroupDirectoryURL)
                            default:
                                Log.shared.error(message: "Unhandled response", category: String(describing: self))
                            }
        }

        return true

    }

    func moveProfileGroups(_ groups: [URL], toURL: URL) {
        for group in groups {
            Log.shared.info(message: "Moving profile group: \(group) to new library at: \(toURL.appendingPathComponent(group.lastPathComponent))", category: String(describing: self))
            do {
                try FileManager.default.createDirectoryIfNotExists(at: toURL, withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: group, to: toURL.appendingPathComponent(group.lastPathComponent))
            } catch {
                Log.shared.error(message: "Failed to move profile group from: \(group) to: \(toURL)", category: String(describing: self))
            }
        }
        NotificationCenter.default.post(name: .didChangePayloadLibraryGroup, object: self, userInfo: nil)
    }

    func copyProfileGroups(_ groups: [URL], toURL: URL) {
        for group in groups {
            Log.shared.info(message: "Copying profile group: \(group) to new library at: \(toURL.appendingPathComponent(group.lastPathComponent))", category: String(describing: self))
            do {
                try FileManager.default.createDirectoryIfNotExists(at: toURL, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: group, to: toURL.appendingPathComponent(group.lastPathComponent))
            } catch {
                Log.shared.error(message: "Failed to copy profile group from: \(group) to: \(toURL)", category: String(describing: self))
            }
        }
        NotificationCenter.default.post(name: .didChangePayloadLibraryGroup, object: self, userInfo: nil)
    }

    func shouldMoveProfiles(fromPath: String, window: NSWindow) -> Bool {

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fromPath, isDirectory: &isDirectory), isDirectory.boolValue else {
            Log.shared.error(message: "Old library path did not exist at: \(fromPath)", category: String(describing: self))
            return false
        }

        let profileLibraryURL = URL(fileURLWithPath: fromPath)
        var profileURLs = [URL]()

        // ---------------------------------------------------------------------
        //  Put all items from default profile save directory into an array
        // ---------------------------------------------------------------------
        do {
            profileURLs = try FileManager.default.contentsOfDirectory(at: profileLibraryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        } catch {
            Log.shared.error(message: "Failed to get the contents of the profile save folder at: \(fromPath) with error: \(error.localizedDescription)", category: String(describing: self))
            return false
        }

        // ---------------------------------------------------------------------
        //  Remove all items that doesn't have the FileExtension.profile extension
        // ---------------------------------------------------------------------
        profileURLs = profileURLs.filter { $0.pathExtension == FileExtension.profile }

        if profileURLs.isEmpty {
            Log.shared.info(message: "No profiles were stored in the old library path", category: String(describing: self))
            return false
        }

        guard let profileDirectoryURL = URL(applicationDirectory: .profiles) else {
            Log.shared.error(message: "No profile library directory was found", category: String(describing: self))
            return false
        }

        let alert = Alert()
        alert.showAlert(message: NSLocalizedString("Move existing profiles?", comment: ""),
                        informativeText: NSLocalizedString("You have \(profileURLs.count) profiles at your old library path.\n\nDo you want to move or copy them to the new library path?", comment: ""),
                        window: window,
                        firstButtonTitle: NSLocalizedString("Don't Move", comment: ""),
                        secondButtonTitle: ButtonTitle.move,
                        thirdButtonTitle: ButtonTitle.copy,
                        firstButtonState: true,
                        sender: nil) { response in
                            switch response {
                            case .alertFirstButtonReturn:
                                ProfileController.sharedInstance.loadSavedProfiles()
                                NotificationCenter.default.post(name: .didChangePayloadLibrary, object: self, userInfo: nil)
                            case .alertSecondButtonReturn:
                                self.moveProfiles(profileURLs, toURL: profileDirectoryURL)
                            case .alertThirdButtonReturn:
                                self.copyProfiles(profileURLs, toURL: profileDirectoryURL)
                            default:
                                Log.shared.error(message: "Unhandled response", category: String(describing: self))
                            }
        }

        return true
    }

    func moveProfiles(_ profiles: [URL], toURL: URL) {
        for profile in profiles {
            Log.shared.info(message: "Moving profile: \(profile) to new library at: \(toURL.appendingPathComponent(profile.lastPathComponent))", category: String(describing: self))
            do {
                try FileManager.default.moveItem(at: profile, to: toURL.appendingPathComponent(profile.lastPathComponent))
            } catch {
                Log.shared.error(message: "Failed to move profile from: \(profile) to: \(toURL)", category: String(describing: self))
            }
        }
        ProfileController.sharedInstance.loadSavedProfiles()
        NotificationCenter.default.post(name: .didChangePayloadLibrary, object: self, userInfo: nil)
    }

    func copyProfiles(_ profiles: [URL], toURL: URL) {
        for profile in profiles {
            Log.shared.info(message: "Copying profile: \(profile) to new library at: \(toURL.appendingPathComponent(profile.lastPathComponent))", category: String(describing: self))
            do {
                try FileManager.default.copyItem(at: profile, to: toURL.appendingPathComponent(profile.lastPathComponent))
            } catch {
                Log.shared.error(message: "Failed to copy profile from: \(profile) to: \(toURL)", category: String(describing: self))
            }
        }
        ProfileController.sharedInstance.loadSavedProfiles()
        NotificationCenter.default.post(name: .didChangePayloadLibrary, object: self, userInfo: nil)
    }
}
