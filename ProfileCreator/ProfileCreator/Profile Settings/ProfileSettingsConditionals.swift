//
//  ProfileSettingsConditionals.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    func match(subkey: PayloadSubkey, targetCondition: PayloadTargetCondition, isEnabledOnlyByUser: Bool = false, parentValueKeyPath: String?, payloadIndex: Int = 0) -> [[String: Any]]? {

        // Set match var
        var match = [[String: Any]]()

        // Verify we got a targetSubkey
        guard let targetSubkey = targetCondition.targetSubkey() else {
            Log.shared.error(message: "Failed to get condition target subkey", category: String(describing: self))
            return match
        }
        self.conditionSubkey = targetSubkey

        let targetKeyPath: String
        if let pValueKeyPath = parentValueKeyPath {
            targetKeyPath = PayloadUtility.expandKeyPath(targetSubkey.valueKeyPath, withRootKeyPath: pValueKeyPath)
        } else {
            targetKeyPath = targetSubkey.valueKeyPath
        }

        var targetParentKeyPath: String?
        var targetKeyPathArray = targetKeyPath.components(separatedBy: ".")
        if 1 < targetKeyPathArray.count {
            targetKeyPathArray.removeLast()
            targetParentKeyPath = targetKeyPathArray.joined(separator: ".")
        }

        // Check cached value
        if parentValueKeyPath == nil, !targetSubkey.isConditionalTarget, let conditionResult = self.cachedConditionals[targetCondition.identifier] as? [[String: Any]] {
            #if DEBUG
            Log.shared.debug(message: "Returning cached condition result: \(conditionResult)", category: String(describing: self))
            #endif
            return conditionResult
        }

        // This is checking if the current subkey and the target subkey have conditions that depend on eachother, in that case pass true to isEnabled to ignoreConditionals, but return any other reason why a key was enabled.
        let requiredConditions = targetSubkey.conditionals.compactMap { !($0.require == .push && self.distributionMethod == .manual) ? $0 : nil }
        let ignoreConditionals = requiredConditions.contains {
            $0.conditions.contains {
                if let payloadSubkey = $0.payloadSubkey, payloadSubkey == targetSubkey {
                    return true
                }
                return false
            }
        }

        #if DEBUGCONDITIONS
        Log.shared.debug(message: "Condition target keyPath: \(targetKeyPath), domainIdentifier: \(targetSubkey.domainIdentifier), type: \(targetSubkey.type), ignoreConditions: \(ignoreConditionals)", category: String(describing: self))
        #endif

        // Platforms
        if let platforms = targetCondition.platforms {
            if !self.platforms.isDisjoint(with: platforms) {
                match.append(["key": ManifestKey.platforms.rawValue, "target": targetSubkey.keyPath])
            }
        }

        // Not Platforms
        if let notPlatforms = targetCondition.notPlatforms {
            if self.platforms.isDisjoint(with: notPlatforms) {
                match.append(["key": ManifestKey.notPlatforms.rawValue, "target": targetSubkey.keyPath])
            }
        }

        // Distribution
        if let distributionMethod = targetCondition.distribution {
            if !self.distributionMethod.isDisjoint(with: distributionMethod) {
                match.append(["key": ManifestKey.distribution.rawValue, "target": targetSubkey.keyPath])
            }
        }

        if !match.isEmpty { return match }

        let isEnabled = self.isEnabled(targetSubkey, onlyByUser: isEnabledOnlyByUser, ignoreConditionals: ignoreConditionals, payloadIndex: payloadIndex)
        let payloadContent = self.payloadContent(forSubkey: targetSubkey, parentValueKeyPath: targetParentKeyPath, payloadIndex: payloadIndex)

        // If key is not enabled, then there is no need to check any other condition either as they doesn't matter.
        if !isEnabled {
            #if DEBUGCONDITIONS
            Log.shared.debug(message: "Condition target keyPath: \(targetSubkey.keyPath), domainIdentifier: \(targetSubkey.domainIdentifier), type: \(targetSubkey.type), isPresent: \(false)", category: String(describing: self))
            #endif

            match.append(["key": ManifestKey.isPresent.rawValue, "target": targetSubkey.keyPath, "value": false])
            return match
        } else if let isPresent = targetCondition.isPresent, isPresent {
            #if DEBUGCONDITIONS
            Log.shared.debug(message: "Condition target keyPath: \(targetSubkey.keyPath), domainIdentifier: \(targetSubkey.domainIdentifier), type: \(targetSubkey.type), isPresent: \(true)", category: String(describing: self))
            #endif

            match.append(["key": ManifestKey.isPresent.rawValue, "target": targetSubkey.keyPath, "value": true])
        }

        if let targetValue = payloadContent[targetSubkey.key] {

            #if DEBUGCONDITIONS
            Log.shared.debug(message: "Condition target keyPath: \(targetSubkey.keyPath), domainIdentifier: \(targetSubkey.domainIdentifier), type: \(targetSubkey.type), value: \(targetValue)", category: String(describing: self))
            #endif

            var arrayElementType: PayloadValueType?
            if targetSubkey.type == .array, let arrayElement = targetSubkey.subkeys.first, targetValue is [Any] {

                #if DEBUGCONDITIONS
                Log.shared.debug(message: "Condition target keyPath: \(targetSubkey.keyPath), domainIdentifier: \(targetSubkey.domainIdentifier), type: \(targetSubkey.type), arrayElementType: \(arrayElement.type)", category: String(describing: self))
                #endif

                arrayElementType = arrayElement.type
            }

            // Is Empty
            if let isEmpty = targetCondition.isEmpty {
                if let targetValues = targetValue as? [Any] {
                    if isEmpty == PayloadUtility.valueIsEmpty(targetValues, valueType: .array) {
                        match.append(["key": ManifestKey.isEmpty.rawValue, "keyValue": isEmpty, "target": targetSubkey.keyPath, "value": targetValue])
                    }
                } else {
                   if isEmpty == PayloadUtility.valueIsEmpty(targetValue, valueType: targetSubkey.type) {
                        match.append(["key": ManifestKey.isEmpty.rawValue, "keyValue": isEmpty, "target": targetSubkey.keyPath, "value": targetValue])
                    }
                }
            }

            // RangeList
            if let rangeList = targetCondition.rangeList {
                if let arrayElementValueType = arrayElementType, let targetValues = targetValue as? [Any] {
                    if rangeList.contains(values: targetValues, ofType: arrayElementValueType) {
                        match.append(["key": ManifestKey.rangeList.rawValue, "target": targetSubkey.keyPath, "value": targetValue])
                    }
                } else {
                    if rangeList.contains(value: targetValue, ofType: targetSubkey.type) {
                        match.append(["key": ManifestKey.rangeList.rawValue, "target": targetSubkey.keyPath, "value": targetValue])
                    }
                }
            }

            // Not RangeList
            if let notRangeList = targetCondition.notRangeList {
                if let arrayElementValueType = arrayElementType, let targetValues = targetValue as? [Any] {
                    if !notRangeList.contains(values: targetValues, ofType: arrayElementValueType) {
                        match.append(["key": ManifestKey.notRangeList.rawValue, "target": targetSubkey.keyPath, "value": targetValue])
                    }
                } else {
                    if !notRangeList.contains(value: targetValue, ofType: targetSubkey.type) {
                        match.append(["key": ManifestKey.notRangeList.rawValue, "target": targetSubkey.keyPath, "value": targetValue])
                    }
                }
            }

            // Contains Any
            if let containsAny = targetCondition.containsAny {
                if let arrayElementValueType = arrayElementType, let targetValues = targetValue as? [Any] {
                    if containsAny.containsAny(values: targetValues, ofType: arrayElementValueType) {
                        match.append(["key": ManifestKey.containsAny.rawValue, "target": targetSubkey.keyPath, "value": targetValue])
                    }
                } else {
                    if containsAny.containsAny(value: targetValue, ofType: targetSubkey.type) {
                        match.append(["key": ManifestKey.containsAny.rawValue, "target": targetSubkey.keyPath, "value": targetValue])
                    }
                }
            }

            // Not Contains Any
            if let notContainsAny = targetCondition.notContainsAny {
                if let arrayElementValueType = arrayElementType, let targetValues = targetValue as? [Any] {
                    if !notContainsAny.containsAny(values: targetValues, ofType: arrayElementValueType) {
                        match.append(["key": ManifestKey.notContainsAny.rawValue, "target": targetSubkey.keyPath, "value": targetValue])
                    }
                } else {
                    if !notContainsAny.containsAny(value: targetValue, ofType: targetSubkey.type) {
                        match.append(["key": ManifestKey.notContainsAny.rawValue, "target": targetSubkey.keyPath, "value": targetValue])
                    }
                }
            }
        } else {
            Log.shared.error(message: "Failed to get value for subkey with keyPath: \(targetKeyPath)", category: String(describing: self))
        }

        // Cache the condition result
        #if DEBUGCONDITIONS
        Log.shared.debug(message: "Setting cached condition result: \(match)", category: String(describing: self))
        #endif

        self.cachedConditionals[targetCondition.identifier] = match

        return !match.isEmpty ? match : nil
    }

    func setCachePayloadContent(_ payloadContent: [String: Any], subkey: PayloadSubkey, payloadIndex: Int) {
        var cacheSubkey = self.cachedPayloadContent[subkey.keyPath] ?? [Int: [String: Any]]()
        cacheSubkey[payloadIndex] = payloadContent
        self.cachedPayloadContent[subkey.keyPath] = cacheSubkey
    }

    func payloadContent(forSubkey subkey: PayloadSubkey, parentValueKeyPath: String? = nil, payloadIndex: Int = 0) -> [String: Any] {

        // ---------------------------------------------------------------------
        //  Check if this subkey has a cached payload content, return that
        // ---------------------------------------------------------------------
        if parentValueKeyPath == nil, let cachePayloadContent = self.cachedPayloadContent[subkey.keyPath], let payloadContent = cachePayloadContent[payloadIndex] {
            #if DEBUGISENABLED
            Log.shared.debug(message: "Subkey: \(subkey.keyPath) payload content: \(payloadContent) (cache)", category: String(describing: self))
            #endif
            return payloadContent
        }

        let export = ProfileExport(exportSettings: self)
        export.ignoreSave = true
        export.ignoreErrorInvalidValue = true

        var payloadContent = [String: Any]()

        do {
            if let subkeyValue = try export.value(forSubkey: subkey, parentValueKeyPath: parentValueKeyPath ?? subkey.parentSubkey?.valueKeyPath, payloadIndex: payloadIndex) {
                payloadContent[subkey.key] = subkeyValue
            } else {
                Log.shared.error(message: "Failed to get payload content for subkey with keyPath: \(subkey.keyPath)", category: String(describing: self))
            }
        } catch {
            Log.shared.error(message: "Failed to get payload content for subkey with keyPath: \(subkey.keyPath)", category: String(describing: self))
        }

        self.setCachePayloadContent(payloadContent, subkey: subkey, payloadIndex: payloadIndex)

        return payloadContent
    }

    func match(subkey: PayloadSubkey, targetConditionals: [PayloadTargetCondition], isEnabledOnlyByUser: Bool = false, parentValueKeyPath: String? = nil, payloadIndex: Int = 0) -> [[String: Any]]? {

        var match = [[String: Any]]()
        for targetCondition in targetConditionals {
            if let matchArray = self.match(subkey: subkey, targetCondition: targetCondition, isEnabledOnlyByUser: isEnabledOnlyByUser, parentValueKeyPath: parentValueKeyPath, payloadIndex: payloadIndex) {

                #if DEBUG
                Log.shared.debug(message: "Subkey: \(subkey.keyPath) conditionals target match array: \(matchArray)", category: String(describing: self))
                #endif

                match.append(contentsOf: matchArray)
            }

            // Reset subkey
            self.conditionSubkey = nil

            // FIXME: This should not be required for target conditionals? What happens now that it's removed?
            // if match.isEmpty {
            //    return nil
            // }
        }

        // FIXME: This must be fixed, should not add the isPresent key to the match unless the key is set? Why isn't this done? isPresent is implied. This class needs a lot of rework anyway, for clarity.
        if !targetConditionals.contains(where: { $0.isPresent != nil }) {
            match = match.filter { !($0["key"] as? String == ManifestKey.isPresent.rawValue) }

            // Somewhat special case for isPresent as that will always return for any key, but if it's also a check then it will always return required
        } else if let isPresent = targetConditionals.first(where: { $0.isPresent != nil })?.isPresent {
            match = match.filter { !($0["key"] as? String == ManifestKey.isPresent.rawValue && $0["value"] as? Bool != isPresent) }
        }

        return !match.isEmpty ? match : nil
    }

    func match(subkey: PayloadSubkey, sourceConditionals: [PayloadCondition], isEnabledOnlyByUser: Bool = false, payloadIndex: Int = 0) -> [[String: Any]]? {
        var match = [[String: Any]]()
        for sourceConditional in sourceConditionals {
            if let matchArray = self.match(subkey: subkey, targetConditionals: sourceConditional.conditions, isEnabledOnlyByUser: isEnabledOnlyByUser, payloadIndex: payloadIndex) {

                #if DEBUG
                Log.shared.debug(message: "Subkey: \(subkey.keyPath) conditionals match array: \(matchArray)", category: String(describing: self))
                #endif

                match.append(contentsOf: matchArray)
            }

            if match.isEmpty {
                return nil
            }
        }

        return !match.isEmpty ? match : nil
    }

    func match(subkey: PayloadSubkey, excludeConditionals: [PayloadExclude], isEnabledOnlyByUser: Bool = false, parentValueKeyPath: String? = nil, payloadIndex: Int = 0) -> [[String: Any]]? {

        var match = [[String: Any]]()
        for excludeConditional in excludeConditionals {

            if excludeConditional.require == .push && self.distributionMethod == .manual {
                continue
            }

            if let matchArray = self.match(subkey: subkey, targetConditionals: excludeConditional.conditions, isEnabledOnlyByUser: isEnabledOnlyByUser, parentValueKeyPath: parentValueKeyPath, payloadIndex: payloadIndex) {

                #if DEBUG
                Log.shared.debug(message: "Subkey: \(subkey.keyPath) exclude match array: \(matchArray)", category: String(describing: self))
                #endif

                match.append(contentsOf: matchArray)
            }
        }

        return !match.isEmpty ? match : nil
    }

}
