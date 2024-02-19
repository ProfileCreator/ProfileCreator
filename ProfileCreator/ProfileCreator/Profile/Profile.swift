//
//  Profile.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

public class Profile: NSDocument, NSCopying {

    // MARK: -
    // MARK: Constant Variables

    let settings: ProfileSettings

    // MARK: -
    // MARK: Variables

    var alert: Alert?

    // MARK: -
    // MARK: Computer Variables

    public var enabledPayloadsCount: Int {
        self.settings.payloadSettingsEnabledCount()
    }

    public var identifier: UUID {
        self.settings.identifier
    }

    public var versionFormatSupported: Bool {
        kSaveFormatVersionMin <= self.settings.formatVersion
    }

    // MARK: -
    // MARK: Initialization

    override init() {
        self.settings = ProfileSettings()

        super.init()

        // ---------------------------------------------------------------------
        //  Set reference to self in ProfileSettings
        // ---------------------------------------------------------------------
        self.settings.profile = self
    }

    init?(withMobileconfig mobileconfig: [String: Any]) throws {
        self.settings = try ProfileSettings(withMobileconfig: mobileconfig)

        super.init()

        self.settings.profile = self
    }

    init?(withSettings settings: [String: Any]) throws {
        self.settings = try ProfileSettings(withSettings: settings)

        super.init()

        self.settings.profile = self
    }

