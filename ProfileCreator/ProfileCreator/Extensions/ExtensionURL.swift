//
//  ExtensionURL.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

extension URL {

    var typeIdentifier: String {
        do {
            if let uti = try self.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                return uti
            }
        } catch {
            Log.shared.error(message: "Failed getting uti for: \(self.path) with error: \(error)", category: String(describing: self))
        }

        if let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, self.pathExtension as CFString, nil) {
            return unmanagedFileUTI.takeRetainedValue() as String
        } else {
            return kUTTypeItem as String
        }
    }
}
