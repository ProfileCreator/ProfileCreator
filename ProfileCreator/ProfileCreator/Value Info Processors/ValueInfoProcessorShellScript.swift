//
//  ValueInfoProcessorFont.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

enum ShellScriptType: String {
    case unknown
    case bash
    case sh
    case python
    case ruby
    case perl
}

class ValueInfoProcessorShellScript: ValueInfoProcessor {

    // MARK: -
    // MARK: Intialization

    override init() {
        super.init(withIdentifier: "shell-script")
    }

    override func valueInfo(forData data: Data) -> ValueInfo? {
        var valueInfo = ValueInfo()

        let scriptType = self.scriptType(forData: data)

        // Title
        valueInfo.title = self.title(forScriptType: scriptType)

        // Top
        valueInfo.topLabel = NSLocalizedString("File Size", comment: "")
        valueInfo.topContent = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: ByteCountFormatter.CountStyle.file)

        // Icon
        valueInfo.icon = self.icon(forScriptType: scriptType)

        return valueInfo
    }

    func shebang(forData data: Data) -> String? {
        if let aStreamReader = StreamReader(data: data) {
            defer {
                aStreamReader.close()
            }
            while let line = aStreamReader.nextLine() {
                if line.contains("#!") {
                    return line
                }
            }
        } else {
            Log.shared.error(message: "Failed to create StreamReader for data", category: String(describing: self))
        }
        return nil
    }

    func scriptType(forData data: Data) -> ShellScriptType {
        if let shebang = self.shebang(forData: data)?.lowercased() {
            if shebang.contains("bash") {
                return .bash
            } else if shebang.contains("sh") {
                return .sh
            } else if shebang.contains("python") {
                return .python
            } else if shebang.contains("perl") {
                return .perl
            } else if shebang.contains("ruby") {
                return .ruby
            }
            return .unknown
        } else {
            return .unknown
        }
    }

    func title(forScriptType type: ShellScriptType) -> String {
        switch type {
        case .unknown:
            return NSLocalizedString("Unknown Script Type", comment: String(describing: self))
        case .bash:
            return NSLocalizedString("Bash Script", comment: String(describing: self))
        case .sh:
            return NSLocalizedString("Shell Script", comment: String(describing: self))
        case .python:
            return NSLocalizedString("Python Script", comment: String(describing: self))
        case .ruby:
            return NSLocalizedString("Ruby Script", comment: String(describing: self))
        case .perl:
            return NSLocalizedString("Perl Script", comment: String(describing: self))
        }
    }

    func icon(forScriptType type: ShellScriptType) -> NSImage {
        switch type {
        case .unknown:
            return NSWorkspace.shared.icon(forFileType: kUTTypeShellScript as String)
        case .bash:
            return NSWorkspace.shared.icon(forFileType: kUTTypeShellScript as String)
        case .sh:
            return NSWorkspace.shared.icon(forFileType: kUTTypeShellScript as String)
        case .python:
            return NSWorkspace.shared.icon(forFileType: kUTTypePythonScript as String)
        case .ruby:
            return NSWorkspace.shared.icon(forFileType: kUTTypeRubyScript as String)
        case .perl:
            return NSWorkspace.shared.icon(forFileType: kUTTypePerlScript as String)
        }
    }
}
