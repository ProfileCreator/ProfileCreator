//
//  ValueImportProcessorDockStaticApps.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ValueImportProcessorDockStaticApps: ValueImportProcessor {

    init() {
        super.init(identifier: "com.apple.dock.static-apps")
    }

    override func addValue(toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        // Verify it's an application bundle
        guard
            let fileUTI = self.fileUTI,
            NSWorkspace.shared.type(fileUTI, conformsToType: kUTTypeApplicationBundle as String),
            let fileURL = self.fileURL,
            let applicationBundle = Bundle(url: fileURL) else {
                completionHandler(nil)
                return
        }

        let bundlePath = applicationBundle.bundlePath
        let bundleLabel = applicationBundle.bundleDisplayName?.deletingSuffix(".app") ?? applicationBundle.bundleURL.deletingPathExtension().lastPathComponent

        // Check if this bundle path is already added
        if let currentValue = toCurrentValue as? [[String: Any]], currentValue.contains(where: {
            if let tileData = $0["tile-data"] as? [String: Any],
            let fileData = tileData["file-data"] as? [String: Any],
            let filePath = fileData["_CFURLString"] as? String {
                return filePath == bundlePath
            } else {
                return false
            }
        }) {
            completionHandler(nil)
            return
        }

        var value = [String: Any]()

        // "tile-type"
        value["tile-type"] = "file-tile"

        var tileData = [String: Any]()

        // "tile-data.label"
        tileData["label"] = bundleLabel

        // "tile-data.file-data._CFURLString"
        tileData["file-data"] = ["_CFURLString": bundlePath]

        // "tile-data
        value["tile-data"] = tileData

        if var currentValue = toCurrentValue as? [[String: Any]] {
            currentValue.append(value)
            completionHandler(currentValue)
        } else {
            completionHandler([value])
        }
    }
}
