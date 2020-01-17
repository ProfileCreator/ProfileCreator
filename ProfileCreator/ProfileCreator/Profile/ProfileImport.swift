//
//  ProfileImport.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

class ProfileImport {

    // ---------------------------------------------------------------------
    //  Variables
    // ---------------------------------------------------------------------
    static let shared = ProfileImport()

    // ---------------------------------------------------------------------
    //  Initialization
    // ---------------------------------------------------------------------
    private init() {}

    func importMobileconfigs(atURLs urls: [URL], completionHandler: @escaping ([UUID]) -> Void) {

        #if DEBUG
        Log.shared.debug(message: "Importing mobileconfigs from URLs: \(urls)", category: String(describing: self))
        #endif

        let dispatchQueue = DispatchQueue(label: "serial")
        let dispatchGroup = DispatchGroup()
        let dispatchSemaphore = DispatchSemaphore(value: 0)

        var profileIdentifiers = [UUID]()

        dispatchQueue.async {
            for url in urls {
                dispatchGroup.enter()
                self.importMobileconfig(atURL: url) { identifier in
                    if let profileIdentifier = identifier {
                        profileIdentifiers.append(profileIdentifier)
                    }
                    dispatchSemaphore.signal()
                    dispatchGroup.leave()
                }
                dispatchSemaphore.wait()
            }

            dispatchGroup.notify(queue: dispatchQueue) {
                DispatchQueue.main.async {
                    completionHandler(profileIdentifiers)
                }
            }
        }
    }

    func importMobileconfig(atURL url: URL, completionHandler: @escaping (UUID?) -> Void) {

        #if DEBUG
        Log.shared.debug(message: "Importing mobileconfig at URL: \(url)", category: String(describing: self))
        #endif

        do {
            let data = try Data(contentsOf: url)
            let decodedData = try ProfileSigning.decode(data: data)

            guard let mobileconfig = try PropertyListSerialization.propertyList(from: decodedData, format: nil) as? [String: Any] else {
                completionHandler(nil)
                return
            }

            if
                let profileUUIDString = mobileconfig[PayloadKey.payloadUUID] as? String,
                let profileUUID = UUID(uuidString: profileUUIDString),
                let profile = ProfileController.sharedInstance.profile(withIdentifier: profileUUID) {

                guard
                    let appDelegate = NSApplication.shared.delegate as? AppDelegate,
                    let mainWindow = appDelegate.mainWindowController.window else {
                        // FIXME: Correct Error
                        completionHandler(nil)
                        return
                }

                DispatchQueue.main.async {
                    let alert = Alert()
                    let alertMessage = NSLocalizedString("Overwrite Existing Profile?", comment: "")
                    let alertInformativeText = NSLocalizedString("A profile with the name: \"\(profile.settings.title)\" already exists with UUID:\n\n\(profile.settings.identifier)\n\nIf you import this profile all current settings will be overwritten with the imported profile.", comment: "")

                    alert.showAlert(message: alertMessage,
                                    informativeText: alertInformativeText,
                                    window: mainWindow,
                                    firstButtonTitle: ButtonTitle.importTitle,
                                    secondButtonTitle: ButtonTitle.cancel,
                                    thirdButtonTitle: nil,
                                    firstButtonState: true,
                                    sender: nil) { response in
                                        if response == .alertFirstButtonReturn {
                                            do {
                                                guard try ProfileController.sharedInstance.removeProfile(withIdentifier: profileUUID) else {
                                                    Log.shared.error(message: "Failed to remove profile with identifier: \(profileUUID)", category: String(describing: self))
                                                    completionHandler(nil)
                                                    return
                                                }
                                                try self.importMobileconfig(mobileconfig, completionHandler: completionHandler)
                                                return
                                            } catch {
                                                Log.shared.error(message: "Import failed with error: \(error)", category: String(describing: self))
                                                completionHandler(nil)
                                            }
                                        } else {
                                            completionHandler(nil)
                                        }
                    }
                }
            } else {
                try self.importMobileconfig(mobileconfig, completionHandler: completionHandler)
            }
        } catch {
            Log.shared.error(message: "Import failed with error: \(error)", category: String(describing: self))

            guard
                let appDelegate = NSApplication.shared.delegate as? AppDelegate,
                let mainWindow = appDelegate.mainWindowController.window else {
                    // FIXME: Correct Error
                    completionHandler(nil)
                    return
            }

            let alert = Alert()
            let alertMessage = NSLocalizedString("Error Importing Profile", comment: "")
            var alertInformativeText = error.localizedDescription
            if let debugDescription = (error as NSError).userInfo["NSDebugDescription"] as? String {
                alertInformativeText += "\n\n" + debugDescription
            }

            DispatchQueue.main.async {
                alert.showAlert(message: alertMessage,
                                informativeText: alertInformativeText,
                                window: mainWindow,
                                firstButtonTitle: ButtonTitle.ok,
                                secondButtonTitle: nil,
                                thirdButtonTitle: nil,
                                firstButtonState: true,
                                sender: nil) { _ in

                                    completionHandler(nil)
                }
            }
        }
    }

