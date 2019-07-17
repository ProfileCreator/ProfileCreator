//
//  ExtensionFileManager.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

extension FileManager {

    func contentsOfDirectory(at url: URL, withExtension pathExtension: String, includingPropertiesForKeys keys: [URLResourceKey]?, options: FileManager.DirectoryEnumerationOptions = []) -> [URL]? {

        var contents = [URL]()
        do {
            contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: options)
        } catch {
            // FIXME: Proper Logging
            print("Class: \(self.self), Function: \(#function), Error: \(error)")
            return nil
        }

        return contents.filter { $0.pathExtension == pathExtension }
    }
}
