//
//  FileInfoProcessorCertificate.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class FileInfoProcessorImage: FileInfoProcessor {

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
                title = self.fileTitle ?? fileURL.lastPathComponent

                // Top
                topLabel = NSLocalizedString("Path", comment: "")
                topContent = fileURL.path

                // Center
                if
                    let fileAttributes = self.fileAttributes,
                    let fileSize = fileAttributes[.size] as? Int64 {
                    centerLabel = NSLocalizedString("File Size", comment: "")
                    centerContent = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: ByteCountFormatter.CountStyle.file)
                }

                // Bottom
                if let imageReps = NSBitmapImageRep.imageReps(withContentsOf: fileURL)?.first {
                    bottomLabel = NSLocalizedString("Image Size", comment: "")
                    bottomContent = "\(imageReps.pixelsWide) x \(imageReps.pixelsHigh)"
                }

                // Icon
                if let image = NSImage(contentsOf: fileURL) {
                    icon = image
                } else {
                    icon = NSWorkspace.shared.icon(forFileType: self.fileUTI)
                }
            }

            // FIXME: Need to fix defaults here
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
