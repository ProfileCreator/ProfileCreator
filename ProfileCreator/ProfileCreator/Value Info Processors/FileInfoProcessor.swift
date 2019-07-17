//
//  FileInfoProcessor.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class FileInfoProcessor {

    // MARK: -
    // MARK: Variables

    let fileURL: URL?
    let fileUTI: String

    var fileInfoVar: FileInfo?
    var fileAttributes: [FileAttributeKey: Any]?
    var fileTitle: String?
    var fileDataVar: Data?

    // MARK: -
    // MARK: Initialization

    init?(data: Data, fileInfo: [String: Any]) {

        // File UTI
        if let fileUTI = fileInfo[FileInfoKey.fileUTI] as? String {
            self.fileUTI = fileUTI
        } else { return nil }

        // File DataVar
        self.fileDataVar = data

        // File URL
        if let filePath = fileInfo[FileInfoKey.fileURL] as? String {
            self.fileURL = URL(fileURLWithPath: filePath)
            self.fileTitle = self.fileURL?.lastPathComponent
        } else {
            self.fileURL = nil
            self.fileTitle = nil
        }

        // File Info
        if let fileInfoDict = fileInfo[FileInfoKey.fileInfoView] as? [String: Any] {
            if let fileInfo = FileInfo(infoDict: fileInfoDict, backupIcon: NSWorkspace.shared.icon(forFileType: self.fileUTI)) {
                self.fileInfoVar = fileInfo
            } else {
                Log.shared.error(message: "Failed to create FileInfo from dictionary: \(fileInfoDict)", category: String(describing: self))
            }
        }
    }

    init(fileURL: URL) {

        // Restore

        // File URL
        self.fileURL = fileURL

        // File UTI
        if let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileURL.pathExtension as CFString, nil) {
            self.fileUTI = unmanagedFileUTI.takeRetainedValue() as String
        } else {
            self.fileUTI = kUTTypeItem as String
        }

        // File Attributes
        self.fileAttributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)

        // File Title
        self.fileTitle = fileURL.lastPathComponent
    }

    // MARK: -
    // MARK: Functions

    func fileData() -> Data? {
        if let fileURL = self.fileURL {
            return try? Data(contentsOf: fileURL)
        } else {
            return self.fileDataVar
        }
    }

    func fileInfoDict() -> [String: Any] {
        var fileInfoDict = [String: Any]()

        // File ITU
        fileInfoDict[FileInfoKey.fileUTI] = self.fileUTI

        // File URL
        if let fileURL = self.fileURL {
            fileInfoDict[FileInfoKey.fileURL] = fileURL.path
        }

        // File Attributes
        if let fileAttributes = self.fileAttributes {
            fileInfoDict[FileInfoKey.fileAttributes] = fileAttributes
        }

        // File Info
        let fileInfo = self.fileInfo()
        fileInfoDict[FileInfoKey.fileInfoView] = fileInfo.infoDict()

        return fileInfoDict
    }

    func fileInfo() -> FileInfo {

        if let fileInfoVar = self.fileInfoVar {
            return fileInfoVar
        } else {

            var title = ""
            var topLabel = ""
            var topContent = ""
            var centerLabel: String?
            var centerContent: String?
            var icon: NSImage?

            if let fileURL = self.fileURL {

                // Title
                title = self.fileTitle ?? fileURL.lastPathComponent

                // Top
                topLabel = NSLocalizedString("Path", comment: "")
                topContent = fileURL.path

                // Center
                if
                    let fileAttributes = self.fileAttributes,
                    let fileSize = fileAttributes[.size] as? Int64 {
                    centerLabel = NSLocalizedString("Size", comment: "")
                    centerContent = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: ByteCountFormatter.CountStyle.file)
                }

                // Icon
                icon = NSWorkspace.shared.icon(forFileType: self.fileUTI)
                // icon = NSWorkspace.shared.icon(forFile: fileURL.path)
            }

            // FIXME: Need to fix defaults here
            self.fileInfoVar = FileInfo(title: title,
                                        topLabel: topLabel,
                                        topContent: topContent,
                                        topError: false,
                                        centerLabel: centerLabel,
                                        centerContent: centerContent,
                                        centerError: false,
                                        bottomLabel: nil,
                                        bottomContent: nil,
                                        bottomError: false,
                                        icon: icon)
            return self.fileInfoVar!
        }
    }
}
