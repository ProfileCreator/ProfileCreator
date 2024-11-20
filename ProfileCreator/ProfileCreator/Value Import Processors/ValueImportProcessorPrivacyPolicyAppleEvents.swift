//
//  ValueImportProcessorPrivacyPolicyAppleEvents.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class ValueImportProcessorPrivacyPolicyAppleEvents: ValueImportProcessor {

    weak var cellView: PayloadCellViewTableView?
    var accessoryView: ValueImportProcessorPrivacyPolicyAppleEventsAccessoryView?

    init() {
        super.init(identifier: "com.apple.TCC.configuration-profile-policy.services.AppleEvents")
    }

    override func addValue(toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        guard let fileURL = self.fileURL, let tableCellView = cellView as? PayloadCellViewTableView else {
            completionHandler(nil)
            return
        }

        self.cellView = tableCellView

        if let fileUTI = self.fileUTI, NSWorkspace.shared.type(fileUTI, conformsToType: kUTTypeApplicationBundle as String) {

            guard
                let applicationBundle = Bundle(url: fileURL),
                let bundleIdentifier = applicationBundle.bundleIdentifier else {
                    throw ValueImportError("The file: \"\(self.fileURL?.lastPathComponent ?? "Unknown File")\" does not seem to be a valid application bundle.")
            }

            guard let designatedCodeRequirement = applicationBundle.designatedCodeRequirementString else {
                throw ValueImportError("The file: \"\(self.fileURL?.lastPathComponent ?? "Unknown File")\" did not have a designated code requirement for it's code signature, and cannot be used.")
            }

            try self.promptUser(withName: fileURL.lastPathComponent,
                                identifier: bundleIdentifier,
                                identifierType: "bundleID",
                                codeRequirement: designatedCodeRequirement,
                                toCurrentValue: toCurrentValue,
                                cellView: tableCellView,
                                completionHandler: completionHandler)
        } else {

            guard let designatedCodeRequirement = SecRequirementCopyString(forURL: fileURL) else {
                throw ValueImportError("The file: \"\(self.fileURL?.lastPathComponent ?? "Unknown File")\" did not have a designated code requirement for it's code signature, and cannot be used.")
            }

            try self.promptUser(withName: fileURL.lastPathComponent,
                                identifier: fileURL.path,
                                identifierType: "path",
                                codeRequirement: designatedCodeRequirement,
                                toCurrentValue: toCurrentValue,
                                cellView: tableCellView,
                                completionHandler: completionHandler)
        }

    }

    func promptUser(withName name: String,
                    identifier: String,
                    identifierType: String,
                    codeRequirement: String,
                    toCurrentValue: [Any]?,
                    cellView: PayloadCellViewTableView,
                    completionHandler: @escaping (_ value: Any?) -> Void) throws {

        DispatchQueue.main.async {

            guard let fileURL = self.fileURL else {
                // FIXME: Should Throw or pass
                completionHandler(nil)
                return
            }

            guard let window = cellView.window else {
                // FIXME: Should Throw
                completionHandler(nil)
                return
            }

            guard let accessoryView = ValueImportProcessorPrivacyPolicyAppleEventsAccessoryView(withCellView: cellView, url: fileURL) else {
                completionHandler(nil)
                return
            }

            self.accessoryView = accessoryView
            let sheetWindow = PolicyWindow(withCellView: cellView, accessoryView: accessoryView, url: fileURL)

            window.beginSheet(sheetWindow) { response in
                guard response == .OK else {
                    completionHandler(nil)
                    return
                }

                var value = [String: Any]()
                value["StaticCode"] = false

                // Allowed
                if let radioButton = accessoryView.radioButtonAllow {
                    value["Allowed"] = radioButton.state == .on
                } else {
                    value["Allowed"] = true
                }

                guard
                    let sendingInfo = accessoryView.sendingApplicationInfo,
                    let recievingInfo = accessoryView.recievingApplicationInfo else {
                    return
                }

                guard
                    let sendingIdentifier = sendingInfo["Identifier"] as? String,
                    let sendingType = sendingInfo["IdentifierType"] as? String,
                    let sendingCodeRequirement = sendingInfo["CodeRequirement"] as? String else {
                        Log.shared.error(message: "Failed to get required information for sending application", category: String(describing: self))
                        return
                }

                value["Identifier"] = sendingIdentifier
                value["IdentifierType"] = sendingType
                value["CodeRequirement"] = sendingCodeRequirement

                guard
                    let recievingIdentifier = recievingInfo["Identifier"] as? String,
                    let recieveingType = recievingInfo["IdentifierType"] as? String,
                    let recieveingCodeRequirement = recievingInfo["CodeRequirement"] as? String else {
                        Log.shared.error(message: "Failed to get required information for recieving application", category: String(describing: self))
                        return
                }

                value["AEReceiverIdentifier"] = recievingIdentifier
                value["AEReceiverIdentifierType"] = recieveingType
                value["AEReceiverCodeRequirement"] = recieveingCodeRequirement

                if var currentValue = toCurrentValue as? [[String: Any]] {
                    if let index = currentValue.firstIndex(where: { $0 == value }) {
                        currentValue[index] = value
                    } else {
                        currentValue.append(value)
                    }
                    completionHandler(currentValue)
                } else {
                    completionHandler([value])
                }
            }
            /*
             let alert = NSAlert()
             alert.messageText = NSLocalizedString("Adding \"\(name)\"", comment: "")
             alert.informativeText = NSLocalizedString("Select if \(name) should be the application sending or recieving apple events.", comment: "")
             if !cellView.tableViewContent.isEmpty {
             alert.accessoryView = accessoryView
             }
             alert.addButton(withTitle: NSLocalizedString("Recieve AppleEvents", comment: "") ) // 1000
             alert.addButton(withTitle: NSLocalizedString("Send AppleEvents", comment: "")) // 1001
             alert.icon = NSWorkspace.shared.icon(forFile: fileURL.path)

             for button in alert.buttons {
             button.keyEquivalent = ""
             }

             alert.beginSheetModal(for: window) { response in

             var value: [String: Any]
             var selectedIndex: Int?

             if
             accessoryView.radioButtonAllow?.state == .on,
             let index = accessoryView.tableView?.selectedRow,
             -1 < index,
             index < cellView.tableViewContent.count,
             let selectedValue = cellView.tableViewContent[index] as? [String: Any] {
             selectedIndex = index
             value = selectedValue
             } else {
             value = [String: Any]()
             }

             value["StaticCode"] = false
             value["Allowed"] = true

             switch response {
             case NSApplication.ModalResponse(1_000):
             value["AEReceiverIdentifier"] = identifier
             value["AEReceiverIdentifierType"] = identifierType
             value["AEReceiverCodeRequirement"] = codeRequirement
             case NSApplication.ModalResponse(1_001):
             value["Identifier"] = identifier
             value["IdentifierType"] = identifierType
             value["CodeRequirement"] = codeRequirement
             default:
             Log.shared.error(message: "Unknown modal response: \(response)", category: String(describing: self))
             }

             if var currentValue = toCurrentValue as? [[String: Any]] {
             if let index = selectedIndex {
             currentValue[index] = value
             } else {
             currentValue.append(value)
             }
             completionHandler(currentValue)
             } else {
             completionHandler([value])
             }
             }
             */
        }
    }
}

