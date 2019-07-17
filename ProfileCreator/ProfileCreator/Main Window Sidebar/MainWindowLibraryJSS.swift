//
//  MainWindowLibrary.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class MainWindowLibraryJSS: MainWindowLibrary {

    // MARK: -
    // MARK: Variables

    // MARK: -
    // MARK: Initialization

    init(outlineViewController: MainWindowOutlineViewController) {
        super.init(title: SidebarGroupTitle.jamf, group: .jamf, groupFolderURL: URL(applicationDirectory: .jamf), outlineViewController: outlineViewController)
    }

    // MARK: -
    // MARK: Instance Functions

    override func newGroup(title: String, identifier: UUID) -> MainWindowLibraryGroup {
        return MainWindowLibraryGroupJSS(title: title, identifier: identifier, parent: self, outlineViewController: self.outlineViewController)
    }

    // MARK: -
    // MARK: Notification Functions

    override func showAlertNewGroup(window: NSWindow) {

        // ---------------------------------------------------------------------
        //  Show add group alert with text field to user
        // ---------------------------------------------------------------------
        let alert = Alert()
        self.alert = alert
        alert.showAlert(message: NSLocalizedString("New Library Group", comment: ""),
                              informativeText: NSLocalizedString("Enter a name for new library group to be created.", comment: ""),
                              window: window,
                              defaultString: nil,
                              placeholderString: nil,
                              firstButtonTitle: ButtonTitle.ok,
                              secondButtonTitle: ButtonTitle.cancel,
                              thirdButtonTitle: nil,
                              firstButtonState: true,
                              sender: self) { title, response in
                                if response == .alertFirstButtonReturn {
                                    self.addGroup(title: title, identifier: UUID(), profileIdentifiers: [], dict: [:], writeToDisk: true)
                                }
        }

        // ---------------------------------------------------------------------
        //  Select the text field in the alert sheet
        // ---------------------------------------------------------------------
        alert.textFieldInput!.selectText(self)
    }
}

class MainWindowLibraryGroupJSS: MainWindowLibraryGroup {

    // MARK: -
    // MARK: Variables

    var jssURL: URL?
    var jssUsername: String?

    // MARK: -
    // MARK: Instance Functions

    override func groupDict() -> [String: Any] {
        var groupDict = super.groupDict()

        // JSS Username
        if let jssUsername = self.jssUsername {
            groupDict[SettingsKey.jssUsername] = jssUsername
        }

        // JSS URL
        if let jssURL = self.jssURL {
            groupDict[SettingsKey.jssURL] = jssURL.absoluteString
        }

        return groupDict
    }
}
