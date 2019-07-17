//
//  Alert.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

struct ButtonTitle {
    static let add = NSLocalizedString("Add", comment: "")
    static let cancel = NSLocalizedString("Cancel", comment: "")
    static let close = NSLocalizedString("Close", comment: "")
    static let delete = NSLocalizedString("Delete", comment: "")
    static let export = NSLocalizedString("Export", comment: "")
    static let ok = NSLocalizedString("OK", comment: "")
    static let save = NSLocalizedString("Save", comment: "")
    static let saveAndClose = NSLocalizedString("Save & Close", comment: "")
    static let importTitle = NSLocalizedString("Import", comment: "")
    static let move = NSLocalizedString("Move", comment: "")
    static let copy = NSLocalizedString("Copy", comment: "")
    static let choose = NSLocalizedString("Choose…", comment: "")
}

class Alert: NSObject {

    var alert = NSAlert()
    var textFieldInput: NSTextField?
    var firstButton: NSButton?
    var secondButton: NSButton?
    var thirdButton: NSButton?

    public func showAlert(message: String,
                          informativeText: String?,
                          window: NSWindow,
                          firstButtonTitle: String,
                          secondButtonTitle: String?,
                          thirdButtonTitle: String?,
                          firstButtonState: Bool,
                          sender: Any?,
                          returnValue: @escaping (NSApplication.ModalResponse) -> Void ) {

        // ---------------------------------------------------------------------
        //  Configure alert
        // ---------------------------------------------------------------------
        self.alert.alertStyle = .informational

        // ---------------------------------------------------------------------
        //  Add buttons
        // ---------------------------------------------------------------------
        self.alert.addButton(withTitle: firstButtonTitle)
        self.firstButton = self.alert.buttons.first
        self.firstButton!.isEnabled = firstButtonState

        if let title = secondButtonTitle {
            self.alert.addButton(withTitle: title)
            self.secondButton = self.alert.buttons[1]
        }

        if let title = thirdButtonTitle {
            self.alert.addButton(withTitle: title)
            self.thirdButton = self.alert.buttons[2]
        }

        // ---------------------------------------------------------------------
        //  Add message
        // ---------------------------------------------------------------------
        self.alert.messageText = message
        if let text = informativeText {
            self.alert.informativeText = text
        }

        // ---------------------------------------------------------------------
        //  Show modal alert in window
        // ---------------------------------------------------------------------
        self.alert.beginSheetModal(for: window) { response in
            returnValue(response)
        }
    }

    public func showAlert(message: String,
                          informativeText: String?,
                          window: NSWindow,
                          defaultString: String?,
                          placeholderString: String?,
                          firstButtonTitle: String,
                          secondButtonTitle: String?,
                          thirdButtonTitle: String?,
                          firstButtonState: Bool,
                          sender: Any?,
                          returnValue: @escaping (String, NSApplication.ModalResponse) -> Void ) {

        // ---------------------------------------------------------------------
        //  Configure alert
        // ---------------------------------------------------------------------
        self.alert.alertStyle = .informational

        // ---------------------------------------------------------------------
        //  Add buttons
        // ---------------------------------------------------------------------
        self.alert.addButton(withTitle: firstButtonTitle)
        self.firstButton = self.alert.buttons.first
        self.firstButton!.isEnabled = firstButtonState

        if let title = secondButtonTitle {
            self.alert.addButton(withTitle: title)
            self.secondButton = self.alert.buttons[1]
        }

        if let title = thirdButtonTitle {
            self.alert.addButton(withTitle: title)
            self.thirdButton = self.alert.buttons[2]
        }

        // ---------------------------------------------------------------------
        //  Add message
        // ---------------------------------------------------------------------
        self.alert.messageText = message
        if let text = informativeText {
            self.alert.informativeText = text
        }

        // ---------------------------------------------------------------------
        //  Add accessory view TextField
        // ---------------------------------------------------------------------
        self.textFieldInput = NSTextField(frame: NSRect(x: 0, y: 0, width: 292, height: 22))
        if sender != nil, let delegate = sender as? NSTextFieldDelegate {
            self.textFieldInput!.delegate = delegate
        }

        if let string = defaultString {
            self.textFieldInput!.stringValue = string
        } else if self.textFieldInput?.delegate != nil {
            self.firstButton!.isEnabled = false
        }

        if let string = placeholderString {
            self.textFieldInput!.placeholderString = string
        }

        self.alert.accessoryView = self.textFieldInput

        // ---------------------------------------------------------------------
        //  Show modal alert in window
        // ---------------------------------------------------------------------
        self.alert.beginSheetModal(for: window) { response in
            returnValue(self.textFieldInput!.stringValue, response)
        }
    }

    func showAlertDelete(message: String,
                         informativeText: String?,
                         window: NSWindow,
                         shouldDelete: @escaping (Bool) -> Void ) {

        // ---------------------------------------------------------------------
        //  Configure alert
        // ---------------------------------------------------------------------
        self.alert.alertStyle = .critical

        // ---------------------------------------------------------------------
        //  Add buttons
        // ---------------------------------------------------------------------
        self.alert.addButton(withTitle: ButtonTitle.cancel)
        self.firstButton = self.alert.buttons.first

        self.alert.addButton(withTitle: ButtonTitle.delete)
        self.secondButton = self.alert.buttons.last

        // ---------------------------------------------------------------------
        //  Add message
        // ---------------------------------------------------------------------
        self.alert.messageText = message
        if let text = informativeText {
            self.alert.informativeText = text
        }

        // ---------------------------------------------------------------------
        //  Show modal alert in window
        // ---------------------------------------------------------------------
        self.alert.beginSheetModal(for: window) { returnCode in
            if returnCode == NSApplication.ModalResponse.alertSecondButtonReturn {
                shouldDelete(true)
            } else {
                shouldDelete(false)
            }
        }
    }
}

extension Alert: NSTextFieldDelegate {

}
