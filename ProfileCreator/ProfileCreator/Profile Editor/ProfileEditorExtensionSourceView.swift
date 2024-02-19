//
//  ProfileEditorSourceView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import Highlightr
import ProfilePayloads

class ProfileEditorSourceView: NSTextView {

    @objc func appearanceChanged(_ notification: Notification?) {
        self.setPayloadString(self.string)
    }

    func setPayloadString(_ string: String) {
        if let highlightr = Highlightr() {
            let theme: String
            if #available(OSX 10.14, *),
                UserDefaults.standard.string(forKey: PreferenceKey.payloadEditorSyntaxHighlightBackgroundColor) == "#ffffff",
                UserDefaults.standard.string(forKey: PreferenceKey.payloadEditorSyntaxHighlightTheme) ?? "kimbie.light" == "kimbie.light" {
                switch self.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
                case .darkAqua?:
                    theme = "kimbie.dark"
                default:
                    theme = "kimbie.light"
                }
            } else {
                theme = UserDefaults.standard.string(forKey: PreferenceKey.payloadEditorSyntaxHighlightTheme) ?? "kimbie.light"
            }
            highlightr.setTheme(to: theme)
            if let highlightedCode = highlightr.highlight(string, as: "xml") {
                self.textStorage?.setAttributedString(highlightedCode)
            } else {
                self.string = string
            }
        } else {
            self.string = string
        }
    }
}

extension ProfileEditor {

    func updateSourceViewManifest() {
        guard let payload = self.selectedPayloadPlaceholder?.payload else { return }

        if self.selectedPayloadView != .source {
            self.select(view: EditorViewTag.source.rawValue)
            if let editorWindowController = self.scrollView.window?.windowController as? ProfileEditorWindowController {
                guard let toolbarItem = editorWindowController.toolbarItemView?.toolbarItem as? NSToolbarItemGroup else { return }

                toolbarItem.setSelected(true, at: EditorViewTag.source.rawValue)
            }
        }
        self.setPayloadContent(payload.manifestDict)
    }

    func updateSourceView(payloadPlaceholder: PayloadPlaceholder) {

        var payloadContent = [String: Any]()

        if payloadPlaceholder.payloadType == .custom, let payloadCustom = payloadPlaceholder.payload as? PayloadCustom {
            if
                let payloadCustomContents = payloadCustom.payloadContent,
                self.selectedPayloadIndex < payloadCustomContents.count {
                payloadContent = payloadCustomContents[self.selectedPayloadIndex]
                payloadContent.removeValue(forKey: PayloadKey.payloadEnabled)
            }
        } else {
            let profileExport = ProfileExport(exportSettings: self.profile.settings)
            profileExport.ignoreErrorInvalidValue = true
            profileExport.ignoreSave = true

            do {
                payloadContent = try profileExport.content(forPayload: payloadPlaceholder.payload, payloadIndex: self.selectedPayloadIndex)
                profileExport.updateManagedPreferences(domain: payloadPlaceholder.domain, type: payloadPlaceholder.payloadType, payloadContent: &payloadContent)
            } catch {
                Log.shared.error(message: "Source view export failed with error: \(error)", category: String(describing: self))
            }
        }

        if
            let backgroundColorString = UserDefaults.standard.string(forKey: PreferenceKey.payloadEditorSyntaxHighlightBackgroundColor),
            let backgroundColor = ValueTransformer(forName: HexColorTransformer.name)?.transformedValue(backgroundColorString) as? NSColor {
            if #available(OSX 10.14, *) {
                if backgroundColorString == "#ffffff" {
                    self.textView.backgroundColor = NSColor(named: NSColor.Name("controlBackgroundColorCustom")) ?? .controlBackgroundColor
                } else {
                    self.textView.backgroundColor = backgroundColor
                }
            } else {
                self.textView.backgroundColor = backgroundColor
            }
        } else {
            self.textView.backgroundColor = .controlBackgroundColor
        }
        self.textView.drawsBackground = true

        self.setPayloadContent(payloadContent)
    }

    func setPayloadContent(_ payloadContent: [String: Any]) {
        self.getPlistString(dictionary: payloadContent) { string, error in
            if let payloadString = string {
                self.textView.setPayloadString(payloadString)
            } else {
                Log.shared.error(message: "Failed to get payload content as string with error: \(String(describing: error))", category: String(describing: self))
                self.textView.string = ""
            }
        }
    }

    func getPlistString(dictionary: [String: Any], completionHandler: @escaping (String?, Error?) -> Void) {

        let dictionaryData: Data
        do {
            dictionaryData = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
        } catch {
            completionHandler(nil, error)
            return
        }

        // ---------------------------------------------------------------------
        //  Remove the plist header and ending tag
        // ---------------------------------------------------------------------
        var plistString: String?
        if let string = String(data: dictionaryData, encoding: .utf8) {

            // Create a scanner from the file contents
            let scanner = Scanner(string: string)

            // Move to the first line containing '<dict>'
            _ = scanner.scanUpToString("<dict>")

            // Add all lines until a line contains '</plist>' to scannerString
            if let scannerString = scanner.scanUpToString("</plist>") {

                // If the scannerString is not empty, replace the plistString
                if !scannerString.isEmpty {
                    plistString = scannerString
                }
            }
        }

        completionHandler(plistString, nil)
    }
}