    public func copy(with zone: NSZone? = nil, withTitle title: String) -> Any {
        guard let newProfile = self.copy() as? Profile else { return Profile() }
        newProfile.fileURL = nil
        newProfile.settings.setValue(title, forValueKeyPath: PayloadKey.payloadDisplayName, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
        newProfile.settings.updateUUIDs()

        // -------------------------------------------------------------
        //  Save the profile to disk
        // -------------------------------------------------------------
        newProfile.save(self)

        return newProfile
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        do {
            guard let copy = try Profile(withSettings: self.settings.currentSettings()) else { return Profile() }
            return copy
        } catch {
            Log.shared.error(message: "Failed to copy profile with error: \(error)", category: String(describing: self))
            return Profile()
        }
    }

    func saveCheck(key: String, value: Any, newValue: Any?) {
        if
            let valueDict = value as? [String: Any],
            let newValueDict = newValue as? [String: Any] {
            if valueDict != newValueDict {
                Log.shared.debug(message: "The key: \(key) (Dictionary) has a new value")
                for (key, value) in valueDict {
                    self.saveCheck(key: key, value: value, newValue: newValueDict[key])
                }
                return
            }
        } else if
            let valueString = value as? String,
            let newValueString = newValue as? String {
            if valueString != newValueString {
                Log.shared.debug(message: "The key: \(key) (String) has a new value")
                Log.shared.debug(message: "The key: \(key) saved value: \(valueString)")
                Log.shared.debug(message: "The key: \(key) new value: \(newValueString)")
            }
            return
        } else if
            let valueInt = value as? Int,
            let newValueInt = newValue as? Int {
            if valueInt != newValueInt {
                Log.shared.debug(message: "The key: \(key) (Int) has a new value")
                Log.shared.debug(message: "The key: \(key) saved value: \(valueInt)")
                Log.shared.debug(message: "The key: \(key) new value: \(newValueInt)")
            }
            return
        } else if
            let valueBool = value as? Bool,
            let newValueBool = newValue as? Bool {
            if valueBool != newValueBool {
                Log.shared.debug(message: "The key: \(key) (Bool) has a new value")
                Log.shared.debug(message: "The key: \(key) saved value: \(valueBool)")
                Log.shared.debug(message: "The key: \(key) new value: \(newValueBool)")
            }
            return
        } else if
            let valueArray = value as? [Any],
            let newValueArray = newValue as? [Any] {
            Log.shared.debug(message: "The key: \(key) (Array) might have a new value. Currently arrays can't be compared")
            Log.shared.debug(message: "The key: \(key) saved value: \(valueArray)")
            Log.shared.debug(message: "The key: \(key) new value: \(newValueArray)")
            return
        } else if let valueFloat = value as? Float,
            let newValueFloat = newValue as? Float {
            if valueFloat != newValueFloat {
                Log.shared.debug(message: "The key: \(key) (Float) has a new value")
                Log.shared.debug(message: "The key: \(key) saved value: \(valueFloat)")
                Log.shared.debug(message: "The key: \(key) new value: \(newValueFloat)")
            }
            return
        } else if let valueDate = value as? Date,
            let newValueDate = newValue as? Date {
            if valueDate != newValueDate {
                Log.shared.debug(message: "The key: \(key) (Date) has a new value")
                Log.shared.debug(message: "The key: \(key) saved value: \(valueDate)")
                Log.shared.debug(message: "The key: \(key) new value: \(newValueDate)")
            }
            return
        } else if let valueData = value as? Data,
            let newValueData = newValue as? Data {
            if valueData != newValueData {
                Log.shared.debug(message: "The key: \(key) (Data) has a new value")
                Log.shared.debug(message: "The key: \(key) saved value: \(valueData)")
                Log.shared.debug(message: "The key: \(key) new value: \(newValueData)")
            }
            return
        }
    }

    // MARK: -

    func showAlertUnsaved(closeWindow: Bool) {

        guard
            let windowController = self.windowControllers.first as? ProfileEditorWindowController,
            let window = windowController.window else { Log.shared.error(message: "No window found for ProfileEditorWindowController", category: String(describing: self)); return }

        let alert = Alert()
        self.alert = alert

        let alertMessage = NSLocalizedString("Unsaved Settings", comment: "")
        let alertInformativeText = NSLocalizedString("If you close this window, all unsaved changes will be lost. Are you sure you want to close the window?", comment: "")

        if self.settings.title == StringConstant.defaultProfileName {

            let firstButtonTitle: String
            if closeWindow {
                firstButtonTitle = ButtonTitle.saveAndClose
            } else {
                firstButtonTitle = ButtonTitle.save
            }

            let informativeText: String
            if self.isSaved() {
                informativeText = NSLocalizedString("You need to give your profile a name before it can be saved.", comment: "")
            } else {
                informativeText = alertInformativeText + "\n\n" + NSLocalizedString("You need to give your profile a name before it can be saved.", comment: "")
            }

            // ---------------------------------------------------------------------
            //  Show unnamed and unsaved settings alert to user
            // ---------------------------------------------------------------------
            alert.showAlert(message: alertMessage,
                            informativeText: informativeText,
                            window: window,
                            defaultString: StringConstant.defaultProfileName,
                            placeholderString: NSLocalizedString("Name", comment: ""),
                            firstButtonTitle: firstButtonTitle,
                            secondButtonTitle: ButtonTitle.close,
                            thirdButtonTitle: ButtonTitle.cancel,
                            firstButtonState: true,
                            sender: self) { newProfileName, response in
                                switch response {
                                case .alertFirstButtonReturn:
                                    self.settings.setValue(newProfileName, forValueKeyPath: PayloadKey.payloadDisplayName, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
                                    self.save(operationType: .saveOperation, completionHandler: { saveError in
                                        if saveError == nil {
                                            if closeWindow {
                                                windowController.performSelector(onMainThread: #selector(windowController.windowClose), with: windowController, waitUntilDone: false)
                                            }
                                            Log.shared.log(message: "Saving profile: \"\(self.settings.title)\" at path: \(self.fileURL?.path ?? "") was successful")
                                        } else {
                                            Log.shared.error(message: "Saving profile: \(self.settings.title) failed with error: \(String(describing: saveError?.localizedDescription))")
                                        }
                                    })
                                case .alertSecondButtonReturn:
                                    windowController.performSelector(onMainThread: #selector(windowController.windowClose), with: windowController, waitUntilDone: false)
                                case .alertThirdButtonReturn:
                                    Log.shared.debug(message: "User canceled", category: String(describing: self))
                                default:
                                    Log.shared.debug(message: "Unknown modal response from alert: \(response)", category: String(describing: self))
                                }
            }

            // ---------------------------------------------------------------------
            //  Select the text field in the alert sheet
            // ---------------------------------------------------------------------
            if let textFieldInput = alert.textFieldInput {
                textFieldInput.selectText(self)
                alert.firstButton?.isEnabled = false
            }
        } else {

            // ---------------------------------------------------------------------
            //  Show unsaved settings alert to user
            // ---------------------------------------------------------------------
            self.alert?.showAlert(message: alertMessage,
                                  informativeText: alertInformativeText,
                                  window: window,
                                  firstButtonTitle: ButtonTitle.saveAndClose,
                                  secondButtonTitle: ButtonTitle.close,
                                  thirdButtonTitle: ButtonTitle.cancel,
                                  firstButtonState: true,
                                  sender: self) { response  in

                                    switch response {
                                    case .alertFirstButtonReturn:
                                        self.save(operationType: .saveOperation, completionHandler: { saveError in
                                            if saveError == nil {
                                                windowController.performSelector(onMainThread: #selector(windowController.windowClose), with: windowController, waitUntilDone: false)
                                                Log.shared.log(message: "Saving profile: \"\(self.settings.title)\" at path: \(self.fileURL?.path ?? "") was successful")
                                            } else {
                                                Log.shared.error(message: "Saving profile: \(self.settings.title) failed with error: \(String(describing: saveError?.localizedDescription))")
                                            }
                                        })
                                    case .alertSecondButtonReturn:
                                        windowController.performSelector(onMainThread: #selector(windowController.windowClose), with: windowController, waitUntilDone: false)
                                    case .alertThirdButtonReturn:
                                        Log.shared.debug(message: "User canceled", category: String(describing: self))
                                    default:
                                        Log.shared.debug(message: "Unknown modal response from alert: \(response)", category: String(describing: self))
                                    }
            }
        }
    }

    // MARK: -
    // MARK: Public Functions

    public func isSaved() -> Bool {

        // NOTE: Should maybe use: self.isDocumentEdited and update change counts instead

        // ---------------------------------------------------------------------
        //  Check if the profile document has a url, if not it's never been saved
        // ---------------------------------------------------------------------
        if self.fileURL == nil { return false }

        // ---------------------------------------------------------------------
        //  Get the current settings dictionary
        // ---------------------------------------------------------------------
        // let settingsCurrent = self.settings.settingsCurrent()
        let currentSettings = self.settings.currentSettings()

        #if DEBUG
        // ---------------------------------------------------------------------
        //  DEBUG: Print all settings that has changed
        // ---------------------------------------------------------------------

        for (key, value) in self.settings.settingsSaved {
            self.saveCheck(key: key, value: value, newValue: currentSettings[key])
        }
        #endif

        // ---------------------------------------------------------------------
        //  Compare the saved settings to current settings to determine if something has changed
        // ---------------------------------------------------------------------
        return self.settings.settingsSaved == currentSettings
    }

    public func edit() {
        let windowController: NSWindowController
        if !self.windowControllers.isEmpty {
            windowController = self.windowControllers.first!
        } else {
            windowController = ProfileEditorWindowController(profile: self)
            self.addWindowController(windowController)
        }

        windowController.window?.makeKeyAndOrderFront(self)
    }

    // MARK: -
    // MARK: Private Functions

    private func saveURL(profilesDirectoryURL: URL) -> URL? {
        if UserDefaults.standard.string(forKey: PreferenceKey.profileLibraryFileNameFormat) == ProfileLibraryFileNameFormat.payloadIdentifier {
            guard let payloadIdentifier = self.settings.value(forValueKeyPath: PayloadKey.payloadIdentifier, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0) as? String else { return nil }
            return profilesDirectoryURL.appendingPathComponent(payloadIdentifier).appendingPathExtension(FileExtension.profile)
        } else {
            return profilesDirectoryURL.appendingPathComponent(self.identifier.uuidString).appendingPathExtension(FileExtension.profile)
        }
    }

    private func save(operationType: NSDocument.SaveOperationType, completionHandler: @escaping (Error?) -> Void) {

        // ---------------------------------------------------------------------
        //  Get path to profile save folder
        // ---------------------------------------------------------------------
        guard let profilesDirectoryURL = URL(applicationDirectory: .profiles) else {
            // FIXME: Correct Error
            return
        }

        // ---------------------------------------------------------------------
        //  Get or create a new path for the profile save file
        // ---------------------------------------------------------------------
        let saveURL: URL
        var moveURL: URL?
        if let currentSaveURL = self.saveURL(profilesDirectoryURL: profilesDirectoryURL) {
            if let fileURL = self.fileURL, fileURL != currentSaveURL {
                saveURL = fileURL
                moveURL = currentSaveURL
            } else {
                saveURL = currentSaveURL
            }
        } else if let fileURL = self.fileURL {
            saveURL = fileURL
        } else {
            saveURL = profilesDirectoryURL.appendingPathComponent(self.identifier.uuidString).appendingPathExtension(FileExtension.profile)
        }

        // ---------------------------------------------------------------------
        //  Call the NSDocument save function
        // ---------------------------------------------------------------------
        super.save(to: saveURL, ofType: TypeName.profile, for: operationType) { saveError in
            if saveError == nil {

                // -----------------------------------------------------------------
                //  Post notification that this profile was saved
                // -----------------------------------------------------------------
                NotificationCenter.default.post(name: .didSaveProfile, object: self, userInfo: [NotificationKey.identifier: self.identifier])

                // -----------------------------------------------------------------
                //  Update settingsSaved with the settings that were written to disk
                // -----------------------------------------------------------------
                self.settings.settingsSaved = self.settings.currentSettings()

                if let targetURL = moveURL {
                    guard !FileManager.default.fileExists(atPath: targetURL.path) else {
                        let error = NSError(domain: "profileCreatorError", code: -1, userInfo: [NSLocalizedDescriptionKey: "File already exists at target path: \(targetURL.path)"]) as Error
                        completionHandler(error)
                        return
                    }
                    super.move(to: targetURL, completionHandler: completionHandler)
                }
            } else { completionHandler(saveError) }
        }
    }
}

// MARK: -
// MARK: NSDocument Functions

extension Profile {
    override public func makeWindowControllers() {
        let windowController = ProfileEditorWindowController(profile: self)
        self.addWindowController(windowController)
    }

    override public func save(_ sender: Any?) {
        if self.settings.title == StringConstant.defaultProfileName { self.showAlertUnsaved(closeWindow: false); return }
        self.save(operationType: .saveOperation) { saveError in
            if saveError == nil {
                Log.shared.log(message: "Saving profile: \"\(self.settings.title)\" at path: \(self.fileURL?.path ?? "") was successful")
            } else {
                Log.shared.error(message: "Saving profile: \(self.settings.title) failed with error: \(String(describing: saveError?.localizedDescription))")
            }
        }
    }

    override public func data(ofType typeName: String) throws -> Data {
        guard typeName == TypeName.profile else {
            // FIXME: Correct Error
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }

        do {
            let profileData = try PropertyListSerialization.data(fromPropertyList: self.settings.currentSettings(), format: .xml, options: 0)
            return profileData
        } catch { Log.shared.error(message: "Creating property list from current settings failed with error: \(error)", category: String(describing: self)) }

        // FIXME: Correct Error
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override public func read(from data: Data, ofType typeName: String) throws {
        guard typeName == TypeName.profile else {
            // FIXME: Correct Error
            throw NSError(type: .unknown)
        }

        do {
            if let profileDict = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                /*
                 guard
                 let saveFormatVersion = profileDict[SettingsKey.saveFormatVersion] as? Int,
                 kSaveFormatVersionMin <= saveFormatVersion else {
                 // FIXME: Correct Error
                 throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
                 }
                 */
                self.settings.restoreSettingsSaved(profileDict)
                return
            }
        } catch {
            // TODO: Proper Logging
        }

        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
}

// MARK: -
// MARK: NSTextFieldDelegate Functions

extension Profile: NSTextFieldDelegate {

    // -------------------------------------------------------------------------
    //  Used when selecting a new profile name to not allow default or empty name
    // -------------------------------------------------------------------------
    public func controlTextDidChange(_ notification: Notification) {

        // ---------------------------------------------------------------------
        //  Get current text in the text field
        // ---------------------------------------------------------------------
        guard let userInfo = notification.userInfo,
            let fieldEditor = userInfo["NSFieldEditor"] as? NSTextView,
            let string = fieldEditor.textStorage?.string else {
                return
        }

        // ---------------------------------------------------------------------
        //  If current text in the text field is either:
        //   * Empty
        //   * Matches the default profile name
        //  Disable the OK button.
        // ---------------------------------------------------------------------
        if let alert = self.alert {
            if alert.firstButton!.isEnabled && (string.isEmpty || string == StringConstant.defaultProfileName) {
                alert.firstButton!.isEnabled = false
            } else {
                alert.firstButton!.isEnabled = true
            }
        }
    }
}
