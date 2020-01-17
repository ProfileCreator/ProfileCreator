//
//  FileInfoProcessorCertificate.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class FileInfoProcessorFont: FileInfoProcessor {

    override init(fileURL url: URL) {
        super.init(fileURL: url)
    }

    override init?(data: Data, fileInfo: [String: Any]) {
        super.init(data: data, fileInfo: fileInfo)
    }

    // MARK: -
    // MARK: Functions

    override func fileInfo() -> FileInfo {

        if let fileInfoVar = self.fileInfoVar {
            return fileInfoVar
        } else {

            var title = ""
            var topLabel = ""
            var topContent = ""
            var centerLabel: String?
            var centerContent: String?
            var bottomLabel: String?
            var bottomContent: String?
            var icon: NSImage?

            if let fileURL = self.fileURL {

                // Title
                if
                    let fontDataProvider = CGDataProvider(filename: fileURL.path),
                    let font = CGFont(fontDataProvider),
                    let fontName = font.postScriptName as String? {
                    title = fontName
                }

                if let fontMDItem = MDItemCreateWithURL(kCFAllocatorDefault, fileURL as CFURL) {

                    // Top
                    if let type = MDItemCopyAttribute(fontMDItem, kMDItemKind) as? String {
                        topLabel = NSLocalizedString("Type", comment: "")
                        topContent = type
                    }

                    // Center
                    if let version = MDItemCopyAttribute(fontMDItem, kMDItemVersion) as? String {
                        centerLabel = NSLocalizedString("Version", comment: "")
                        centerContent = version.components(separatedBy: ";").first
                    }

                    // Bottom
                    if let publishers = MDItemCopyAttribute(fontMDItem, kMDItemPublishers) as? [String] {
                        bottomLabel = NSLocalizedString("Publisher", comment: "")
                        bottomContent = publishers.joined(separator: ", ")
                    } else if let creator = MDItemCopyAttribute(fontMDItem, kMDItemCreator) as? String {
                        bottomLabel = NSLocalizedString("Creator:", comment: "")
                        bottomContent = creator
                    } else if let copyright = MDItemCopyAttribute(fontMDItem, kMDItemCopyright) as? String {
                        bottomLabel = NSLocalizedString("Copyright", comment: "")
                        bottomContent = copyright
                    }
                }
            }

            // Icon
            icon = NSWorkspace.shared.icon(forFileType: self.fileUTI)

            // Get FileInfo
            self.fileInfoVar = FileInfo(title: title,
                                        topLabel: topLabel,
                                        topContent: topContent,
                                        topError: false,
                                        centerLabel: centerLabel,
                                        centerContent: centerContent,
                                        centerError: false,
                                        bottomLabel: bottomLabel,
                                        bottomContent: bottomContent,
                                        bottomError: false,
                                        icon: icon)
            return self.fileInfoVar!
        }
    }
}
