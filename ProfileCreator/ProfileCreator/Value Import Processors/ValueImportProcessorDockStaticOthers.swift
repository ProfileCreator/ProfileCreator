//
//  ValueImportProcessorDockStaticOthers.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ValueImportProcessorDockStaticOthers: ValueImportProcessor {

    init() {
        super.init(identifier: "com.apple.dock.static-others")
    }

    override func addValue(toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        // File, Directory or URL
        guard let fileUTI = self.fileUTI, let fileURL = self.fileURL else { completionHandler(nil); return }

        // Directory
        if NSWorkspace.shared.type(fileUTI, conformsToType: kUTTypeDirectory as String) {
            try self.addFolder(fileURL, toCurrentValue: toCurrentValue, cellView: cellView, completionHandler: completionHandler)

            // File
        } else {
            try self.addFile(fileURL, toCurrentValue: toCurrentValue, cellView: cellView, completionHandler: completionHandler)
        }
    }

    func addFolder(_ folderURL: URL, toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        var folderPath: String
        if
            3 <= folderURL.pathComponents.count,
            folderURL.pathComponents[1] == "Users",
            !folderURL.path.hasPrefix("/Users/Shared") {
            folderPath = "~/" + folderURL.pathComponents.dropFirst(3).joined(separator: "/")
        } else {
            folderPath = folderURL.path
        }

        var value = [String: Any]()
        var tileData = [String: Any]()

        if folderPath.hasPrefix("~") {

            if let currentValue = toCurrentValue as? [[String: Any]], currentValue.contains(where: {
                if let tileData = $0["tile-data"] as? [String: Any],
                    let filePath = tileData["home directory relative"] as? String {
                    return filePath == folderPath
                } else {
                    return false
                }
            }) {
                completionHandler(nil)
                return
            }

            tileData["home directory relative"] = folderPath

        } else {

            if let currentValue = toCurrentValue as? [[String: Any]], currentValue.contains(where: {
                if let tileData = $0["tile-data"] as? [String: Any],
                    let fileData = tileData["file-data"] as? [String: Any],
                    let filePath = fileData["_CFURLString"] as? String {
                    return filePath == folderURL.path
                } else {
                    return false
                }
            }) {
                completionHandler(nil)
                return
            }

            tileData["file-data"] = ["_CFURLString": folderPath]
        }

        // "tile-type"
        value["tile-type"] = "directory-tile"

        // "tile-data.label"
        tileData["label"] = folderURL.lastPathComponent

        // "tile-data
        value["tile-data"] = tileData

        if var currentValue = toCurrentValue as? [[String: Any]] {
            currentValue.append(value)
            completionHandler(currentValue)
        } else {
            completionHandler([value])
        }
    }

    func addFile(_ fileURL: URL, toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        // Check if this folder path is already added
        if let currentValue = toCurrentValue as? [[String: Any]], currentValue.contains(where: {
            if let tileData = $0["tile-data"] as? [String: Any],
                let fileData = tileData["file-data"] as? [String: Any],
                let filePath = fileData["_CFURLString"] as? String {
                return filePath == fileURL.path
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
        tileData["label"] = fileURL.lastPathComponent

        // "tile-data.file-data._CFURLString"
        tileData["file-data"] = ["_CFURLString": fileURL.path]

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
