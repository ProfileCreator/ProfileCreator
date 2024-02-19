//
//  ValueImportProcessorApplicationAccessWhiteList.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

// swiftlint:disable:next inclusive_language
class ValueImportProcessorApplicationAccessWhiteList: ValueImportProcessor {

    init() {
        super.init(identifier: "com.apple.applicationaccess.new.whiteList")
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

        guard let bundleIdentifier = applicationBundle.bundleIdentifier else {
            throw ValueImportError("The file: \"\(self.fileURL?.lastPathComponent ?? "Unknown File")\" does not seem to be a valid application bundle.")
        }

        // Check if this bundle identifier is already added
        if let currentValue = toCurrentValue as? [[String: Any]], currentValue.contains(where: { $0["bundleID"] as? String == bundleIdentifier }) {
            completionHandler(nil)
            return
        }

        guard let designatedCodeRequirementData = applicationBundle.designatedCodeRequirementData else {
            throw ValueImportError("The file: \"\(self.fileURL?.lastPathComponent ?? "Unknown File")\" did not have a designated code requirement for it's code signature, and cannot be used.")
        }

        var value = [String: Any]()

        // whiteList.whiteListItem.appID
        value["appID"] = designatedCodeRequirementData

        // whiteList.whiteListItem.bundleID
        value["bundleID"] = bundleIdentifier

        // whiteList.whiteListItem.displayName
        value["displayName"] = applicationBundle.bundleDisplayName ?? applicationBundle.bundleName ?? ""

        // whiteList.whiteListItem.detachedSignature
        // FIXME: Not Implemented

        // whiteList.whiteListItem.appStore
        value["appStore"] = false

        // whiteList.whiteListItem.disabled
        value["disabled"] = false

        // whiteList.whiteListItem.subApps
        if let subApps = self.subApps(forBundle: applicationBundle) {
            value["subApps"] = subApps
        }

        if var currentValue = toCurrentValue as? [[String: Any]] {
            currentValue.append(value)
            completionHandler(currentValue)
        } else {
            completionHandler([value])
        }
    }

    func subApps(forBundle bundle: Bundle) -> [[String: Any]]? {
        guard let bundleExecutableURL = bundle.executableURL?.absoluteURL else { return nil }
        var subApps = [[String: Any]]()
        if let enumerator = FileManager.default.enumerator(at: bundle.bundleURL, includingPropertiesForKeys: nil) {
            for url in enumerator {
                guard let url = url as? URL else { continue }
                guard let fileResourceValues = try? url.resourceValues(forKeys: Set([.isSymbolicLinkKey])) else { continue }
                if fileResourceValues.isSymbolicLink == true {
                    enumerator.skipDescendants()
                } else if url.isMachOExecutable == true && url != bundleExecutableURL {
                    guard let designatedCodeRequirementData = SecRequirementCopyData(forURL: url) else { continue }

                    var bundleID: String

                    if let bundle = Bundle(url: url) {
                        if let bundleIdentifier = bundle.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as? String ?? bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String {
                            bundleID = bundleIdentifier
                        } else {
                            let bundleExecutable = bundle.object(forInfoDictionaryKey: kCFBundleExecutableKey as String) as? String ?? url.lastPathComponent
                            bundleID = "com.unknown." + bundleExecutable
                        }
                    } else {
                        bundleID = "com.unknown." + url.lastPathComponent
                    }

                    var value = [String: Any]()

                    // whiteList.whiteListItem.subApps.appID
                    value["appID"] = designatedCodeRequirementData

                    // whiteList.whiteListItem.subApps.bundleID
                    value["bundleID"] = bundleID

                    // displayName
                    value["displayName"] = url.lastPathComponent

                    subApps.append(value)
                }
            }
        }

        if !subApps.isEmpty {
            return subApps
        }

        return nil
    }
}

public enum Magic: UInt32 {
    case magic64 = 0xFEEDFACF
    case cigam64 = 0xCFFAEDFE
}

extension Data {
    func uint32Value(atOffset: Int, withMagic magic: Magic) -> UInt32? {
        let offset = (atOffset * 4)
        switch magic {
        case .cigam64:
            return UInt32(littleEndian: subdata(in: offset..<(offset + 2)).withUnsafeBytes { $0.load(as: UInt32.self) })
        case .magic64:
            return UInt32(bigEndian: subdata(in: offset..<(offset + 2)).withUnsafeBytes { $0.load(as: UInt32.self) })
        }
    }

    func uint16Value(atOffset: Int, withMagic magic: Magic) -> UInt16? {
        let offset = (atOffset * 2)
        switch magic {
        case .cigam64:
            return UInt16(littleEndian: subdata(in: offset..<(offset + 2)).withUnsafeBytes { $0.load(as: UInt16.self) })
        case .magic64:
            return UInt16(bigEndian: subdata(in: offset..<(offset + 2)).withUnsafeBytes { $0.load(as: UInt16.self) })
        }
    }
}

extension URL {
    var fileSize: UInt64 {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: self.path)
            if let size = fileAttributes[FileAttributeKey.size] as? UInt64 {
                return size
            } else {
                return 0
            }
        } catch {
            return 0
        }
    }

    var isMachOExecutable: Bool {

        // Get the file handle
        let fileHandle: FileHandle
        do {
            fileHandle = try FileHandle(forReadingFrom: self)
        } catch {
            return false
        }

        // Get the file size
        let fileSize = self.fileSize

        // Get the header data from the beginning of the file
        guard 4_096 < fileSize else { return false }
        fileHandle.seek(toFileOffset: 0)
        let data = fileHandle.readData(ofLength: 4_096)
        guard data.count == 4_096 else { return false }

        // Get the magic byte
        guard
            let magicByte = data.uint32Value(atOffset: 0, withMagic: .magic64),
            let magic = Magic(rawValue: magicByte) else {
                return false
        }

        // Get the filetype
        guard
            let fileType = data.uint32Value(atOffset: 3, withMagic: magic) else {
                return false
        }

        // Check if the fileType value returned is equal to 0x2 (executable)
        return fileType == 0x2
    }
}
