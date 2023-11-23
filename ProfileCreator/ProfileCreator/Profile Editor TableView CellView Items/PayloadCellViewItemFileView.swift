//
//  PayloadCellViewItemFileView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class EditorFileView {

    class func view(allowedFileTypes: [String]?,
                    constraints: inout [NSLayoutConstraint],
                    cellView: PayloadCellView) -> FileView {

        let fileView = FileView(delegate: cellView, allowedFileTypes: allowedFileTypes, constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add FileView to TableCellView
        // ---------------------------------------------------------------------
        cellView.addSubview(fileView)

        // ---------------------------------------------------------------------
        //  Setup Layout Constraings for FileView
        // ---------------------------------------------------------------------
        // Height
        constraints.append(NSLayoutConstraint(item: fileView,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: 100.0))

        cellView.updateHeight(100.0)

        return fileView
    }
}

class FileView: NSView {

    // MARK: -
    // MARK: Instance Variables

    weak var delegate: PayloadCellView?
    var allowedFileTypes: [String]?

    let imageViewIcon = NSImageView()
    let textFieldTitle = NSTextField()

    // Top
    let textFieldTopContent = NSTextField()
    let textFieldTopLabel = NSTextField()

    // Center
    let textFieldCenterContent = NSTextField()
    let textFieldCenterLabel = NSTextField()

    // Bottom
    let textFieldBottomContent = NSTextField()
    let textFieldBottomLabel = NSTextField()

    // Message
    let textFieldMessage = NSTextField()

    let textFieldPropmpt = NSTextField()

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(delegate: PayloadCellView, allowedFileTypes: [String]?, constraints: inout [NSLayoutConstraint]) {
        super.init(frame: NSRect.zero)

        self.delegate = delegate
        self.allowedFileTypes = allowedFileTypes

        self.translatesAutoresizingMaskIntoConstraints = false
        self.wantsLayer = true
        self.layer?.masksToBounds = true
        self.layer?.borderWidth = 0.5
        self.layer?.borderColor = NSColor.gray.cgColor
        self.registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeURL as String)])

        // Prompt
        self.setupPrompt(constraints: &constraints)

        // ImageView
        self.setupImageView(constraints: &constraints)

        // Title
        self.setupTitle(constraints: &constraints)

        // Description Top
        self.setupLabel(textField: self.textFieldTopLabel, previousLabel: nil, constraints: &constraints)
        self.setupContent(textField: self.textFieldTopContent, label: self.textFieldTopLabel, constraints: &constraints)

        // Description Center
        self.setupLabel(textField: self.textFieldCenterLabel, previousLabel: self.textFieldTopLabel, constraints: &constraints)
        self.setupContent(textField: self.textFieldCenterContent, label: self.textFieldCenterLabel, constraints: &constraints)

        // Description Bottom
        self.setupLabel(textField: self.textFieldBottomLabel, previousLabel: self.textFieldCenterLabel, constraints: &constraints)
        self.setupContent(textField: self.textFieldBottomContent, label: self.textFieldBottomLabel, constraints: &constraints)

        // Message
        self.setupMessage(constraints: &constraints)

        var fileTypes = ""
        if let allowedTypes = self.allowedFileTypes, allowedTypes.count <= 2 {
            for type in allowedTypes {
                var description = "." + type
                if let typeDescription = UTTypeCopyDescription(type as CFString)?.takeUnretainedValue() as String? {
                    description = typeDescription.capitalized
                }

                if fileTypes.isEmpty {
                    fileTypes += description
                } else {
                    fileTypes += " or \(description)"
                }
            }
        }
        if fileTypes.isEmpty {
            self.textFieldPropmpt.stringValue = NSLocalizedString("Add File", comment: "")
        } else {
            self.textFieldPropmpt.stringValue = NSLocalizedString("Add \(fileTypes)", comment: "")
        }
    }

    // MARK: -
    // MARK: Private Functions

    private func containsAcceptedURL(pasteboard: NSPasteboard) -> Bool {
        pasteboard.canReadObject(forClasses: [NSURL.self], options: pasteboardReadingOptions())
    }

    private func pasteboardReadingOptions() -> [NSPasteboard.ReadingOptionKey: Any]? {
        if let allowedFileTypes = self.allowedFileTypes?.filter({ $0.contains(".") }), !allowedFileTypes.isEmpty {
            return [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true,
                    NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes: allowedFileTypes]
        } else {
            return [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true]
        }
    }
}

// MARK: -
// MARK: NSDraggingDestination Functions

