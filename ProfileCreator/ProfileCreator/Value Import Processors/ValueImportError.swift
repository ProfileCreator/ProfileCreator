//
//  ValueImportError.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

struct ValueImportError: LocalizedError {
        var errorDescription: String? { return mMsg }
        var failureReason: String? { return mMsg }
        var recoverySuggestion: String? { return "" }
        var helpAnchor: String? { return "" }

        private var mMsg: String

        init(_ description: String) {
            mMsg = description
        }
}
