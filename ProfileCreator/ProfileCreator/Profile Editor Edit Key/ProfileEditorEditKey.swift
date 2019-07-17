//
//  ProfileEditorEditKey.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

class ProfileEditorEditKey {

    // MARK: -
    // MARK: Weak Variables

    weak var editor: ProfileEditor?

    // MARK: -
    // MARK: Variables

    var window: ProfileEditorEditKeyWindow?

    // MARK: -
    // MARK: Initialization

    init(editor: ProfileEditor) {
        self.editor = editor
    }

    func addKey(forPlaceholder placeholder: PayloadPlaceholder) {
        Swift.print("Adding key for placeholder: \(placeholder.domain)")
        self.prompt(nil, forPlaceholder: placeholder)
    }

    func editKey(_ payloadSubkey: PayloadSubkey, forPlaceholder placeholder: PayloadPlaceholder) {
        Swift.print("Editing key: \(payloadSubkey.key) for placeholder: \(placeholder.domain)")
        self.prompt(payloadSubkey, forPlaceholder: placeholder)
    }

    private func prompt(_ payloadSubkey: PayloadSubkey?, forPlaceholder placeholder: PayloadPlaceholder) {
        guard self.window == nil else {
            Log.shared.error(message: "Another Key Edit Window is already showing", category: String(describing: self))
            return
        }

        guard
            let windowController = self.editor?.profile.windowControllers.first as? ProfileEditorWindowController,
            let window = windowController.window else {
            Log.shared.error(message: "Failed to get the current editor window", category: String(describing: self))
                return
        }

        let contentView = ProfileEditorEditKeyView(payloadSubkey: payloadSubkey, payloadPlaceholder: placeholder, editorWindow: window)
        let sheetWindow = ProfileEditorEditKeyWindow(contentView: contentView)

        window.beginSheet(sheetWindow) { response in
            Swift.print("response: \(response)")
            guard response == .OK else {
                return
            }
        }
    }

}