extension FileView {
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if self.delegate?.isEnabled ?? false, sender.draggingPasteboard.pasteboardItems?.count == 1 && self.containsAcceptedURL(pasteboard: sender.draggingPasteboard) {
            return NSDragOperation.copy
        }
        return NSDragOperation()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if sender.draggingPasteboard.pasteboardItems?.count == 1 && self.containsAcceptedURL(pasteboard: sender.draggingPasteboard) {
            if
                let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
                let cellView = delegate as? PayloadCellViewFile {

                if 1 < urls.count {
                    cellView.importURLs(urls)
                } else if let url = urls.first {
                    cellView.processFile(atURL: url, forPayloadIndex: nil) { success in
                        if success {
                            cellView.showPrompt(!success)
                        }
                    }
                }
            }
            return true
        }
        return false
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension FileView {

    private func setupPrompt(constraints: inout [NSLayoutConstraint]) {
        self.setup(textField: self.textFieldPropmpt, fontWeight: .regular, fontSize: 15, fontColor: .tertiaryLabelColor)
        self.addSubview(self.textFieldPropmpt)

        // Center X
        constraints.append(NSLayoutConstraint(item: self.textFieldPropmpt,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerX,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Center Y
        constraints.append(NSLayoutConstraint(item: self.textFieldPropmpt,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }

    private func setupImageView(constraints: inout [NSLayoutConstraint]) {
        self.imageViewIcon.translatesAutoresizingMaskIntoConstraints = false
        self.imageViewIcon.imageScaling = .scaleProportionallyUpOrDown
        self.imageViewIcon.setContentHuggingPriority(.required, for: .horizontal)
        self.addSubview(self.imageViewIcon)

        // Top
        constraints.append(NSLayoutConstraint(item: self.imageViewIcon,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: 14.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.imageViewIcon,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 14.0))

        // Bottom
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self.imageViewIcon,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 14.0))

        // Width == Height
        constraints.append(NSLayoutConstraint(item: self.imageViewIcon,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: self.imageViewIcon,
                                              attribute: .height,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }

    private func setupTitle(constraints: inout [NSLayoutConstraint]) {
        self.setup(textField: self.textFieldTitle, fontWeight: .bold, fontSize: 15, fontColor: .labelColor)
        self.addSubview(self.textFieldTitle)

        // Top
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: 11.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.imageViewIcon,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 14.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))

    }

    private func setupLabel(textField: NSTextField, previousLabel: NSTextField?, constraints: inout [NSLayoutConstraint]) {
        self.setup(textField: textField, fontWeight: .medium, fontSize: (NSFont.systemFontSize(for: .small) + 1), fontColor: .secondaryLabelColor)
        textField.setContentCompressionResistancePriority(.required, for: .horizontal)
        textField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.addSubview(textField)

        let topConstraint: CGFloat
        if previousLabel != nil {
            topConstraint = 2

            // Trailing
            constraints.append(NSLayoutConstraint(item: textField,
                                                  attribute: .trailing,
                                                  relatedBy: .equal,
                                                  toItem: previousLabel,
                                                  attribute: .trailing,
                                                  multiplier: 1.0,
                                                  constant: 0.0))
        } else {
            topConstraint = 3
        }

        // Top
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: previousLabel ?? self.textFieldTitle,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: topConstraint))

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.imageViewIcon,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 14.0))
    }

    private func setupMessage(constraints: inout [NSLayoutConstraint]) {
        self.setup(textField: self.textFieldMessage, fontWeight: .medium, fontSize: (NSFont.systemFontSize(for: .small) + 1), fontColor: .secondaryLabelColor)
        self.textFieldMessage.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.textFieldMessage.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.textFieldMessage.lineBreakMode = .byWordWrapping
        self.addSubview(self.textFieldMessage)

        // Top
        constraints.append(NSLayoutConstraint(item: self.textFieldMessage,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 3.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.textFieldMessage,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.imageViewIcon,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 14.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldMessage,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 12.0))
    }

    private func setupContent(textField: NSTextField, label: NSTextField, constraints: inout [NSLayoutConstraint]) {
        self.setup(textField: textField, fontWeight: .regular, fontSize: (NSFont.systemFontSize(for: .small) + 1), fontColor: .secondaryLabelColor)
        self.addSubview(textField)

        // Baseline
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .firstBaseline,
                                              relatedBy: .equal,
                                              toItem: label,
                                              attribute: .firstBaseline,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: label,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textField,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))

    }

    private func setup(textField: NSTextField, fontWeight: NSFont.Weight, fontSize: CGFloat, fontColor: NSColor) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byTruncatingTail
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.font = NSFont.systemFont(ofSize: fontSize, weight: fontWeight)
        textField.textColor = fontColor
    }
}
