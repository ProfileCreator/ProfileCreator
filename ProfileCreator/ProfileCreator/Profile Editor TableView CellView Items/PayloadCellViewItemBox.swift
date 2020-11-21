//
//  PayloadCellViewItemPopUpButton.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class BoxView: NSView {
    var color = NSColor.lightGray.withAlphaComponent(0.1)

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        self.color.setFill()
        dirtyRect.fill()
    }
}

class EditorBox {

    class func with(profile: Profile,
                    subkey: PayloadSubkey,
                    indent: Int,
                    constraints: inout [NSLayoutConstraint],
                    cellView: PayloadCellView) -> BoxView? {

        guard let note = subkey.note, !note.isEmpty else {
            return nil
        }

        // ---------------------------------------------------------------------
        //  Create and setup Box
        // ---------------------------------------------------------------------
        let box = BoxView()
        box.translatesAutoresizingMaskIntoConstraints = false

        // ---------------------------------------------------------------------
        //  Add box to cell view
        // ---------------------------------------------------------------------
        cellView.addSubview(box)

        // -------------------------------------------------------------------------
        //  Calculate Indent
        // -------------------------------------------------------------------------
        let indentValue: CGFloat = 8.0 + (16.0 * CGFloat(indent))

        // ---------------------------------------------------------------------
        //  Setup Layout Constraings for Box
        // ---------------------------------------------------------------------
        // Leading
        constraints.append(NSLayoutConstraint(item: box,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: cellView,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: indentValue))

        // Trailing
        constraints.append(NSLayoutConstraint(item: cellView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: box,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))

        // ---------------------------------------------------------------------
        //  Create box line
        // ---------------------------------------------------------------------
        let boxLine = BoxView()
        boxLine.translatesAutoresizingMaskIntoConstraints = false
        boxLine.color = NSColor.lightGray.withAlphaComponent(0.5)

        // ---------------------------------------------------------------------
        //  Add box to cell view
        // ---------------------------------------------------------------------
        box.addSubview(boxLine)

        // ---------------------------------------------------------------------
        //  Setup Layout Constraings for Box
        // ---------------------------------------------------------------------
        // Width
        constraints.append(NSLayoutConstraint(item: boxLine,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: 4.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: box,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: boxLine,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Top
        constraints.append(NSLayoutConstraint(item: box,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: boxLine,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Bottom
        constraints.append(NSLayoutConstraint(item: box,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: boxLine,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // ---------------------------------------------------------------------
        //  Create NSTextField
        // ---------------------------------------------------------------------
        let textFieldNote = EditorTextField.note(note: NSLocalizedString("Note", comment: ""), indent: indent, cellView: cellView)
        textFieldNote.textColor = .labelColor
        textFieldNote.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize(for: .regular))

        let textFieldNoteMessage = EditorTextField.note(note: note, indent: indent, cellView: cellView)
        textFieldNoteMessage.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth - (indentValue + 8.0 + 6.0 + 4.0 + 4.0)

        // ---------------------------------------------------------------------
        //  Add text field to box
        // ---------------------------------------------------------------------
        box.addSubview(textFieldNote)
        box.addSubview(textFieldNoteMessage)

        // ---------------------------------------------------------------------
        //  Setup Layout Constraings for Box
        // ---------------------------------------------------------------------
        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldNote,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: boxLine,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 6.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldNoteMessage,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: boxLine,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 6.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: box,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textFieldNote,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 4.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: box,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textFieldNoteMessage,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 3.0))

        // Top
        constraints.append(NSLayoutConstraint(item: textFieldNote,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: box,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: 3.0))

        // Top
        constraints.append(NSLayoutConstraint(item: textFieldNoteMessage,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: textFieldNote,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 3.0))

        // Bottom
        constraints.append(NSLayoutConstraint(item: box,
                                              attribute: .bottom,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: textFieldNoteMessage,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 6.0))

        cellView.updateHeight(3.0)
        cellView.updateHeight(textFieldNote.intrinsicContentSize.height)
        cellView.updateHeight(3.0)
        cellView.updateHeight(textFieldNoteMessage.intrinsicContentSize.height)
        cellView.updateHeight(6.0)

        return box
    }
}
