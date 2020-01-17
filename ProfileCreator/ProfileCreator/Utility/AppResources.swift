//
//  AppResources.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension FileManager {

    func moveFile(at url: URL, toDirectory directoryURL: URL, withName name: String) throws -> URL? {
        let targetURL = directoryURL.appendingPathComponent(name)
        try self.createDirectoryIfNotExists(at: directoryURL, withIntermediateDirectories: true)
        try self.removeItemIfExists(at: targetURL)
        try self.moveItem(at: url, to: targetURL)
        return targetURL
    }

    func createDirectoryIfNotExists(at url: URL, withIntermediateDirectories intermediate: Bool, attributes: [FileAttributeKey: Any]? = nil) throws {
        do {
            try self.createDirectory(at: url, withIntermediateDirectories: intermediate, attributes: attributes)
        } catch {
            if (error as NSError).code != 516 {
                throw error
            }
        }
    }

    func removeItemIfExists(at url: URL) throws {
        do {
            try self.removeItem(at: url)
        } catch {
            if (error as NSError).code != NSFileNoSuchFileError {
                throw error
            }
        }
    }
}

extension URL {
    init?(applicationDirectory directory: ApplicationDirectory) {
        switch directory {
        case .applicationSupport:
            do {
                let userApplicationSupport = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let userApplicationSupportProfileCreator = userApplicationSupport.appendingPathComponent("ProfileCreator", isDirectory: true)
                self.init(fileURLWithPath: userApplicationSupportProfileCreator.path, isDirectory: true)
            } catch {
                Log.shared.error(message: "Failed to get URL for user Application Support directory with error: \(error)", category: String(describing: #file))
                return nil
            }

        case .profiles:
            let profileLibraryURL: URL
            var isDirectory: ObjCBool = false
            if
                let userProfileLibraryPath = UserDefaults.standard.string(forKey: PreferenceKey.profileLibraryPath),
                !(FileManager.default.fileExists(atPath: userProfileLibraryPath, isDirectory: &isDirectory) && !isDirectory.boolValue) {
                profileLibraryURL = URL(fileURLWithPath: userProfileLibraryPath)
            } else if let userApplicationSupport = URL(applicationDirectory: .applicationSupport) {
                profileLibraryURL = userApplicationSupport.appendingPathComponent("Profiles", isDirectory: true)
            } else {
                return nil
            }

            do {
                try FileManager.default.createDirectoryIfNotExists(at: profileLibraryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Log.shared.error(message: "Failed to create directory: \(profileLibraryURL) with error: \(error)", category: String(describing: #file))
                return nil
            }
            self.init(fileURLWithPath: profileLibraryURL.path, isDirectory: true)

        case .groups:
            let profileLibraryGroupURL: URL
            var isDirectory: ObjCBool = false
            if
                let userProfileLibraryGroupPath = UserDefaults.standard.string(forKey: PreferenceKey.profileLibraryGroupPath),
                !(FileManager.default.fileExists(atPath: userProfileLibraryGroupPath, isDirectory: &isDirectory) && !isDirectory.boolValue) {
                profileLibraryGroupURL = URL(fileURLWithPath: userProfileLibraryGroupPath)
            } else if let userApplicationSupport = URL(applicationDirectory: .applicationSupport) {
                profileLibraryGroupURL = userApplicationSupport.appendingPathComponent("Groups", isDirectory: true)
            } else {
                return nil
            }

            do {
                try FileManager.default.createDirectoryIfNotExists(at: profileLibraryGroupURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Log.shared.error(message: "Failed to create directory: \(profileLibraryGroupURL) with error: \(error)", category: String(describing: #file))
                return nil
            }
            self.init(fileURLWithPath: profileLibraryGroupURL.path, isDirectory: true)

        case .groupLibrary:
            guard let groups = URL(applicationDirectory: .groups) else {
                return nil
            }
            self.init(fileURLWithPath: groups.appendingPathComponent("Library", isDirectory: true).path, isDirectory: true)

        case .groupSmartGroups:
            guard let groups = URL(applicationDirectory: .groups) else {
                return nil
            }
            self.init(fileURLWithPath: groups.appendingPathComponent("SmartGroups", isDirectory: true).path, isDirectory: true)

        case .jamf:
            guard let groups = URL(applicationDirectory: .groups) else {
                return nil
            }
            self.init(fileURLWithPath: groups.appendingPathComponent("JAMF", isDirectory: true).path, isDirectory: true)
        }
    }
}
