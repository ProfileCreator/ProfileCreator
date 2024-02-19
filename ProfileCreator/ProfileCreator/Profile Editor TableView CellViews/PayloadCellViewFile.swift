//
//  PayloadCellViewFile.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewFile: PayloadCellView, ProfileCreatorCellView {

    // MARK: -
    // MARK: Instance Variables

    var fileView: FileView?
    var progressIndicator = NSProgressIndicator()
    var textFieldProgress = NSTextField()
    var imageViewDragDrop = NSImageView()
    let buttonAdd = PayloadButton()
    let buttonRemove = PayloadButton()
    var valueDefault: Data?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(subkey: PayloadSubkey, payloadIndex: Int, enabled: Bool, required: Bool, editor: ProfileEditor) {
        super.init(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: editor)

        // ---------------------------------------------------------------------
        //  Setup Custom View Content
        // ---------------------------------------------------------------------
        self.fileView = EditorFileView.view(allowedFileTypes: subkey.allowedFileTypes, constraints: &self.cellViewConstraints, cellView: self)
        self.setupFileView()
        self.setupButtonAdd()
        self.setupButtonRemove()
        self.setupProgressIndicator()
        self.setupTextFieldProgress()
        self.setupImageViewDragDrop()

        // ---------------------------------------------------------------------
        //  Setup Footer
        // ---------------------------------------------------------------------
        super.setupFooter(belowCustomView: self.buttonAdd)

        // ---------------------------------------------------------------------
        //  Set Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.valueDefault as? Data {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Set Value
        // ---------------------------------------------------------------------
        var valueData: Data?
        if let value = profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) as? Data {
            valueData = value
        } else if let value = self.valueDefault {
            valueData = value
        }

        if let data = valueData, self.processFile(data: data) {
            self.showPrompt(false)
        } else {
            self.showPrompt(true)
        }

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.buttonAdd
        self.trailingKeyView = self.buttonAdd

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.buttonAdd.isEnabled = enable
    }

    // MARK: -
    // MARK: Private Functions

    func showPrompt(_ show: Bool) {
        self.buttonRemove.isHidden = show
        guard let fileView = self.fileView else { return }
        fileView.imageViewIcon.isHidden = show
        fileView.textFieldTitle.isHidden = show
        fileView.textFieldTopLabel.isHidden = show
        fileView.textFieldTopContent.isHidden = show
        fileView.textFieldCenterLabel.isHidden = show
        fileView.textFieldCenterContent.isHidden = show
        fileView.textFieldBottomLabel.isHidden = show
        fileView.textFieldBottomContent.isHidden = show
        fileView.textFieldMessage.isHidden = show
        fileView.textFieldPropmpt.isHidden = !show
    }

    // MARK: -
    // MARK: Button Actions

    @objc private func selectFile(_ button: NSButton) {

        // ---------------------------------------------------------------------
        //  Setup open dialog
        // ---------------------------------------------------------------------
        let openPanel = NSOpenPanel()
        openPanel.prompt = !self.buttonAdd.title.isEmpty ? self.buttonAdd.title : NSLocalizedString("Select File", comment: "")
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = self.subkey.payload?.unique ?? true ? false : true

        // ---------------------------------------------------------------------
        //  Get open dialog allowed file types
        // ---------------------------------------------------------------------
        if let allowedFileTypes = self.subkey.allowedFileTypes {
            openPanel.allowedFileTypes = allowedFileTypes
        }

        if let window = button.window {
            openPanel.beginSheetModal(for: window) { response in
                if response == .OK {
                    if 1 < openPanel.urls.count {
                        self.importURLs(openPanel.urls)
                    } else if let url = openPanel.urls.first {
                        self.processFile(atURL: url, forPayloadIndex: self.payloadIndex) { success in
                            self.showPrompt(!success)
                        }
                    }
                }
            }
        }
    }

    func importURLs(_ urls: [URL]) {
        var importSuccess = true
        let importSize = self.fileSizeForURLs(urls)
        self.showPrompt(withMessage: NSLocalizedString("Are you sure you want to add multiple files?", comment: ""),
                        informativeText: NSLocalizedString("This action will create one payload for each file.\n\nThe combined size for the files is: \(ByteCountFormatter.string(fromByteCount: Int64(importSize), countStyle: .file)).", comment: ""),
                        firstButton: ButtonTitle.cancel,
                        secondButton: ButtonTitle.ok,
                        thirdButton: nil) { response in

            if response == .alertSecondButtonReturn {
                let dispatchQueue = DispatchQueue(label: "serial")
                let dispatchGroup = DispatchGroup()
                let dispatchSemaphore = DispatchSemaphore(value: 0)
                dispatchQueue.async {
                    for (idx, url) in urls.enumerated() {
                        dispatchGroup.enter()

                        if !importSuccess {
                            dispatchSemaphore.signal()
                            dispatchGroup.leave()
                            break
                        }

                        if idx == 0 {
                            DispatchQueue.main.async {
                                self.processFile(atURL: url, forPayloadIndex: self.payloadIndex, verifySize: false) { success in
                                    importSuccess = success
                                    dispatchSemaphore.signal()
                                    dispatchGroup.leave()
                                }
                            }
                        } else if let payload = self.subkey.payload {

                            // Add a new empty payload
                            self.profile.settings.setSettingsDefault(forPayload: payload)

                            // Get the new payload index
                            let index = (self.profile.settings.settingsCount(forDomainIdentifier: payload.domainIdentifier, type: payload.type) - 1)

                            // Enable the new payload
                            self.profile.settings.setPayloadEnabled(self.profile.settings.isEnabled(payload), payload: payload)

                            DispatchQueue.main.async {
                                self.processFile(atURL: url, forPayloadIndex: index, verifySize: false) { success in
                                    importSuccess = success
                                    dispatchSemaphore.signal()
                                    dispatchGroup.leave()
                                }
                            }
                        } else {
                            Log.shared.error(message: "Found no Payload instance for subkey: \(self.subkey.keyPath)", category: "")
                        }
                        dispatchSemaphore.wait()
                    }

                    dispatchGroup.notify(queue: dispatchQueue) {
                        DispatchQueue.main.async {
                            Log.shared.debug(message: "Imported \(urls.count) URLs.", category: String(describing: self))
                            if let placeholder = self.subkey.payload?.placeholder {
                                self.profileEditor.select(payloadPlaceholder: placeholder, ignoreCurrentSelection: true)

                                // FIXME: This is clunky and resource heavy for what it does, should use a notification maybe, or just upadte the specific cellview not BOTH table views
                                if let editorWindowController = self.profile.windowControllers.first as? ProfileEditorWindowController,
                                   let libraryTableViews = editorWindowController.splitView.librarySplitView?.tableViews {
                                    libraryTableViews.reloadTableviews()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @objc private func removeFile(_ button: NSButton) {
        guard let window = button.window else { return }
        let alert = Alert()
        alert.showAlert(message: NSLocalizedString("Remove File?", comment: ""),
                        informativeText: NSLocalizedString("Are you sure you want to remove the current file?", comment: ""),
                        window: window,
                        firstButtonTitle: ButtonTitle.ok,
                        secondButtonTitle: ButtonTitle.cancel,
                        thirdButtonTitle: nil,
                        firstButtonState: true,
                        sender: nil) { response in
                            if response == .alertFirstButtonReturn {
                                self.profile.settings.setValue(Data(), forSubkey: self.subkey, payloadIndex: self.payloadIndex)
                                self.showPrompt(true)
                            }

        }
    }

    // MARK: -
    // MARK: Process File

    private func processFile(data: Data) -> Bool {
        let valueInfoProcessor: ValueInfoProcessor
        if let valueInfoProcessorIdentifier = self.subkey.valueInfoProcessor, let processor = ValueInfoProcessors.shared.processor(withIdentifier: valueInfoProcessorIdentifier) {
            valueInfoProcessor = processor
        } else if let processor = ValueInfoProcessors.shared.processor(forSubkey: self.subkey) {
            valueInfoProcessor = processor
        } else {
            valueInfoProcessor = ValueInfoProcessor()
        }

        if let valueInfo = valueInfoProcessor.valueInfo(forData: data, subkey: self.subkey) {
            return self.updateView(valueInfo: valueInfo)
        }
        return false
    }

    func fileSizeForURLs(_ urls: [URL]) -> UInt64 {
        var fileSize: UInt64 = 0
        for url in urls {
            fileSize += url.fileSize
        }
        return fileSize
    }

    func processFile(atURL url: URL, forPayloadIndex payloadIndex: Int?, verifySize: Bool = true, completionHandler: @escaping (_ success: Bool) -> Void) {

        var allowImport = true
        var alertShow = false
        var alertMessage = ""
        var alertInformativeMessage = ""

        let valueInfoProcessor: ValueInfoProcessor
        if let valueInfoProcessorIdentifier = self.subkey.valueInfoProcessor, let processor = ValueInfoProcessors.shared.processor(withIdentifier: valueInfoProcessorIdentifier) {
            valueInfoProcessor = processor
        } else if let processor = ValueInfoProcessors.shared.processor(forFileAtURL: url) {
            valueInfoProcessor = processor
        } else if let processor = ValueInfoProcessors.shared.processor(forSubkey: self.subkey) {
            valueInfoProcessor = processor
        } else {
            valueInfoProcessor = ValueInfoProcessor()
        }

        guard
            let fileData = valueInfoProcessor.valueData(forURL: url),
            let valueInfo = valueInfoProcessor.valueInfo(forURL: url, subkey: self.subkey) else {
                Log.shared.error(message: "Failed to get value info from url: \(url.path)", category: String(describing: self))
                completionHandler(false)
                return
        }

        // ---------------------------------------------------------------------
        //  Verify the file size
        // ---------------------------------------------------------------------
        if verifySize {
        let fileSize = Int64(url.fileSize)

        // ---------------------------------------------------------------------
        //  Verify if the file size has a maximum requirement
        // ---------------------------------------------------------------------
        if let maxFileSizeBytes = self.subkey.rangeMax as? Int64 {
            if maxFileSizeBytes < fileSize {

                let formatter = ByteCountFormatter()
                formatter.allowsNonnumericFormatting = false
                formatter.countStyle = .file
                formatter.allowedUnits = [.useMB]
                formatter.includesUnit = true
                let fileSizeString = formatter.string(fromByteCount: fileSize)
                let maxFileSizeString = formatter.string(fromByteCount: maxFileSizeBytes)

                allowImport = false
                alertShow = true
                alertMessage = NSLocalizedString("File is too Large", comment: "")
                alertInformativeMessage = NSLocalizedString("Selected file size is: \(fileSizeString).\nMaximum file size is: \(maxFileSizeString)", comment: "")
            }
        } else {
            let formatter = ByteCountFormatter()
            formatter.allowsNonnumericFormatting = false
            formatter.countStyle = .file
            formatter.allowedUnits = [.useMB]
            formatter.includesUnit = false
            let fileSizeString = formatter.string(fromByteCount: fileSize)
            if let fileSizeMB = Double(fileSizeString.replacingOccurrences(of: ",", with: ".")) {
                if 1.0 < fileSizeMB {
                    alertShow = true
                    alertMessage = NSLocalizedString("Large File Size", comment: "")
                    alertInformativeMessage = NSLocalizedString("The file you have selected is: \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)). Are you sure you want to continue?", comment: "")
                } else if fileSizeMB < 0.0 {
                    alertShow = true
                    alertMessage = NSLocalizedString("Unknown File Size", comment: "")
                    alertInformativeMessage = NSLocalizedString("Could not determine the size of the selected file. Are you sure you want to continue?", comment: "")
                }
            } else {
                alertShow = true
                alertMessage = NSLocalizedString("Unknown File Size", comment: "")
                alertInformativeMessage = NSLocalizedString("Could not determine the size of the selected file. Are you sure you want to continue?", comment: "")
            }
        }
        }

        // ---------------------------------------------------------------------
        //  If any issues was found with the file size, show alert
        // ---------------------------------------------------------------------
        if alertShow {
            guard let window = self.buttonAdd.window else { completionHandler(false); return }
            let alert = Alert()
            alert.showAlert(message: alertMessage,
                            informativeText: alertInformativeMessage,
                            window: window,
                            firstButtonTitle: ButtonTitle.ok,
                            secondButtonTitle: (allowImport) ? ButtonTitle.cancel : nil,
                            thirdButtonTitle: nil,
                            firstButtonState: true,
                            sender: nil) { response in
                                if allowImport, response == .alertFirstButtonReturn {
                                    if self.updateView(valueInfo: valueInfo) {
                                        self.profile.settings.setValue(fileData, forSubkey: self.subkey, payloadIndex: payloadIndex ?? self.payloadIndex)
                                    }
                                    completionHandler(true); return
                                } else {
                                    completionHandler(false); return
                                }
            }
        } else {
            if self.updateView(valueInfo: valueInfo) {
                self.profile.settings.setValue(fileData, forSubkey: self.subkey, payloadIndex: payloadIndex ?? self.payloadIndex)
            }
            completionHandler(true); return
        }
    }

    private func updateView(valueInfo: ValueInfo) -> Bool {
        guard let fileView = self.fileView else { return false }

        fileView.textFieldTitle.stringValue = valueInfo.title ?? ""

        // Top
        fileView.textFieldTopLabel.stringValue = valueInfo.topLabel ?? ""
        fileView.textFieldTopContent.stringValue = valueInfo.topContent ?? ""
        if valueInfo.topError {
            fileView.textFieldTopLabel.textColor = .systemRed
            fileView.textFieldTopContent.textColor = .systemRed
        } else {
            fileView.textFieldTopLabel.textColor = .secondaryLabelColor
            fileView.textFieldTopContent.textColor = .tertiaryLabelColor
        }

        // Center
        fileView.textFieldCenterLabel.stringValue = valueInfo.centerLabel ?? ""
        fileView.textFieldCenterContent.stringValue = valueInfo.centerContent ?? ""
        if valueInfo.centerError {
            fileView.textFieldCenterLabel.textColor = .systemRed
            fileView.textFieldCenterContent.textColor = .systemRed
        } else {
            fileView.textFieldCenterLabel.textColor = .secondaryLabelColor
            fileView.textFieldCenterContent.textColor = .tertiaryLabelColor
        }

        // Bottom
        fileView.textFieldBottomLabel.stringValue = valueInfo.bottomLabel ?? ""
        fileView.textFieldBottomContent.stringValue = valueInfo.bottomContent ?? ""
        if valueInfo.bottomError {
            fileView.textFieldBottomLabel.textColor = .systemRed
            fileView.textFieldBottomContent.textColor = .systemRed
        } else {
            fileView.textFieldBottomLabel.textColor = .secondaryLabelColor
            fileView.textFieldBottomContent.textColor = .tertiaryLabelColor
        }

        // Message
        fileView.textFieldMessage.stringValue = valueInfo.message ?? ""

        // Icon
        fileView.imageViewIcon.image = valueInfo.icon

        return true
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewFile {

    private func setupFileView() {
        guard let fileView = self.fileView else { return }

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Below
        self.addConstraints(forViewBelow: fileView)

        // Leading
        self.addConstraints(forViewLeading: fileView)

        // Trailing
        self.addConstraints(forViewTrailing: fileView)
    }

    private func setupButtonAdd() {
        guard let fileView = self.fileView else { return }

        self.buttonAdd.translatesAutoresizingMaskIntoConstraints = false
        self.buttonAdd.bezelStyle = .rounded
        self.buttonAdd.setButtonType(.momentaryPushIn)
        self.buttonAdd.isBordered = true
        self.buttonAdd.isTransparent = false
        self.buttonAdd.title = NSLocalizedString("Add", comment: "")
        self.buttonAdd.target = self
        self.buttonAdd.action = #selector(self.selectFile(_:))
        self.buttonAdd.sizeToFit()
        self.buttonAdd.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        // ---------------------------------------------------------------------
        //  Add Button to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.buttonAdd)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Leading
        self.addConstraints(forViewLeading: self.buttonAdd)

        // Top
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.buttonAdd,
                                                           attribute: .top,
                                                           relatedBy: .equal,
                                                           toItem: fileView,
                                                           attribute: .bottom,
                                                           multiplier: 1.0,
                                                           constant: 8.0))

        self.updateHeight((8 + self.buttonAdd.intrinsicContentSize.height))
    }

    private func setupButtonRemove() {
        self.buttonRemove.translatesAutoresizingMaskIntoConstraints = false
        self.buttonRemove.bezelStyle = .rounded
        self.buttonRemove.setButtonType(.momentaryPushIn)
        self.buttonRemove.isBordered = true
        self.buttonRemove.isTransparent = false
        self.buttonRemove.title = NSLocalizedString("Remove", comment: "")
        self.buttonRemove.target = self
        self.buttonRemove.action = #selector(self.removeFile(_:))
        self.buttonRemove.sizeToFit()
        self.buttonRemove.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        // ---------------------------------------------------------------------
        //  Add Button to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.buttonRemove)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Leading
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.buttonRemove,
                                                           attribute: .leading,
                                                           relatedBy: .equal,
                                                           toItem: self.buttonAdd,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 4.0))

        // Center
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.buttonRemove,
                                                           attribute: .centerY,
                                                           relatedBy: .equal,
                                                           toItem: self.buttonAdd,
                                                           attribute: .centerY,
                                                           multiplier: 1.0,
                                                           constant: 0.0))
    }

    private func setupProgressIndicator() {
        self.progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.progressIndicator.style = .spinning
        self.progressIndicator.controlSize = .small
        self.progressIndicator.isIndeterminate = true
        self.progressIndicator.isDisplayedWhenStopped = false

        // ---------------------------------------------------------------------
        //  Add ProgressIndicator to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.progressIndicator)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Leading
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.progressIndicator,
                                                           attribute: .leading,
                                                           relatedBy: .equal,
                                                           toItem: self.buttonAdd,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 6.0))

        // Center
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.buttonAdd,
                                                           attribute: .centerY,
                                                           relatedBy: .equal,
                                                           toItem: self.progressIndicator,
                                                           attribute: .centerY,
                                                           multiplier: 1.0,
                                                           constant: 0.0))

    }

    private func setupTextFieldProgress() {
        self.textFieldProgress.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldProgress.lineBreakMode = .byWordWrapping
        self.textFieldProgress.isBordered = false
        self.textFieldProgress.isBezeled = false
        self.textFieldProgress.drawsBackground = false
        self.textFieldProgress.isEditable = false
        self.textFieldProgress.isSelectable = false
        self.textFieldProgress.textColor = .secondaryLabelColor
        self.textFieldProgress.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular), weight: .regular)
        self.textFieldProgress.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
        self.textFieldProgress.stringValue = ""
        self.textFieldProgress.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.textFieldProgress)

        // Leading
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.textFieldProgress,
                                                           attribute: .leading,
                                                           relatedBy: .equal,
                                                           toItem: self.progressIndicator,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 6.0))
        // Trailing
        // self.addConstraints(forViewTrailing: self.textFieldProgress)

        // Center
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.textFieldProgress,
                                                           attribute: .centerY,
                                                           relatedBy: .equal,
                                                           toItem: self.progressIndicator,
                                                           attribute: .centerY,
                                                           multiplier: 1.0,
                                                           constant: 0.0))
    }

    private func setupImageViewDragDrop() {
        self.imageViewDragDrop.translatesAutoresizingMaskIntoConstraints = false
        self.imageViewDragDrop.image = NSImage(named: "DragDrop")
        self.imageViewDragDrop.imageScaling = .scaleProportionallyUpOrDown
        self.imageViewDragDrop.setContentHuggingPriority(.required, for: .horizontal)
        self.imageViewDragDrop.toolTip = NSLocalizedString("This payload key supports Drag and Drop", comment: "")
        self.imageViewDragDrop.isHidden = false // self.valueInfoProcessor == nil

        // ---------------------------------------------------------------------
        //  Add ImageView to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.imageViewDragDrop)

        // Height
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.imageViewDragDrop,
                                                           attribute: .height,
                                                           relatedBy: .equal,
                                                           toItem: nil,
                                                           attribute: .notAnAttribute,
                                                           multiplier: 1.0,
                                                           constant: 20.0))

        // Width
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.imageViewDragDrop,
                                                           attribute: .width,
                                                           relatedBy: .equal,
                                                           toItem: nil,
                                                           attribute: .notAnAttribute,
                                                           multiplier: 1.0,
                                                           constant: 30.0))

        // Center
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.progressIndicator,
                                                           attribute: .centerY,
                                                           relatedBy: .equal,
                                                           toItem: self.imageViewDragDrop,
                                                           attribute: .centerY,
                                                           multiplier: 1.0,
                                                           constant: 2.0))

        // Leading
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.imageViewDragDrop,
                                                           attribute: .leading,
                                                           relatedBy: .greaterThanOrEqual,
                                                           toItem: self.textFieldProgress,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 6.0))

        // Trailing
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.imageViewDragDrop,
                                                           attribute: .trailing,
                                                           relatedBy: .equal,
                                                           toItem: self.fileView,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 2.0))
    }
}
