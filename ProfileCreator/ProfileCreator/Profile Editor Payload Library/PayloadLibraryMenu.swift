//
//  PayloadLibraryMenu.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

protocol PayloadLibrarySelectionDelegate: AnyObject {
    func selectLibrary(type: PayloadType, sender: Any?)
}

class PayloadLibraryMenu: NSObject {

    // MARK: -
    // MARK: Variables

    let view = NSStackView()
    var buttons = [NSButton]()

    var buttonCustom: NSButton?
    var buttonAppleDomains: NSButton?
    var buttonAppleManagedPreferences: NSButton?
    var buttonApplicationManagedPreferences: NSButton?
    var buttonApplicationManagedPreferencesLocal: NSButton?
    var buttonDeveloper: NSButton?

    weak var selectionDelegate: PayloadLibrarySelectionDelegate?

    override init() {
        super.init()

        // ---------------------------------------------------------------------
        //  Setup View
        // ---------------------------------------------------------------------
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.orientation = .horizontal
        self.view.alignment = .centerY
        self.view.spacing = 10
        self.view.distribution = .gravityAreas
        self.view.detachesHiddenViews = true

        // ---------------------------------------------------------------------
        //  Add current buttons to view
        // ---------------------------------------------------------------------
        self.updateButtons(keyPath: nil)

        // ---------------------------------------------------------------------
        //  Setup Notification Observers
        // ---------------------------------------------------------------------
        UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowCustom, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowDomainsApple, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowManagedPreferencesApple, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowManagedPreferencesApplications, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowManagedPreferencesApplicationsLocal, options: .new, context: nil)
    }

    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowCustom, context: nil)
        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowDomainsApple, context: nil)
        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowManagedPreferencesApple, context: nil)
        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowManagedPreferencesApplications, context: nil)
        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.payloadLibraryShowManagedPreferencesApplicationsLocal, context: nil)
    }

    // MARK: -
    // MARK: Key/Value Observing Functions

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let add = change?[.newKey] as? Bool {
            if add {
                if keyPath ?? "" == PreferenceKey.payloadLibraryShowManagedPreferencesApplicationsLocal, let payloadTypes = (NSApplication.shared.delegate as? AppDelegate)?.payloadTypesEnabled() {
                    ProfilePayloads.shared.currentPayloadTypes = payloadTypes
                    ProfilePayloads.shared.updateManifests(ofType: payloadTypes)
                }
                self.updateButtons(keyPath: keyPath)
                // FIXME: Keep selection here, if it isn't removed
                if let button = self.buttons.first {
                    self.selectLibrary(button)
                }
            } else if let button = self.buttonFor(keyPath: keyPath), self.view.views.contains(button) {
                self.view.removeView(button)
                self.buttons = self.buttons.filter({ $0 != button })
                // FIXME: Implement when the selection is added to the library

            }
        }
    }

    // MARK: -
    // MARK: Button Action Functions

    @objc func selectLibrary(_ sender: NSButton) {
        if let selectLibrary = self.selectionDelegate?.selectLibrary, let libraryTag = PayloadType(int: sender.tag) {
            selectLibrary(libraryTag, self)
            sender.state = .on
            for button in self.buttons where button != sender {
                button.state = .off
            }
        }
    }

    // MARK: -
    // MARK: Button Action Functions

    private func updateButtons(keyPath: String?) {

        // ---------------------------------------------------------------------
        //  Remove all current items from stack view
        // ---------------------------------------------------------------------
        self.buttons.removeAll()
        for view in self.view.views {
            self.view.removeView(view)
        }

        // ---------------------------------------------------------------------
        //  Add all enabled buttons to stack view
        // ---------------------------------------------------------------------
        let userDefaults = UserDefaults.standard

        // Apple Domains
        if userDefaults.bool(forKey: PreferenceKey.payloadLibraryShowDomainsApple) || keyPath == PreferenceKey.payloadLibraryShowDomainsApple {
            if let buttonAppleDomains = self.buttonFor(keyPath: PreferenceKey.payloadLibraryShowDomainsApple) {
                self.buttons.append(buttonAppleDomains)
                self.view.addView(buttonAppleDomains, in: .center)
            }
        }

        // Apple Managed Preferences
        if userDefaults.bool(forKey: PreferenceKey.payloadLibraryShowManagedPreferencesApple) || keyPath == PreferenceKey.payloadLibraryShowManagedPreferencesApple {
            if let buttonAppleManagedPreferences = self.buttonFor(keyPath: PreferenceKey.payloadLibraryShowManagedPreferencesApple) {
                self.buttons.append(buttonAppleManagedPreferences)
                self.view.addView(buttonAppleManagedPreferences, in: .center)
            }
        }

        // Application Managed Preferences
        if userDefaults.bool(forKey: PreferenceKey.payloadLibraryShowManagedPreferencesApplications) || keyPath == PreferenceKey.payloadLibraryShowManagedPreferencesApplications {
            if let buttonApplicationDomains = self.buttonFor(keyPath: PreferenceKey.payloadLibraryShowManagedPreferencesApplications) {
                self.buttons.append(buttonApplicationDomains)
                self.view.addView(buttonApplicationDomains, in: .center)
            }
        }

        // Application Managed Preferences Local
        if userDefaults.bool(forKey: PreferenceKey.payloadLibraryShowManagedPreferencesApplicationsLocal) || keyPath == PreferenceKey.payloadLibraryShowManagedPreferencesApplicationsLocal {
            if let buttonApplicationManagedPreferencesLocal = self.buttonFor(keyPath: PreferenceKey.payloadLibraryShowManagedPreferencesApplicationsLocal) {
                self.buttons.append(buttonApplicationManagedPreferencesLocal)
                self.view.addView(buttonApplicationManagedPreferencesLocal, in: .center)
            }
        }

        // Custom
        if userDefaults.bool(forKey: PreferenceKey.payloadLibraryShowCustom) || keyPath == PreferenceKey.payloadLibraryShowCustom {
            if let buttonLocalCustom = self.buttonFor(keyPath: PreferenceKey.payloadLibraryShowCustom) {
                self.buttons.append(buttonLocalCustom)
                self.view.addView(buttonLocalCustom, in: .center)
            }
        }

        // Developer
        #if DEBUG
        if self.buttonDeveloper == nil {
            self.buttonDeveloper = self.button(imageName: "SourceCodeDeSelected",
                                               alternateImageName: "SourceCode",
                                               tag: PayloadTypeInt.managedPreferencesDeveloper.rawValue,
                                               tooltip: NSLocalizedString("Developer Domains", comment: String(describing: self)))
        }
        self.buttons.append(self.buttonDeveloper!)
        self.view.addView(self.buttonDeveloper!, in: .center)
        #endif
    }

    // swiftlint:disable cyclomatic_complexity
    private func buttonFor(keyPath: String?) -> NSButton? {

        switch keyPath {
        case PreferenceKey.payloadLibraryShowCustom:
            if self.buttonCustom == nil {
                self.buttonCustom = self.button(imageName: "CustomPayloadDeSelected",
                                                alternateImageName: "CustomPayload",
                                                tag: PayloadTypeInt.custom.rawValue,
                                                tooltip: NSLocalizedString("Custom", comment: String(describing: self)))
            }
            return self.buttonCustom
        case PreferenceKey.payloadLibraryShowDomainsApple:
            if self.buttonAppleDomains == nil {
                self.buttonAppleDomains = self.button(imageName: "ApprovalDeSelected",
                                                      alternateImageName: "Approval",
                                                      tag: PayloadTypeInt.manifestsApple.rawValue,
                                                      tooltip: NSLocalizedString("Apple Domains", comment: String(describing: self)))
            }
            return self.buttonAppleDomains
        case PreferenceKey.payloadLibraryShowManagedPreferencesApple:
            if self.buttonAppleManagedPreferences == nil {
                self.buttonAppleManagedPreferences = self.button(imageName: "AppleDeSelected",
                                                                 alternateImageName: "Apple",
                                                                 tag: PayloadTypeInt.managedPreferencesApple.rawValue,
                                                                 tooltip: NSLocalizedString("Apple Managed Preferences", comment: String(describing: self)))
            }
            return self.buttonAppleManagedPreferences
        case PreferenceKey.payloadLibraryShowManagedPreferencesApplications:
            if self.buttonApplicationManagedPreferences == nil {
                self.buttonApplicationManagedPreferences = self.button(imageName: "AppStoreDeSelected",
                                                                       alternateImageName: "AppStore",
                                                                       tag: PayloadTypeInt.managedPreferencesApplications.rawValue,
                                                                       tooltip: NSLocalizedString("Application Managed Preferences", comment: String(describing: self)))
            }
            return self.buttonApplicationManagedPreferences
        case PreferenceKey.payloadLibraryShowManagedPreferencesApplicationsLocal:
            if self.buttonApplicationManagedPreferencesLocal == nil {
                self.buttonApplicationManagedPreferencesLocal = self.button(imageName: "iMacDeSelected",
                                                                            alternateImageName: "iMac",
                                                                            tag: PayloadTypeInt.managedPreferencesApplicationsLocal.rawValue,
                                                                            tooltip: NSLocalizedString("Application Managed Preferences Local", comment: String(describing: self)))
            }
            return self.buttonApplicationManagedPreferencesLocal
        case .none:
            Log.shared.error(message: "No keyPath passed for button", category: String(describing: self))
        case .some:
            Log.shared.error(message: "Unknown keyPath passed for button: \(String(describing: keyPath))", category: String(describing: self))
        }

        return nil
    }
    // swiftlint:enable cyclomatic_complexity

    private func button(imageName: String, alternateImageName: String, tag: Int, tooltip: String) -> NSButton? {

        guard let image = NSImage(named: imageName) else {
            Log.shared.error(message: "Failed to get image with name: \(imageName)", category: String(describing: self))
            return nil
        }

        guard let alternateImage = NSImage(named: alternateImageName) else {
            Log.shared.error(message: "Failed to get alternate image with name: \(alternateImageName)", category: String(describing: self))
            return nil
        }

        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Create Button
        // ---------------------------------------------------------------------
        let button = NSButton()
        button.bezelStyle = .smallSquare
        button.setButtonType(.toggle)
        button.isBordered = false
        button.isTransparent = false
        button.tag = tag
        button.target = self
        button.action = #selector(self.selectLibrary(_:))
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyUpOrDown
        button.image = image
        button.alternateImage = alternateImage
        button.toolTip = tooltip

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Height
        constraints.append(NSLayoutConstraint(item: button,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 18.0))

        // Width == Height
        constraints.append(NSLayoutConstraint(item: button,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: button,
                                              attribute: .height,
                                              multiplier: 1,
                                              constant: 0.0))

        // ---------------------------------------------------------------------
        //  Activate layout constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)

        return button
    }
}
