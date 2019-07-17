//
//  Log.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import os.log

class Log {

    enum LogLevel: UInt8 {
        case info = 1
        case debug = 2
        case error = 16
        case fault = 17
    }

    // MARK: -
    // MARK: Static Variables

    static let shared = Log()

    // MARK: -
    // MARK: Initialization

    private init () {}

    // MARK: -
    // MARK: Functions Category

    func debug(message: String) {
        self.write(message: message, category: "DEBUG", level: .info)
    }

    func log(message: String) {
        self.write(message: message, category: "", level: nil)
    }

    func error(message: String) {
        self.write(message: message, category: "ERROR", level: .error)
    }

    func fault(message: String) {
        self.write(message: message, category: "FAULT", level: .fault)
    }

    func info(message: String) {
        self.write(message: message, category: "INFO", level: .info)
    }

    // MARK: -
    // MARK: Functions Category

    func debug(message: String, category: String) {
        self.write(message: message, category: category, level: .info)
    }

    func log(message: String, category: String) {
        self.write(message: message, category: category, level: nil)
    }

    func error(message: String, category: String) {
        self.write(message: message, category: category, level: .error)
    }

    func fault(message: String, category: String) {
        self.write(message: message, category: category, level: .fault)
    }

    func info(message: String, category: String) {
        self.write(message: message, category: category, level: .info)
    }

    func write(message: String, category: String, level: LogLevel? = .info) {
        if #available(OSX 10.12, *) {
            let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? StringConstant.domain, category: category)
            switch level {
            case .debug?:
                os_log("%{public}@", log: log, type: .debug, message)
            case .error?:
                os_log("%{public}@", log: log, type: .error, message)
            case .fault?:
                os_log("%{public}@", log: log, type: .fault, message)
            case .info?:
                os_log("%{public}@", log: log, type: .info, message)
            default:
                os_log("%{public}@", log: log, type: .default, message)
            }
        } else {
            if level == .debug {
                NSLog(" [\(category)] DEBUG: \(message)")
            } else if level == .error {
                NSLog(" [\(category)] ERROR: \(message)")
            } else if level == .fault {
                NSLog(" [\(category)] FAULT: \(message)")
            } else if level == .info {
                NSLog(" [\(category)] INFO: \(message)")
            } else {
                NSLog(" [\(category)] \(message)")
            }
        }
    }
}