    func importMobileconfig(_ mobileconfig: [String: Any], completionHandler: @escaping (UUID?) -> Void) throws {
        guard let profile = try Profile(withMobileconfig: mobileconfig) else {
            Log.shared.error(message: "Failed to create a profile from the mobileconfig: \(mobileconfig)", category: String(describing: self))
            completionHandler(nil)
            return
        }

        if !profile.settings.importErrors.isEmpty {

            // -------------------------------------------------------------
            //  Show that there were some errors when importing the profile
            // -------------------------------------------------------------
            DispatchQueue.main.async {
                self.showImportError(forProfile: profile, completionHandler: completionHandler)
            }
        } else {

            // -------------------------------------------------------------
            //  Add the profile and return it's identifier
            // -------------------------------------------------------------
            DispatchQueue.main.async {
                self.addProfile(profile)
                completionHandler(profile.identifier)
            }
        }
    }

    func informativeText(forImportErrors importErrors: [String: Any], clipboardContent: inout String) -> String {
        var informativeText = ""
        for (key, value) in importErrors {
            switch key {
            case ImportErrorKey.payloadTypeCustom:
                if !informativeText.isEmpty {
                    informativeText += "\n\n"
                }
                informativeText += NSLocalizedString("Payloads currently unavailable in ProfileCreator:", comment: "") + "\n"
                if let valueArray = value as? [String] {
                    for payloadType in valueArray {
                        informativeText += "\n    • \(payloadType)"
                    }
                }
                informativeText += "\n\n" + NSLocalizedString("The contents of the unavailable payloads can still be viewed and exported but not edited by ProfileCreator.", comment: "")

            case ImportErrorKey.payloadTypeMissing:
                if !informativeText.isEmpty {
                    informativeText += "\n\n"
                }
                informativeText += NSLocalizedString("Missing PayloadType:", comment: "") + "\n"
                if let valueArray = value as? [String] {
                    for payloadName in valueArray {
                        informativeText += "\n    • \(payloadName)"
                    }
                }

            case ImportErrorKey.payloadKeyMissing:
                if !informativeText.isEmpty {
                    informativeText += "\n\n"
                }
                informativeText += NSLocalizedString("Payload Keys currently unavailable in ProfileCreator:", comment: "") + "\n"
                if let valueDict = value as? [String: [String]] {
                    for domain in valueDict.keys {
                        informativeText += "\n• \(domain)"
                        for keyPath in valueDict[domain] ?? [String]() {
                            informativeText += "\n  - \(keyPath)"
                        }
                    }
                }
                clipboardContent += informativeText
                informativeText += "\n\n" + NSLocalizedString("The unavailable payload keys will not be included in the export. Please open an issue on GitHub to get this key added to the payload.", comment: "")
            default:
                informativeText += "\n\n" + NSLocalizedString("Unknown Error", comment: "")
                Log.shared.error(message: "Unhandled ImportErrorKey: \(key), value: \(value)", category: String(describing: self))
            }
        }
        return informativeText
    }

    func addProfile(_ profile: Profile) {

        // -------------------------------------------------------------
        //  Save the profile to disk
        // -------------------------------------------------------------
        profile.save(self)

        // -------------------------------------------------------------
        //  Add the profile to the list of profiles
        // -------------------------------------------------------------
        ProfileController.sharedInstance.profiles.insert(profile)

        // -------------------------------------------------------------
        //  Post notification that a profile was added
        // -------------------------------------------------------------
        NotificationCenter.default.post(name: .didAddProfile, object: self, userInfo: [NotificationKey.identifier: profile.identifier])
    }

    func showImportError(forProfile profile: Profile, completionHandler: @escaping (UUID?) -> Void) {

        // -------------------------------------------------------------
        //  Get the main window
        // -------------------------------------------------------------
        guard
            let appDelegate = NSApplication.shared.delegate as? AppDelegate,
            let mainWindow = appDelegate.mainWindowController.window else {
                Log.shared.error(message: "Failed to get main window to display import error: \(profile.settings.importErrors)", category: String(describing: self))
                completionHandler(nil)
                return
        }

        // -------------------------------------------------------------
        //  Create the user alert
        // -------------------------------------------------------------
        var clipboardContent = ""
        let alert = Alert()
        let alertMessage = NSLocalizedString("Import Warning for \"\(profile.settings.title)\".", comment: "")
        let alertInformativeText = self.informativeText(forImportErrors: profile.settings.importErrors, clipboardContent: &clipboardContent)

        alert.showAlert(message: alertMessage,
                        informativeText: alertInformativeText,
                        window: mainWindow,
                        firstButtonTitle: ButtonTitle.importTitle,
                        secondButtonTitle: ButtonTitle.cancel,
                        thirdButtonTitle: clipboardContent.isEmpty ? nil : "Copy Error to Clipboard",
                        firstButtonState: true,
                        sender: nil) { response in
                            if response == .alertFirstButtonReturn {
                                self.addProfile(profile)
                                completionHandler(profile.identifier)
                            } else if response == .alertThirdButtonReturn {
                                let pasteboard = NSPasteboard.general
                                pasteboard.declareTypes([.string], owner: nil)
                                pasteboard.setString(clipboardContent, forType: .string)
                            } else {
                                completionHandler(nil)
                            }
        }
    }
}