class PolicyWindow: NSWindow {

    override var canBecomeKey: Bool { true }

    init(withCellView cellView: PayloadCellViewTableView, accessoryView: ValueImportProcessorPrivacyPolicyAppleEventsAccessoryView, url: URL) {
        super.init(contentRect: NSRect.zero, styleMask: .docModalWindow, backing: .buffered, defer: false)
        self.contentView = accessoryView
    }

}

class ValueImportProcessorPrivacyPolicyAppleEventsAccessoryView: NSView {

    // MARK: -
    // MARK: Variables

    @objc dynamic var updateRow: Bool = false

    weak var cellView: PayloadCellViewTableView?

    var url: URL?

    var height: CGFloat = 0.0

    var separatorTop = NSBox()
    var separatorBottom = NSBox()

    let textFieldTitle = NSTextField()
    let textFieldDescription = NSTextField()
    let textFieldStatus = NSTextField()

    let buttonCancel = NSButton()
    let buttonAdd = NSButton()

    var radioButtonAllow: NSButton?
    var radioButtonDeny: NSButton?

    var scrollView: OverlayScrollView?
    var tableView: NSTableView?

    let imageViewSendingApp = NSImageView()
    let imageViewAllow = NSImageView()
    let imageViewRecievingApp = NSImageView()

    let popUpButtonSendingApp = NSPopUpButton()
    let popUpButtonRecievingApp = NSPopUpButton()

    var userApplications = [[String: Any]]()

    var sendingApplicationInfo: [String: Any]?
    var recievingApplicationInfo: [String: Any]?

    // MARK: -
    // MARK: Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    @objc func buttonClicked(_ button: NSButton) {
        self.setValue(button != self.radioButtonAllow, forKeyPath: NSStringFromSelector(#selector(getter: self.updateRow)))
    }

    func informationForIdentifier(_ identifier: String) -> [String: Any]? {
        var information = [String: Any]()
        if
            let bundlePath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier),
            let bundle = Bundle(path: bundlePath.path) {
            guard let designatedCodeRequirement = bundle.designatedCodeRequirementString else { return nil }
            information["CodeRequirement"] = designatedCodeRequirement
            information["Identifier"] = identifier
            information["IdentifierType"] = "bundleID"
            information["Title"] = bundle.bundleURL.lastPathComponent
            information["Icon"] = NSWorkspace.shared.icon(forFile: bundlePath.path)
            information["Path"] = bundle.bundleURL.path
        } else if
            let designatedCodeRequirement = SecRequirementCopyString(forURL: URL(fileURLWithPath: identifier)) {
            information["CodeRequirement"] = designatedCodeRequirement
            information["Identifier"] = identifier
            information["IdentifierType"] = "path"
            information["Title"] = URL(fileURLWithPath: identifier).lastPathComponent
            information["Icon"] = NSWorkspace.shared.icon(forFile: identifier)
            information["Path"] = identifier
        }
        return information
    }

