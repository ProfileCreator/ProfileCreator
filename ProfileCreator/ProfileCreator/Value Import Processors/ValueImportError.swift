//
//  ValueImportError.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

struct ValueImportError: LocalizedError {
        var errorDescription: String? { mMsg }
        var failureReason: String? { mMsg }
        var recoverySuggestion: String? { "" }
        var helpAnchor: String? { "" }

        private var mMsg: String

        init(_ description: String) {
            mMsg = description
        }
}
