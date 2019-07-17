//
//  ValueImportProcessor.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

class ValueImportProcessor {

    // FIMXE: Should add fileUTIs when initializing.

    // MARK: -
    // MARK: Variables

    let identifier: String

    var fileURL: URL?
    var fileUTI: String?
    var subkey: PayloadSubkey?
    var currentValue: Any?
    var allowedFileTypes: [String]?

    // MARK: -
    // MARK: Initialization

    init(identifier: String) {
        self.identifier = identifier
    }

    func addValue(forFile url: URL, toCurrentValue: [Any]?, subkey: PayloadSubkey, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        // Subkey
        self.subkey = subkey

        // Allowed File Types
        self.allowedFileTypes = subkey.allowedFileTypes

        // File UTI
        self.fileURL = url

        // File UTI
        self.fileUTI = url.typeIdentifier

        try self.addValue(toCurrentValue: toCurrentValue, cellView: cellView, completionHandler: completionHandler)
    }

    // Override This
    func addValue(toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {
        // FIXME: Replace all this with a protocol for better control
        fatalError("This must be overridden by the subclass.")
    }
}
