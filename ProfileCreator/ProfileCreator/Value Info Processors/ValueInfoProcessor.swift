//
//  ValueInfoProcessor.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

class ValueInfoProcessor {

    // MARK: -
    // MARK: Variables

    let identifier: String
    var fileURL: URL?
    var fileUTI: String?
    var fileData: Data?
    var subkey: PayloadSubkey?

    // MARK: -
    // MARK: Initialization

    init() {
        self.identifier = "default"
    }

    init(withIdentifier identifier: String) {
        self.identifier = identifier
    }

    func valueInfo(forURL url: URL, subkey: PayloadSubkey) -> ValueInfo? {

        // Subkey
        self.subkey = subkey

        // File URL
        self.fileURL = url

        // File UTI
        self.fileUTI = url.typeIdentifier

        // File Data
        guard let fileData = self.valueData(forURL: url) else { return nil }
        self.fileData = fileData

        // Value Info
        return self.valueInfo(forData: fileData)
    }

    func valueInfo(forData data: Data, subkey: PayloadSubkey) -> ValueInfo? {

        // Subkey
        self.subkey = subkey

        // File URL
        // -

        // File UTI
        if let allowedFileTypes = subkey.allowedFileTypes, allowedFileTypes.count == 1, let fileUTI = allowedFileTypes.first {
            self.fileUTI = fileUTI
        }

        // File Data
        self.fileData = data

        // Value Info
        return self.valueInfo(forData: data)
    }

    func valueData(forURL url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            Log.shared.error(message: "Failed to initialize data from file at path: \(url.path)", category: String(describing: self))
            return nil
        }
    }

    func valueInfo(forData data: Data) -> ValueInfo? {
        var valueInfo = ValueInfo()

        // Title
        valueInfo.title = NSLocalizedString("Unknown Item", comment: "")

        // Top
        valueInfo.topLabel = NSLocalizedString("File Size", comment: "")
        valueInfo.topContent = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: ByteCountFormatter.CountStyle.file)

        // Icon
        valueInfo.icon = NSWorkspace.shared.icon(forFileType: kUTTypeData as String)

        return valueInfo
    }
}
