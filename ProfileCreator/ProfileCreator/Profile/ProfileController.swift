//
//  ProfileController.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class ProfileController: NSDocumentController {

    // MARK: -
    // MARK: Static Variables

    public static let sharedInstance = ProfileController()

    // MARK: -
    // MARK: Variables

    var profiles = Set<Profile>()
    var profileLoadErrorCount: Int = 0

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init() {
        super.init()

        // ---------------------------------------------------------------------
        //  Load all saved profiles from disk
        // ---------------------------------------------------------------------
        self.loadSavedProfiles()

        // ---------------------------------------------------------------------
        //  Setup Notification Observers
        // ---------------------------------------------------------------------
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose(_:)), name: NSWindow.willCloseNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newDocument(_:)), name: .newProfile, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .newProfile, object: nil)
    }

    // MARK: -
    // MARK: Notification Functions

    @objc func windowWillClose(_ notification: Notification?) {

        // ---------------------------------------------------------------------
        //  If window was a ProfileEditor window, update the associated profile
        // ---------------------------------------------------------------------
        if
            let window = notification?.object as? NSWindow,
            let windowController = window.windowController as? ProfileEditorWindowController {

            // -----------------------------------------------------------------
            //  Get profile associated with the editor
            // -----------------------------------------------------------------
            guard let profile = windowController.document as? Profile else {
                Log.shared.error(message: "Failed to get the profile associated with the window being closed")
                return
            }

            // -----------------------------------------------------------------
            //  Remove the window controller from the profile
            // -----------------------------------------------------------------
            profile.removeWindowController(windowController)

            // -----------------------------------------------------------------
            //  If no URL is associated, it has never been saved
            // -----------------------------------------------------------------
            if profile.fileURL != nil {
                profile.settings.restoreSettingsSaved(nil)
            } else {
                let identifier = profile.identifier
                do {
                    if try self.removeProfile(withIdentifier: identifier) {

                        // ---------------------------------------------------------
                        //  If removed successfully, post a didRemoveProfiles notification
                        // ---------------------------------------------------------
                        NotificationCenter.default.post(name: .didRemoveProfiles, object: self, userInfo: [NotificationKey.identifiers: [ identifier ],
                                                                                                           NotificationKey.indexSet: IndexSet()])
                    }
                } catch {
                    Log.shared.error(message: "Failed to remove unsaved profile with identifier: \(identifier) with error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: -
    // MARK: NSDocumentController Functions

    override func newDocument(_ sender: Any?) {
        Log.shared.log(message: "Creating new empty profile")

        do {

            // -------------------------------------------------------------
            //  Try to create a new empty Profile document
            // -------------------------------------------------------------
            if let profile = try self.openUntitledDocumentAndDisplay(true) as? Profile {

                self.profiles.insert(profile)

                // -------------------------------------------------------------
                //  Post notification that a profile was added
                // -------------------------------------------------------------
                NotificationCenter.default.post(name: .didAddProfile, object: self, userInfo: [NotificationKey.identifier: profile.identifier])
            }
        } catch {
            Log.shared.error(message: "Failed to create a new empty profile with error: \(error.localizedDescription)")
        }
    }

    override func openDocument(withContentsOf url: URL, display displayDocument: Bool, completionHandler: @escaping (NSDocument?, Bool, Error?) -> Void) {
        Log.shared.debug(message: "Open document with contents of URL: \(url), displayDocument: \(displayDocument)", category: String(describing: self))

        let fileUTI = url.typeIdentifier

        if NSWorkspace.shared.type(fileUTI, conformsToType: kUTTypeMobileconfig) {
            ProfileImport.shared.importMobileconfigs(atURLs: [url]) { identifiers in
                guard let profileIdentifier = identifiers.first, let profile = ProfileController.sharedInstance.profile(withIdentifier: profileIdentifier) else {
                    completionHandler(nil, false, nil)
                    return
                }
                completionHandler(profile, true, nil)
            }
            /*
             do {
             let data = try Data(contentsOf: url)
             let decodedData = try ProfileSigning.decode(data: data)
             
             guard let mobileconfig = try PropertyListSerialization.propertyList(from: decodedData, format: nil) as? [String: Any] else {
             completionHandler(nil, false, nil)
             return
             }
             
             
             
             if
             let profileUUIDString = mobileconfig[PayloadKey.payloadUUID] as? String,
             let profileUUID = UUID(uuidString: profileUUIDString),
             let profile = ProfileController.sharedInstance.profile(withIdentifier: profileUUID) {
             completionHandler(profile, true, nil)
             }
             
             ProfileImport
             
             guard let profile = try Profile(withMobileconfig: mobileconfig) else {
             Log.shared.error(message: "Failed to create a profile from the mobileconfig: \(mobileconfig)", category: String(describing: self))
             completionHandler(nil, false, nil)
             return
             }
             
             
             if !profile.settings.importErrors.isEmpty {
             completionHandler(nil, false, nil)
             return
             }
             
             // -------------------------------------------------------------
             //  Save the profile to disk
             // -------------------------------------------------------------
             profile.save(self)
             
             // -------------------------------------------------------------
             //  Add the profile to the list of profiles
             // -------------------------------------------------------------
             self.profiles.insert(profile)
             
             // -------------------------------------------------------------
             //  Post notification that a profile was added
             // -------------------------------------------------------------
             NotificationCenter.default.post(name: .didAddProfile, object: self, userInfo: [NotificationKey.identifier: profile.identifier])
             
             // -------------------------------------------------------------
             //  Return the new document
             // -------------------------------------------------------------
             completionHandler(profile, false, nil)
             } catch {
             Log.shared.error(message: "Import failed with error: \(error)", category: String(describing: self))
             }
             */
        } else if NSWorkspace.shared.type(fileUTI, conformsToType: kUTTypeProfileConfiguration) {
            Log.shared.info(message: "Importing pfcconf files is not implemented yet.", category: String(describing: self))
            /* FIXME: Currently not set up to recieve our own save files... must fix this.
             do {
             
             // -------------------------------------------------------------
             //  Create the profile from the file at profileURL
             // -------------------------------------------------------------
             let document = try self.makeDocument(withContentsOf: url, ofType: TypeName.profile)
             
             // -------------------------------------------------------------
             //  Check that no other profile exist with the same identifier
             //  This means that only the first profile created with that identifier will exist
             // -------------------------------------------------------------
             guard let profile = document as? Profile, !self.profiles.contains(where: { $0.identifier == profile.identifier }) else {
             Log.shared.error(message: "A profile with identifier: \(String(describing: (document as? Profile)?.identifier)) was already imported. This and subsequent profiles with the same identifier will be ignored.", category: String(describing: self))
             completionHandler(nil, true, nil)
             return
             }
             self.profiles.insert(profile)
             
             // -------------------------------------------------------------
             //  Post notification that a profile was added
             // -------------------------------------------------------------
             NotificationCenter.default.post(name: .didAddProfile, object: self, userInfo: [NotificationKey.identifier: profile.identifier])
             
             completionHandler(profile, false, nil)
             } catch {
             Log.shared.error(message: "Failed to load a profile from the file at: \(url.path) with error: \(error.localizedDescription)", category: String(describing: self))
             completionHandler(nil, false, nil)
             }
             */
        }

    }

    override func reopenDocument(for urlOrNil: URL?, withContentsOf contentsURL: URL, display displayDocument: Bool, completionHandler: @escaping (NSDocument?, Bool, Error?) -> Void) {
        // FIXME: This is here for testing when it's called.
        Log.shared.debug(message: "Reopen document for: \(String(describing: urlOrNil)) withContentsOf: \(contentsURL)", category: String(describing: self))
        super.reopenDocument(for: urlOrNil, withContentsOf: contentsURL, display: displayDocument, completionHandler: completionHandler)
    }

    // MARK: -
    // MARK: Load Profiles

    func loadSavedProfiles() {
        Log.shared.log(message: "Loading saved profiles…", category: String(describing: self))

        // ---------------------------------------------------------------------
        //  Reset existing profiles
        // ---------------------------------------------------------------------
        // FIXME: This might be weird if profiles are open. Might need to check and prompt to close them before
        self.profiles = Set<Profile>()

        // ---------------------------------------------------------------------
        //  Get path to default profile save directory
        // ---------------------------------------------------------------------
        guard let profileDirectoryURL = URL(applicationDirectory: .profiles) else {
            Log.shared.error(message: "No default profile save folder was found", category: String(describing: self))
            return
        }

        var profileURLs = [URL]()

        // ---------------------------------------------------------------------
        //  Put all items from default profile save directory into an array
        // ---------------------------------------------------------------------
        do {
            profileURLs = try FileManager.default.contentsOfDirectory(at: profileDirectoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        } catch {
            Log.shared.error(message: "Failed to get the contents of the default profile save folder with error: \(error.localizedDescription)", category: String(describing: self))
            return
        }

        // ---------------------------------------------------------------------
        //  Remove all items that doesn't have the FileExtension.profile extension
        // ---------------------------------------------------------------------
        profileURLs = profileURLs.filter { $0.pathExtension == FileExtension.profile }

        self.profileLoadErrorCount = 0

        // ---------------------------------------------------------------------
        //  Loop through all profile files, try to create a Profile instance and add them to the profiles set
        // ---------------------------------------------------------------------
        for profileURL in profileURLs {
            do {

                // -------------------------------------------------------------
                //  Create the profile from the file at profileURL
                // -------------------------------------------------------------
                let document = try self.makeDocument(withContentsOf: profileURL, ofType: TypeName.profile)

                // -------------------------------------------------------------
                //  Check that no other profile exist with the same identifier
                //  This means that only the first profile created with that identifier will exist
                // -------------------------------------------------------------
                guard let profile = document as? Profile, !self.profiles.contains(where: { $0.identifier == profile.identifier }) else {
                    Log.shared.error(message: "A profile with identifier: \(String(describing: (document as? Profile)?.identifier)) was already imported. This and subsequent profiles with the same identifier will be ignored.", category: String(describing: self))
                    return
                }
                self.profiles.insert(profile)

                // -------------------------------------------------------------
                //  Post notification that a profile was added
                // -------------------------------------------------------------
                NotificationCenter.default.post(name: .didAddProfile, object: self, userInfo: [NotificationKey.identifier: profile.identifier])
            } catch {
                self.profileLoadErrorCount += 1
                Log.shared.error(message: "Failed to load a profile from the file at: \(profileURL.path) with error: \(error.localizedDescription)", category: String(describing: self))
            }
        }
    }

    // MARK: -
    // MARK: Get Profiles

    public func profile(withIdentifier identifier: UUID) -> Profile? {
        return self.profiles.first { $0.identifier == identifier }
    }

    public func profiles(withIdentifiers identifiers: [UUID]) -> [Profile]? {
        return self.profiles.filter { identifiers.contains($0.identifier) }
    }

    public func profileIdentifiers() -> [UUID]? {
        return self.profiles.map { $0.identifier }
    }

    public func titleOfProfile(withIdentifier identifier: UUID) -> String? {
        if let profile = self.profile(withIdentifier: identifier) {
            return profile.settings.title
        } else { Log.shared.error(message: "Found no profile with identifier: \(identifier)", category: String(describing: self)) }
        return nil
    }

    // MARK: -
    // MARK: Edit Profiles

    public func editProfile(withIdentifier identifier: UUID) {
        Log.shared.info(message: "Edit profile with identifier: \(identifier)", category: String(describing: self))

        if let profile = self.profile(withIdentifier: identifier) {
            if profile.versionFormatSupported {
                profile.edit()
            } else {
                Log.shared.error(message: "The format of the save file is not supported", category: String(describing: self))
            }
        } else { Log.shared.error(message: "Found no profile with identifier: \(identifier)", category: String(describing: self)) }
    }

    // MARK: -
    // MARK: Duplicate Profiles

    public func duplicateProfile(withIdentifier identifier: UUID, promptWindow: NSWindow?) {
        Log.shared.info(message: "Duplicate profile with identifier: \(identifier)", category: String(describing: self))

        if let profile = self.profile(withIdentifier: identifier) {
            if profile.versionFormatSupported {

                // ---------------------------------------------------------------------
                //  Show title panel to let user select new title
                // ---------------------------------------------------------------------

                let profileTitle = profile.settings.title.replacingOccurrences(of: "-[0-9]+$", with: "", options: .regularExpression, range: nil)
                var newTitle = profileTitle
                for index in 1...40 {
                    if self.profiles.contains(where: { $0.settings.title == newTitle }) {
                        newTitle = profileTitle.deletingSuffix("-\(index - 1)") + "-\(index)"
                    } else {
                        break
                    }
                }
                guard let newProfile = profile.copy(withTitle: newTitle) as? Profile else { return }

                // -------------------------------------------------------------
                //  Add the profile to the list of profiles
                // -------------------------------------------------------------
                self.profiles.insert(newProfile)

                // -------------------------------------------------------------
                //  Post notification that a profile was added
                // -------------------------------------------------------------
                NotificationCenter.default.post(name: .didAddProfile, object: self, userInfo: [NotificationKey.identifier: newProfile.identifier])
            } else {
                Log.shared.error(message: "The format of the save file is not supported", category: String(describing: self))
            }
        } else { Log.shared.error(message: "Found no profile with identifier: \(identifier)", category: String(describing: self)) }
    }

    // MARK: -
    // MARK: Export Plists

    public func exportPlist(profile: Profile, promptWindow: NSWindow?) {
        Log.shared.log(message: "Export profile with identifier: \(profile.identifier) as plist", category: String(describing: self))

        // ---------------------------------------------------------------------
        //  Get a reference to the main window to attach dialogs to
        // ---------------------------------------------------------------------
        let window: NSWindow
        if let pWindow = promptWindow {
            window = pWindow
        } else if
            let appDelegate = NSApplication.shared.delegate as? AppDelegate,
            let mainWindow = appDelegate.mainWindowController.window {
            window = mainWindow
        } else {
            return
        }

        // ---------------------------------------------------------------------
        //  Verify atleast one payload is enabled
        // ---------------------------------------------------------------------
        if profile.enabledPayloadsCount == 0 {
            Log.shared.error(message: "No payloads were selected in profile with identifier: \(profile.identifier)", category: String(describing: self))
            self.showAlertNoPayloadSelected(inProfile: profile, window: window)
            return
        }

        // ---------------------------------------------------------------------
        //  Instantiate the export accessory view to use
        // ---------------------------------------------------------------------
        guard let exportSettings = profile.settings.copy() as? ProfileSettings else {
            Log.shared.error(message: "Failed to copy profile settings", category: String(describing: self))
            return
        }

        // ---------------------------------------------------------------------
        //  Show open panel to let user select save path
        // ---------------------------------------------------------------------
        let openPanel = NSOpenPanel()
        openPanel.accessoryView = ProfileExportPlistAccessoryView(profile: profile, exportSettings: exportSettings)
        openPanel.prompt = NSLocalizedString("Select Folder", comment: "")
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.isAccessoryViewDisclosed = true
        openPanel.prompt = ButtonTitle.export

        openPanel.beginSheetModal(for: window) { response in
            if response != .OK { return }
            if let folderURL = openPanel.url {
                do {
                    try ProfileExport(exportSettings: exportSettings).exportPlist(profile: profile, folderURL: folderURL)
                } catch {
                    Log.shared.error(message: "Failed to export profile with identifier: \(profile.identifier) to path: \(folderURL.path) with error: \(error.localizedDescription)", category: String(describing: self))
                    self.showAlertExport(error: error, window: window)
                }
            } else { Log.shared.error(message: "Failed to get the selected save path from the save panel for profile with identifier: \(profile.identifier)", category: String(describing: self)) }
        }
    }

    public func exportPlist(withIdentifier identifier: UUID, promptWindow: NSWindow?) {
        if let profile = self.profile(withIdentifier: identifier) {
            self.exportPlist(profile: profile, promptWindow: promptWindow)
        } else { Log.shared.error(message: "Found no profile with identifier: \(identifier)", category: String(describing: self)) }
    }

    public func exportPlists(withIdentifiers identifiers: [UUID], promptWindow: NSWindow?) {
        if let profiles = self.profiles(withIdentifiers: identifiers) {
            for profile in profiles {
                self.exportPlist(profile: profile, promptWindow: promptWindow)
            }
        } else { Log.shared.error(message: "Found no profiles with identifiers: \(identifiers)", category: String(describing: self)) }
    }

    // MARK: -
    // MARK: Export Profiles

    public func export(profile: Profile, promptWindow: NSWindow?) {
        Log.shared.log(message: "Export profile with identifier: \(profile.identifier)", category: String(describing: self))

        // ---------------------------------------------------------------------
        //  Get a reference to the main window to attach dialogs to
        // ---------------------------------------------------------------------
        let window: NSWindow
        if let pWindow = promptWindow {
            window = pWindow
        } else if
            let appDelegate = NSApplication.shared.delegate as? AppDelegate,
            let mainWindow = appDelegate.mainWindowController.window {
            window = mainWindow
        } else {
            return
        }

        // ---------------------------------------------------------------------
        //  Verify atleast one payload is enabled
        // ---------------------------------------------------------------------
        if profile.enabledPayloadsCount == 0 {
            Log.shared.error(message: "No payloads were selected in profile with identifier: \(profile.identifier)", category: String(describing: self))
            self.showAlertNoPayloadSelected(inProfile: profile, window: window)
            return
        }

        // ---------------------------------------------------------------------
        //  Instantiate the export accessory view to use
        // ---------------------------------------------------------------------
        guard let exportSettings = profile.settings.copy() as? ProfileSettings else {
            Log.shared.error(message: "Failed to copy profile settings", category: String(describing: self))
            return
        }
        let accessoryView = ProfileExportAccessoryView(profile: profile, exportSettings: exportSettings)

        // ---------------------------------------------------------------------
        //  Show save panel to let user select save path
        // ---------------------------------------------------------------------
        let savePanel = NSSavePanel()
        savePanel.delegate = accessoryView
        savePanel.allowedFileTypes = [kUTTypeMobileconfig]
        savePanel.accessoryView = accessoryView
        savePanel.nameFieldStringValue = exportSettings.title
        savePanel.beginSheetModal(for: window) { response in
            if response != .OK { return }
            if let profileURL = savePanel.url {
                let settings: [String: Any] = [
                    "profile": profile,
                    "settings": exportSettings,
                    "profileURL": profileURL,
                    "window": window
                ]

                self.perform(#selector(self.performExport(settings:)), on: Thread.main, with: settings, waitUntilDone: false)
            } else { Log.shared.error(message: "Failed to get the selected save path from the save panel for profile with identifier: \(profile.identifier)", category: String(describing: self)) }
        }
    }

    @objc private func performExport(settings: [String: Any]) {
        let profile = settings["profile"] as! Profile
        let exportSettings = settings["settings"] as! ProfileSettings
        let profileURL = settings["profileURL"] as! URL
        let window = settings["window"] as! NSWindow

        do {
            try ProfileExport(exportSettings: exportSettings).export(profile: profile, profileURL: profileURL)
        } catch {
            Log.shared.error(message: "Failed to export profile with identifier: \(profile.identifier) to path: \(profileURL.path) with error: \(error.localizedDescription)", category: String(describing: self))
            self.showAlertExport(error: error, window: window)
        }
    }

    public func exportProfile(withIdentifier identifier: UUID, promptWindow: NSWindow?) {
        if let profile = self.profile(withIdentifier: identifier) {
            self.export(profile: profile, promptWindow: promptWindow)
        } else { Log.shared.error(message: "Found no profile with identifier: \(identifier)", category: String(describing: self)) }
    }

    public func exportProfiles(withIdentifiers identifiers: [UUID], promptWindow: NSWindow?) {
        if let profiles = self.profiles(withIdentifiers: identifiers) {
            for profile in profiles {
                self.export(profile: profile, promptWindow: promptWindow)
            }
        } else { Log.shared.error(message: "Found no profiles with identifiers: \(identifiers)", category: String(describing: self)) }
    }

    public func showAlertNoPayloadSelected(inProfile profile: Profile, window: NSWindow) {
        let alert = Alert()
        let alertMessage = NSLocalizedString("No Payloads are included in \"\(profile.settings.title)\".", comment: "")
        let alertInformativeText = NSLocalizedString("Please include at least one (1) payload in the profile.", comment: "")

        alert.showAlert(message: alertMessage,
                        informativeText: alertInformativeText,
                        window: window,
                        firstButtonTitle: ButtonTitle.ok,
                        secondButtonTitle: nil,
                        thirdButtonTitle: nil,
                        firstButtonState: true,
                        sender: nil) { _ in }
    }

    public func showAlertExport(error: Error, window: NSWindow) {
        guard let exportError = error as? ProfileExportError else { return }
        let alert = Alert()

        var message: String
        var informativeString: String?

        switch exportError {
        case let .saveError(path):
            message = NSLocalizedString("Failed to write the mobileconfig at the selected path.", comment: "")
            informativeString = path
        case .signingErrorNoIdentity:
            message = NSLocalizedString("Failed to get the selected signing certificate from settings.", comment: "")
            informativeString = NSLocalizedString("Try deselecting and selecting the certificate in the signing certificate popup button.", comment: "")
        case .signingErrorGetIdentity:
            message = NSLocalizedString("Failed to get the selected signing certificate from the user keycain.", comment: "")
            informativeString = NSLocalizedString("Verify the ACL of the private key of the selected certificate in \"Keychain Access.app\". Toggle the ACL setting and save to update the private key ACL.", comment: "")
        case let .signingErrorFailed(certificate, error):
            message = NSLocalizedString("Failed to sign the profile using certificate: ", comment: "") + certificate
            informativeString = NSLocalizedString("\(error)\n\nVerify the ACL of the private key of the selected certificate in \"Keychain Access.app\". Toggle the ACL setting and save to refresh update the private key access.", comment: "")
        case let .noPayload(domain, payloadType):
            message = NSLocalizedString("Unknown payload domain: \(domain) of type: \(payloadType)", comment: "")
            informativeString = NSLocalizedString("Try to configure a new profile without copying or importing any settings.", comment: "")
        case let .settingsErrorEmptyDomain(domain, payloadType):
            message = NSLocalizedString("Found no settings for payload domain: \(domain) of type: \(payloadType)", comment: "")
            informativeString = NSLocalizedString("Try to configure a new profile without copying or importing any settings.", comment: "")
        case let .settingsErrorEmptyKey(key, domain, payloadType):
            message = NSLocalizedString("Found no settings for key: \(key) in payload domain: \(domain) of type: \(payloadType)", comment: "")
            informativeString = NSLocalizedString("Try re-entering the value for the key.", comment: "")
        case let .settingsErrorInvalid(value, key, domain, payloadType):
            message = NSLocalizedString("Invalid value for key: \(key) in payload domain: \(domain) of type: \(payloadType)", comment: "")
            informativeString = NSLocalizedString("Value: \(value ?? "nil")\n\nVerify you have entered a correct value.", comment: "")
        case let .configurationErrorInvalid(key, domain, payloadType):
            message = NSLocalizedString("The payload manifest contains a configuration error.", comment: "")
            informativeString = NSLocalizedString("Key: \(key)\nDomain: \(domain)\nType: \(payloadType)", comment: "")
        default:
            message = exportError.localizedDescription
        }

        alert.showAlert(message: message,
                        informativeText: informativeString,
                        window: window,
                        firstButtonTitle: ButtonTitle.ok,
                        secondButtonTitle: nil,
                        thirdButtonTitle: nil,
                        firstButtonState: true,
                        sender: nil) { _ in }
    }

    // MARK: -
    // MARK: Remove Profiles

    public func removeProfile(withIdentifier identifier: UUID) throws -> Bool {
        Log.shared.log(message: "Removing profile with identifier: \(identifier)", category: String(describing: self))

        if let profile = self.profile(withIdentifier: identifier) {

            // -----------------------------------------------------------------
            //  Try to get the URL, if it doesn't have a URL, it should not be saved on disk
            // -----------------------------------------------------------------
            guard let url = profile.fileURL, FileManager.default.fileExists(atPath: url.path) else {
                self.profiles.remove(profile)
                return true
            }

            // -----------------------------------------------------------------
            //  Try to remove item at url
            // -----------------------------------------------------------------
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            self.profiles.remove(profile)
            return true
        } else {
            Log.shared.error(message: "Found no profile with identifier: \(identifier)", category: String(describing: self))
        }
        return false
    }

    public func removeProfiles(atIndexes indexes: IndexSet, withIdentifiers identifiers: [UUID]) {
        #if DEBUG
        Log.shared.debug(message: "Removing profiles at indexes: \(indexes) with identifiers: \(identifiers)", category: String(describing: self))
        #endif

        var removedIdentifiers = [UUID]()

        // ---------------------------------------------------------------------
        //  Loop through all passed identifiers and try to remove them individually
        // ---------------------------------------------------------------------
        for identifier in identifiers {
            do {
                if try self.removeProfile(withIdentifier: identifier) {

                    // -------------------------------------------------------------
                    //  If removed successfully, add to removedIdentifiers
                    // -------------------------------------------------------------
                    removedIdentifiers.append(identifier)
                }
            } catch {
                Log.shared.error(message: "Removing profile with identifier: \(identifier) failed with error: \(error.localizedDescription)", category: String(describing: self))
            }
        }

        // ---------------------------------------------------------------------
        //  Post all successfully removed profile identifiers as a didRemoveProfile notification
        // ---------------------------------------------------------------------
        if !removedIdentifiers.isEmpty {
            NotificationCenter.default.post(name: .didRemoveProfiles, object: self, userInfo: [NotificationKey.identifiers: removedIdentifiers,
                                                                                               NotificationKey.indexSet: indexes])
        }
    }
}
