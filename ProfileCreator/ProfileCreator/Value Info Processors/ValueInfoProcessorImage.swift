//
//  ValueInfoProcessorImage.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension Data {
    // https://stackoverflow.com/a/45305316
    private static let utiTypeSignatures: [UInt8: CFString] = [
            0xFF: kUTTypeJPEG,
            0x89: kUTTypePNG,
            0x47: kUTTypeGIF,
            0x49: kUTTypeTIFF,
            0x4D: kUTTypeTIFF,
            0x25: kUTTypePDF
    ]

    var imageUTI: CFString? {
        var c: UInt8 = 0
        copyBytes(to: &c, count: 1)
        return Data.utiTypeSignatures[c]
    }

    var imageTypeName: String? {
        guard let imageUTI = self.imageUTI else { return nil }
        switch imageUTI {
        case kUTTypeJPEG:
            return "JPEG"
        case kUTTypePNG:
            return "PNG"
        case kUTTypeGIF:
            return "GIF"
        case kUTTypeTIFF:
            return "TIFF"
        case kUTTypePDF:
            return "PDF"
        default:
            return nil
        }
    }
}

class ValueInfoProcessorImage: ValueInfoProcessor {

    // MARK: -
    // MARK: Intialization

    override init() {
        super.init(withIdentifier: "image")
    }

    override func valueInfo(forData data: Data) -> ValueInfo? {

        guard
            let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else { return nil }

        var valueInfo = ValueInfo()

        // Title
        if let imageType = data.imageTypeName as String? {
            valueInfo.title = imageType + NSLocalizedString(" Image", comment: "")
        } else {
            valueInfo.title = NSLocalizedString("Unknown Image Type", comment: "")
        }

        // Center
        valueInfo.topLabel = NSLocalizedString("File Size", comment: "")
        valueInfo.topContent = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: ByteCountFormatter.CountStyle.file)

        // Bottom
        if #available(OSX 10.13, *) {
            if let imageHeight = imageProperties[kCGImagePropertyHeight as String] as? Int,
                let imageWidth = imageProperties[kCGImagePropertyWidth as String] as? Int {
                valueInfo.centerLabel = NSLocalizedString("Image Size", comment: "")
                valueInfo.centerContent = "\(imageWidth) x \(imageHeight)"
            } else if let imageReps = NSBitmapImageRep.imageReps(with: data).first {
                valueInfo.centerLabel = NSLocalizedString("Image Size", comment: "")
                valueInfo.centerContent = "\(imageReps.pixelsWide) x \(imageReps.pixelsHigh)"
            }
        } else {
            if let imageHeight = imageProperties["PixelHeight"] as? Int,
                let imageWidth = imageProperties["PixelWidth"] as? Int {
                valueInfo.centerLabel = NSLocalizedString("Image Size", comment: "")
                valueInfo.centerContent = "\(imageWidth) x \(imageHeight)"
            } else if let imageReps = NSBitmapImageRep.imageReps(with: data).first {
                valueInfo.centerLabel = NSLocalizedString("Image Size", comment: "")
                valueInfo.centerContent = "\(imageReps.pixelsWide) x \(imageReps.pixelsHigh)"
            }
        }

        // Icon
        if let icon = NSImage(data: data) {
            valueInfo.icon = icon
        }

        return valueInfo
    }

}