    func iconForIdentifier(_ identifier: String) -> NSImage {
        if let bundlePath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) {
            return NSWorkspace.shared.icon(forFile: bundlePath.path)
        } else {
            return NSWorkspace.shared.icon(forFile: identifier)
        }
    }

    @objc func selectOtherAppliction(_ menuItem: NSMenuItem) {

        // ---------------------------------------------------------------------
        //  Setup open dialog
        // ---------------------------------------------------------------------
        let openPanel = NSOpenPanel()
        openPanel.prompt = !self.buttonAdd.title.isEmpty ? self.buttonAdd.title : NSLocalizedString("Select File", comment: "")
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false

        // ---------------------------------------------------------------------
        //  Get open dialog allowed file types
        // ---------------------------------------------------------------------
        if let window = self.window {
            openPanel.beginSheetModal(for: window) { response in
                if response == .OK {
                    for url in openPanel.urls {
                        let passedIdentifier: String
                        if let bundle = Bundle(url: url) {
                            passedIdentifier = bundle.bundleIdentifier ?? url.path
                        } else {
                            passedIdentifier = url.path
                        }

                        if let item = self.informationForIdentifier(passedIdentifier) {
                            self.userApplications.append(item)
                            if url == openPanel.urls.last {
                                self.popUpButtonSendingApp.menu = self.menuForSendingAppliction()
                                self.popUpButtonRecievingApp.menu = self.menuForRecievingApplication()
                                if let title = item["Title"] as? String {
                                    if menuItem.identifier == NSUserInterfaceItemIdentifier(rawValue: "sending") {
                                        self.popUpButtonSendingApp.selectItem(withTitle: title)
                                        self.selected(self.popUpButtonSendingApp)
                                    } else {
                                        self.popUpButtonRecievingApp.selectItem(withTitle: title)
                                        self.selected(self.popUpButtonRecievingApp)
                                    }
                                }
                                 self.updateView()
                            }
                        }
                    }
                } else {
                    if menuItem.identifier == NSUserInterfaceItemIdentifier(rawValue: "sending") {
                        if
                            let image = self.imageViewSendingApp.image,
                            let menuItem = self.popUpButtonSendingApp.menu?.items.first(where: {
                                if let object = $0.representedObject as? [String: Any] {
                                    return object["Image"] as? NSImage == image
                                }
                                return false
                            }) {
                            self.popUpButtonSendingApp.selectItem(withTitle: menuItem.title)
                        }
                    } else {

                    }
                }
            }
        }
    }

    func menuForRecievingApplication() -> NSMenu {
        let menu = NSMenu()
        for item in self.userApplications {
            menu.addItem(self.menuItem(forInformation: item))
        }
        var addedSeparator = false
        for bundleIdentifier in ["com.apple.systemevents", "com.apple.systemuiserver", "com.apple.finder"] {
            if let information = self.informationForIdentifier(bundleIdentifier) {
                if !addedSeparator {
                    menu.addItem(NSMenuItem.separator())
                    addedSeparator = true
                }
                menu.addItem(self.menuItem(forInformation: information))
            }
        }
        menu.addItem(NSMenuItem.separator())

        let menuItemOther = NSMenuItem()
        menuItemOther.title = NSLocalizedString("Other…", comment: "")
        menuItemOther.identifier = NSUserInterfaceItemIdentifier(rawValue: "recieving")
        menuItemOther.target = self
        menuItemOther.action = #selector(self.selectOtherAppliction(_:))
        menu.addItem(menuItemOther)
        return menu
    }

    func menuForSendingAppliction() -> NSMenu {
        let menu = NSMenu()
        for item in self.userApplications {
            menu.addItem(self.menuItem(forInformation: item))
        }
        menu.addItem(NSMenuItem.separator())
        let menuItemOther = NSMenuItem()
        menuItemOther.title = NSLocalizedString("Other…", comment: "")
        menuItemOther.identifier = NSUserInterfaceItemIdentifier(rawValue: "sending")
        menuItemOther.target = self
        menuItemOther.action = #selector(self.selectOtherAppliction(_:))
        menu.addItem(menuItemOther)
        return menu
    }

    init?(withCellView cellView: PayloadCellViewTableView, url: URL) {

        // ---------------------------------------------------------------------
        //  Initialize Self
        // ---------------------------------------------------------------------
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()
        self.url = url
        self.cellView = cellView

        var items = [[String: Any]]()

        let passedIdentifier: String
        if let bundle = Bundle(url: url) {
            passedIdentifier = bundle.bundleIdentifier ?? url.path
        } else {
            passedIdentifier = url.path
        }

        if let item = self.informationForIdentifier(passedIdentifier) {
            self.sendingApplicationInfo = item
            self.recievingApplicationInfo = item
            items.append(item)
        }

        if let tableViewContent = cellView.tableViewContent as? [[String: Any]] {
            for policyRule in tableViewContent {
                if
                    let identifier = policyRule["Identifier"] as? String,
                    let identifierType = policyRule["IdentifierType"] as? String,
                    let codeRequirement = policyRule["CodeRequirement"] as? String {
                    var information = [String: Any]()
                    information["Identifier"] = codeRequirement
                    information["IdentifierType"] = identifierType
                    information["CodeRequirement"] = codeRequirement

                    if
                        let bundlePath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier),
                        let bundle = Bundle(path: bundlePath.path) {
                        information["Title"] = bundle.bundleURL.lastPathComponent
                        information["Icon"] = NSWorkspace.shared.icon(forFile: bundlePath.path)
                        information["Path"] = bundle.bundleURL.path
                    } else {
                        information["Title"] = URL(fileURLWithPath: identifier).lastPathComponent
                        information["Icon"] = NSWorkspace.shared.icon(forFile: identifier)
                        information["Path"] = identifier
                    }

                    if !items.contains(where: { $0["Path"] as? String == information["Path"] as? String }) {
                        items.append(information)
                    }
                    continue
                } else
                    if let identifier = policyRule["AEReceiverIdentifier"] as? String,
                        let identifierType = policyRule["AEReceiverIdentifierType"] as? String,
                        let codeRequirement = policyRule["AEReceiverCodeRequirement"] as? String {
                        var information = [String: Any]()
                        information["Identifier"] = codeRequirement
                        information["IdentifierType"] = identifierType
                        information["CodeRequirement"] = codeRequirement

                        if
                            let bundlePath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier),
                            let bundle = Bundle(path: bundlePath.path) {
                            information["Title"] = bundle.bundleURL.lastPathComponent
                            information["Icon"] = NSWorkspace.shared.icon(forFile: bundlePath.path)
                            information["Path"] = bundle.bundleURL.path
                        } else {
                            information["Title"] = URL(fileURLWithPath: identifier).lastPathComponent
                            information["Icon"] = NSWorkspace.shared.icon(forFile: identifier)
                            information["Path"] = identifier
                        }

                        if !items.contains(where: { $0["Path"] as? String == information["Path"] as? String }) {
                            items.append(information)
                        }
                        continue
                }

                var identifier: String
                if let bundleIdentifier = policyRule["Identifier"] as? String {
                    identifier = bundleIdentifier
                } else {
                    continue
                }

                if let info = self.informationForIdentifier(identifier) {
                    items.append(info)
                }
            }
        }

        self.userApplications = items

        self.setupView(constraints: &constraints)
        self.setupTextFieldTitle(constraints: &constraints)
        self.setupImageViewSendingApp(constraints: &constraints)
        self.setupPopUpButtonSendingApp(cellView: cellView, items: items, constraints: &constraints)
        self.setupImageViewRecievingApp(constraints: &constraints)
        self.setupPopUpButtonRecievingApp(cellView: cellView, items: items, constraints: &constraints)
        self.setupRadioButtons(cellView: cellView, constraints: &constraints)
        self.setupButtonAdd(constraints: &constraints)
        self.setupButtonCancel(constraints: &constraints)
        self.setupTextFieldDescription(constraints: &constraints)
        self.setupTextFieldStatus(constraints: &constraints)
        self.setupSeparatorTop(constraints: &constraints)
        self.setupSeparatorBottom(constraints: &constraints)
        self.setupImageViewAllow(constraints: &constraints)

        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: 600.0))

        // ---------------------------------------------------------------------
        //  Activate layout constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)

        self.updateView()
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func selected(_ popUpButton: NSPopUpButton) {
        if popUpButton == self.popUpButtonSendingApp {
            guard let information = popUpButton.selectedItem?.representedObject as? [String: Any] else { return }
            self.sendingApplicationInfo = information
            if let icon = information["Icon"] as? NSImage {
                self.imageViewSendingApp.image = icon
            }
            self.updateView()
        } else if popUpButton == self.popUpButtonRecievingApp {
            guard let information = popUpButton.selectedItem?.representedObject as? [String: Any] else { return }
            self.recievingApplicationInfo = information
            if let icon = information["Icon"] as? NSImage {
                self.imageViewRecievingApp.image = icon
            }
            self.updateView()
        }
    }

    @objc func checked(_ radioButton: NSButton) {
        if radioButton == self.radioButtonAllow {
            self.imageViewAllow.image = NSImage(named: "ArrowRight")
        } else {
            self.imageViewAllow.image = NSImage(named: "unavailable")
        }
        self.updateView()
    }

    func updateView() {
        let sending = self.popUpButtonSendingApp.selectedItem?.title ?? ""
        let recieving = self.popUpButtonRecievingApp.selectedItem?.title ?? ""

        if sending.isEmpty || recieving.isEmpty {
            self.textFieldStatus.stringValue = ""
            self.buttonAdd.isEnabled = false
            return
        } else if sending == recieving {
            self.textFieldStatus.stringValue = "\(sending) is already allowed to send AppleEvents to itself."
            self.buttonAdd.isEnabled = false
            return
        } else {
            self.buttonAdd.isEnabled = true
        }

        self.textFieldStatus.stringValue = self.messageString(sending: sending, recieving: recieving)
    }

    func messageString(sending: String, recieving: String) -> String {
        "\(self.radioButtonAllow?.state == .on ? "Allow" : "Deny") \(sending) to send AppleEvents to \(recieving)"
    }

    @objc func clicked(_ button: NSButton) {
        guard let window = self.cellView?.window, let sheetWindow = self.window else { return }
        if button.title == ButtonTitle.add {
            window.endSheet(sheetWindow, returnCode: .OK)
            return
        }
        window.endSheet(sheetWindow, returnCode: .cancel)
    }

    // MARK: -
    // MARK: Setup

    func setupView(constraints: inout [NSLayoutConstraint]) {
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    func menuItem(forInformation information: [String: Any]) -> NSMenuItem {
        let menuItem = NSMenuItem()
        menuItem.title = information["Title"] as? String ?? "Unknown"
        menuItem.representedObject = information
        // menuItem.image = information["Icon"] as? NSImage
        return menuItem
    }

    func setupTextFieldTitle(constraints: inout [NSLayoutConstraint]) {

        self.textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldTitle.lineBreakMode = .byWordWrapping
        self.textFieldTitle.isBordered = false
        self.textFieldTitle.isBezeled = false
        self.textFieldTitle.drawsBackground = false
        self.textFieldTitle.isEditable = false
        self.textFieldTitle.font = NSFont.boldSystemFont(ofSize: 14)
        self.textFieldTitle.textColor = .labelColor
        self.textFieldTitle.alignment = .natural
        self.textFieldTitle.stringValue = NSLocalizedString("Configure AppleEvents Policy", comment: "")
        self.textFieldTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        self.addSubview(self.textFieldTitle)

        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: 16.0))

        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 32.0))

        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 32.0))
    }

    func setupTextFieldDescription(constraints: inout [NSLayoutConstraint]) {

        self.textFieldDescription.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldDescription.lineBreakMode = .byWordWrapping
        self.textFieldDescription.isBordered = false
        self.textFieldDescription.isBezeled = false
        self.textFieldDescription.drawsBackground = false
        self.textFieldDescription.isEditable = false
        self.textFieldDescription.font = NSFont.labelFont(ofSize: 12)
        self.textFieldDescription.textColor = .labelColor
        self.textFieldDescription.alignment = .natural
        self.textFieldDescription.stringValue = NSLocalizedString("Select the applications Sending and Recieving AppleEvents and if that should be allowed.", comment: "")
        self.textFieldDescription.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.textFieldDescription.sizeToFit()
        self.addSubview(self.textFieldDescription)

        constraints.append(NSLayoutConstraint(item: self.textFieldDescription,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 5.0))

        constraints.append(NSLayoutConstraint(item: self.textFieldDescription,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 32.0))

        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldDescription,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 32.0))
    }

    func setupTextFieldStatus(constraints: inout [NSLayoutConstraint]) {

        self.textFieldStatus.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldStatus.lineBreakMode = .byWordWrapping
        self.textFieldStatus.isBordered = false
        self.textFieldStatus.isBezeled = false
        self.textFieldStatus.drawsBackground = false
        self.textFieldStatus.isEditable = false
        self.textFieldStatus.font = NSFont.boldSystemFont(ofSize: 15)
        self.textFieldStatus.textColor = .labelColor
        self.textFieldStatus.alignment = .center
        self.textFieldStatus.stringValue = NSLocalizedString("Allow Test.app to send AppleEvents to SystemEvents.app", comment: "")
        self.textFieldStatus.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.textFieldStatus.sizeToFit()
        self.addSubview(self.textFieldStatus)

        constraints.append(NSLayoutConstraint(item: self.textFieldStatus,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.separatorTop,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 12.0))

        constraints.append(NSLayoutConstraint(item: self.textFieldStatus,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 40.0))

        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldStatus,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 40.0))
    }

    func setupImageViewSendingApp(constraints: inout [NSLayoutConstraint]) {
        self.imageViewSendingApp.translatesAutoresizingMaskIntoConstraints = false
        // self.imageViewSendingApp.imageFrameStyle = .grayBezel
        self.imageViewSendingApp.imageScaling = .scaleProportionallyUpOrDown
        self.imageViewSendingApp.setContentHuggingPriority(.required, for: .horizontal)
        if let itemURL = self.url {
            self.imageViewSendingApp.image = NSWorkspace.shared.icon(forFile: itemURL.path)
        }
        self.addSubview(self.imageViewSendingApp)

        constraints.append(NSLayoutConstraint(item: self.imageViewSendingApp,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.textFieldDescription,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 16.0))

        constraints.append(NSLayoutConstraint(item: self.imageViewSendingApp,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: 140.0))

        constraints.append(NSLayoutConstraint(item: self.imageViewSendingApp,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: self.imageViewSendingApp,
                                              attribute: .height,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }

    func setupImageViewAllow(constraints: inout [NSLayoutConstraint]) {
        self.imageViewAllow.translatesAutoresizingMaskIntoConstraints = false
        self.imageViewAllow.image = NSImage(named: "ArrowRight")
        self.imageViewAllow.imageScaling = .scaleProportionallyUpOrDown
        self.imageViewAllow.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.imageViewAllow.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.imageViewAllow.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.imageViewAllow.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        self.addSubview(self.imageViewAllow)

        constraints.append(NSLayoutConstraint(item: self.imageViewAllow,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerX,
                                              multiplier: 1.0,
                                              constant: 0.0))

        constraints.append(NSLayoutConstraint(item: self.imageViewAllow,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.imageViewSendingApp,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))

        constraints.append(NSLayoutConstraint(item: self.imageViewAllow,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.imageViewSendingApp,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 50.0))

        constraints.append(NSLayoutConstraint(item: self.imageViewAllow,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: 64.0))

        constraints.append(NSLayoutConstraint(item: self.imageViewAllow,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: self.imageViewAllow,
                                              attribute: .height,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }

    func setupImageViewRecievingApp(constraints: inout [NSLayoutConstraint]) {
        self.imageViewRecievingApp.translatesAutoresizingMaskIntoConstraints = false
        // self.imageViewRecievingApp.imageFrameStyle = .grayBezel
        self.imageViewRecievingApp.imageScaling = .scaleProportionallyUpOrDown
        if let itemURL = self.url {
            self.imageViewRecievingApp.image = NSWorkspace.shared.icon(forFile: itemURL.path)
        }
        self.addSubview(self.imageViewRecievingApp)

        constraints.append(NSLayoutConstraint(item: self.imageViewRecievingApp,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.imageViewSendingApp,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))

        constraints.append(NSLayoutConstraint(item: self.imageViewRecievingApp,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.imageViewAllow,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 50.0))

        constraints.append(NSLayoutConstraint(item: self.imageViewRecievingApp,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: self.imageViewSendingApp,
                                              attribute: .height,
                                              multiplier: 1.0,
                                              constant: 0.0))

        constraints.append(NSLayoutConstraint(item: self.imageViewRecievingApp,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: self.imageViewRecievingApp,
                                              attribute: .height,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }

    func setupButtonCancel(constraints: inout [NSLayoutConstraint]) {
        self.buttonCancel.translatesAutoresizingMaskIntoConstraints = false
        self.buttonCancel.bezelStyle = .rounded
        self.buttonCancel.setButtonType(.momentaryPushIn)
        self.buttonCancel.isBordered = true
        self.buttonCancel.isTransparent = false
        self.buttonCancel.title = ButtonTitle.cancel
        self.buttonCancel.target = self
        self.buttonCancel.action = #selector(self.clicked(_:))
        self.buttonCancel.sizeToFit()

        // ---------------------------------------------------------------------
        //  Add Button to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.buttonCancel)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.buttonAdd,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.buttonCancel,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 6.0))

        // Center Y
        constraints.append(NSLayoutConstraint(item: self.buttonCancel,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.buttonAdd,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }

    func setupSeparatorTop(constraints: inout [NSLayoutConstraint]) {
        self.separatorTop.translatesAutoresizingMaskIntoConstraints = false
        self.separatorTop.boxType = .separator
        self.addSubview(self.separatorTop)

        constraints.append(NSLayoutConstraint(item: self.separatorTop,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.popUpButtonSendingApp,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 14.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.separatorTop,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.separatorTop,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 0.0))

    }

    func setupSeparatorBottom(constraints: inout [NSLayoutConstraint]) {
        self.separatorBottom.translatesAutoresizingMaskIntoConstraints = false
        self.separatorBottom.boxType = .separator
        self.addSubview(self.separatorBottom)

        constraints.append(NSLayoutConstraint(item: self.separatorBottom,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.textFieldStatus,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 12.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.separatorBottom,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.separatorBottom,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 0.0))

    }

    func setupButtonAdd(constraints: inout [NSLayoutConstraint]) {
        self.buttonAdd.translatesAutoresizingMaskIntoConstraints = false
        self.buttonAdd.bezelStyle = .rounded
        self.buttonAdd.setButtonType(.momentaryPushIn)
        self.buttonAdd.isBordered = true
        self.buttonAdd.isTransparent = false
        self.buttonAdd.title = ButtonTitle.add
        self.buttonAdd.keyEquivalent = "\r"
        self.buttonAdd.target = self
        self.buttonAdd.action = #selector(self.clicked(_:))
        self.buttonAdd.sizeToFit()

        // ---------------------------------------------------------------------
        //  Add Button to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.buttonAdd)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.buttonAdd,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 12.0))

        // Top
        constraints.append(NSLayoutConstraint(item: self.buttonAdd,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.separatorBottom,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 16.0))

        // Bottom
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self.buttonAdd,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 12.0))

        // Width
        constraints.append(NSLayoutConstraint(item: self.buttonAdd,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: self.buttonCancel,
                                              attribute: .width,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }

    func setupPopUpButtonSendingApp(cellView: PayloadCellViewTableView, items: [[String: Any]], constraints: inout [NSLayoutConstraint]) {
        self.popUpButtonSendingApp.translatesAutoresizingMaskIntoConstraints = false
        self.popUpButtonSendingApp.action = #selector(self.selected(_:))
        self.popUpButtonSendingApp.target = self
        self.popUpButtonSendingApp.menu = self.menuForSendingAppliction()
        self.addSubview(self.popUpButtonSendingApp)

        constraints.append(NSLayoutConstraint(item: self.popUpButtonSendingApp,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.imageViewSendingApp,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 6.0))

        constraints.append(NSLayoutConstraint(item: self.imageViewSendingApp,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.popUpButtonSendingApp,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 2.0))

        constraints.append(NSLayoutConstraint(item: self.popUpButtonSendingApp,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.imageViewSendingApp,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 2.0))
    }

    func setupPopUpButtonRecievingApp(cellView: PayloadCellViewTableView, items: [[String: Any]], constraints: inout [NSLayoutConstraint]) {
        self.popUpButtonRecievingApp.translatesAutoresizingMaskIntoConstraints = false
        self.popUpButtonRecievingApp.action = #selector(self.selected(_:))
        self.popUpButtonRecievingApp.target = self
        self.popUpButtonRecievingApp.menu = self.menuForRecievingApplication()
        self.addSubview(self.popUpButtonRecievingApp)

        constraints.append(NSLayoutConstraint(item: self.popUpButtonRecievingApp,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.imageViewRecievingApp,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 6.0))

        constraints.append(NSLayoutConstraint(item: self.imageViewRecievingApp,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.popUpButtonRecievingApp,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 2.0))

        constraints.append(NSLayoutConstraint(item: self.popUpButtonRecievingApp,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.imageViewRecievingApp,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 2.0))
    }

    func setupRadioButtons(cellView: PayloadCellViewTableView, constraints: inout [NSLayoutConstraint]) {

        let radioButtonAllow = NSButton(radioButtonWithTitle: NSLocalizedString("Allow", comment: ""), target: self, action: #selector(self.buttonClicked(_:)))
        radioButtonAllow.identifier = NSUserInterfaceItemIdentifier("radioButtonAllowDeny")
        radioButtonAllow.translatesAutoresizingMaskIntoConstraints = false
        radioButtonAllow.state = .on
        radioButtonAllow.action = #selector(self.checked(_:))
        radioButtonAllow.target = self
        self.addSubview(radioButtonAllow)
        self.radioButtonAllow = radioButtonAllow
        self.height += radioButtonAllow.intrinsicContentSize.height

        let radioButtonDeny = NSButton(radioButtonWithTitle: NSLocalizedString("Deny", comment: ""), target: self, action: #selector(self.buttonClicked(_:)))
        radioButtonDeny.identifier = NSUserInterfaceItemIdentifier("radioButtonAllowDeny")
        radioButtonDeny.translatesAutoresizingMaskIntoConstraints = false
        radioButtonDeny.action = #selector(self.checked(_:))
        radioButtonDeny.target = self
        self.addSubview(radioButtonDeny)
        self.radioButtonDeny = radioButtonDeny

        let centerIndenct = (radioButtonAllow.intrinsicContentSize.width + radioButtonDeny.intrinsicContentSize.width + 6.0) / 2.0

        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: radioButtonAllow,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: centerIndenct))

        constraints.append(NSLayoutConstraint(item: radioButtonAllow,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.popUpButtonSendingApp,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))

        constraints.append(NSLayoutConstraint(item: radioButtonDeny,
                                              attribute: .leading,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: radioButtonAllow,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 6.0))

        constraints.append(NSLayoutConstraint(item: radioButtonDeny,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: radioButtonAllow,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }

    /*
     func setupRadioButtons(cellView: PayloadCellViewTableView, constraints: inout [NSLayoutConstraint]) {

     let buttonNew = NSButton(radioButtonWithTitle: NSLocalizedString("New Row", comment: ""), target: self, action: #selector(self.buttonClicked(_:)))
     buttonNew.identifier = NSUserInterfaceItemIdentifier("radioButton")
     buttonNew.translatesAutoresizingMaskIntoConstraints = false
     buttonNew.state = .on
     self.addSubview(buttonNew)
     self.buttonNew = buttonNew
     self.height += buttonNew.intrinsicContentSize.height

     let buttonupdate = NSButton(radioButtonWithTitle: NSLocalizedString("Update Existing Row", comment: ""), target: self, action: #selector(self.buttonClicked(_:)))
     buttonupdate.identifier = NSUserInterfaceItemIdentifier("radioButton")
     buttonupdate.translatesAutoresizingMaskIntoConstraints = false
     buttonupdate.isEnabled = !cellView.tableViewContent.isEmpty
     self.addSubview(buttonupdate)
     self.buttonUpdate = buttonupdate

     constraints.append(NSLayoutConstraint(item: buttonNew,
     attribute: .leading,
     relatedBy: .equal,
     toItem: self,
     attribute: .leading,
     multiplier: 1.0,
     constant: 0.0))

     constraints.append(NSLayoutConstraint(item: buttonNew,
     attribute: .top,
     relatedBy: .equal,
     toItem: self,
     attribute: .top,
     multiplier: 1.0,
     constant: 8.0))
     self.height += 8.0

     constraints.append(NSLayoutConstraint(item: buttonupdate,
     attribute: .leading,
     relatedBy: .equal,
     toItem: self.buttonNew,
     attribute: .trailing,
     multiplier: 1.0,
     constant: 10.0))

     constraints.append(NSLayoutConstraint(item: buttonNew,
     attribute: .centerY,
     relatedBy: .equal,
     toItem: buttonupdate,
     attribute: .centerY,
     multiplier: 1.0,
     constant: 0.0))

     constraints.append(NSLayoutConstraint(item: self,
     attribute: .trailing,
     relatedBy: .greaterThanOrEqual,
     toItem: buttonupdate,
     attribute: .trailing,
     multiplier: 1.0,
     constant: 20.0))
     }

     func setupScrollView(cellView: PayloadCellViewTableView, constraints: inout [NSLayoutConstraint]) {

     guard
     let scrollView = self.scrollView,
     let buttonNew = self.buttonNew,
     let tableView = scrollView.documentView as? NSTableView else { return }
     scrollView.translatesAutoresizingMaskIntoConstraints = false

     if !cellView.tableViewContent.isEmpty {
     tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
     tableView.allowsEmptySelection = false
     for row in cellView.tableViewContent.indices {
     for column in cellView.tableViewColumns.indices {
     let view = tableView.view(atColumn: column, row: row, makeIfNecessary: false)
     if let checkboxView = view as? EditorTableViewCellViewCheckbox {
     checkboxView.checkbox.isEnabled = false
     } else if let textFieldView = view as? EditorTableViewCellViewTextField {
     textFieldView.textField?.isEnabled = false
     }
     }
     }
     }

     tableView.bind(.enabled, to: self, withKeyPath: NSStringFromSelector(#selector(getter: self.updateRow)), options: [.continuouslyUpdatesValue: true])

     self.addSubview(scrollView)

     constraints.append(NSLayoutConstraint(item: scrollView,
     attribute: .leading,
     relatedBy: .equal,
     toItem: self,
     attribute: .leading,
     multiplier: 1.0,
     constant: 0.0))

     constraints.append(NSLayoutConstraint(item: scrollView,
     attribute: .trailing,
     relatedBy: .equal,
     toItem: self,
     attribute: .trailing,
     multiplier: 1.0,
     constant: 0.0))

     constraints.append(NSLayoutConstraint(item: scrollView,
     attribute: .top,
     relatedBy: .equal,
     toItem: buttonNew,
     attribute: .bottom,
     multiplier: 1.0,
     constant: 10.0))
     self.height += 10.0

     constraints.append(NSLayoutConstraint(item: scrollView,
     attribute: .bottom,
     relatedBy: .equal,
     toItem: self,
     attribute: .bottom,
     multiplier: 1.0,
     constant: 0.0))

     constraints.append(NSLayoutConstraint(item: scrollView,
     attribute: .height,
     relatedBy: .equal,
     toItem: nil,
     attribute: .notAnAttribute,
     multiplier: 1.0,
     constant: 100.0))
     self.height += 100.0
     }
     */
}
