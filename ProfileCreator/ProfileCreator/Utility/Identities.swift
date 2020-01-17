//
//  Certificates.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class Identities {

    static let shared = Identities()

    var identities = [[String: AnyObject]]()

    func updateCodeSigningIdentities() {
        self.identities = self.codeSigningIdentities() ?? [[String: AnyObject]]()
    }

    private func codeSigningIdentities() -> [[String: AnyObject]]? {

        var osStatus = errSecSuccess
        let matchTrustedOnly: CFBoolean = UserDefaults.standard.bool(forKey: PreferenceKey.signingCertificateShowUntrusted) ? kCFBooleanFalse : kCFBooleanTrue

        var query = [kSecClass as String: kSecClassIdentity,
                     kSecMatchTrustedOnly as String: matchTrustedOnly,
                     kSecMatchLimit as String: kSecMatchLimitAll,
                     kSecReturnAttributes as String: kCFBooleanTrue,
                     kSecReturnPersistentRef as String: kCFBooleanTrue,
                     kSecReturnRef as String: kCFBooleanTrue] as [String: Any]

        if !UserDefaults.standard.bool(forKey: PreferenceKey.signingCertificateShowExpired) {
            query[kSecMatchValidOnDate as String] = Date()
        }

        if !UserDefaults.standard.bool(forKey: PreferenceKey.signingCertificateSearchSystemKeychain) {
            let userKeychainPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("/Library/Keychains/login.keychain-db")

            var userKeychain: SecKeychain?
            osStatus = SecKeychainOpen(userKeychainPath.path, &userKeychain)
            guard osStatus == errSecSuccess, let keychain = userKeychain else {
                let osStatusString = String(SecCopyErrorMessageString(osStatus, nil) ?? "")
                Log.shared.error(message: "Failed to open the user keychain at path: \(userKeychainPath.path) with error: \(osStatusString)", category: String(describing: self))
                return nil
            }

            query[kSecMatchSearchList as String] = [keychain]
        }

        var queryResult: AnyObject?
        osStatus = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        guard osStatus != errSecItemNotFound else {
            let osStatusString = String(SecCopyErrorMessageString(osStatus, nil) ?? "")
            Log.shared.error(message: "Error when getting code singing identities: \(osStatusString)", category: String(describing: self))
            return nil
        }

        guard let identityDicts = queryResult as? [[String: AnyObject]] else {
            Log.shared.error(message: "Error when getting query result items for code signing identities", category: String(describing: self))
            return nil
        }

        return  identityDicts.sorted { $0[kSecAttrLabel as String] as? String ?? "" < $1[kSecAttrLabel as String] as? String ?? "" }
    }

    static func codeSigningIdentityDict(persistentRef: Data?) -> [String: AnyObject]? {
        guard let persistentRefData = persistentRef else { return nil }

        let query = [ kSecClass as String: kSecClassIdentity,
                      kSecValuePersistentRef as String: persistentRefData,
                      kSecReturnAttributes as String: kCFBooleanTrue,
                      kSecMatchLimit as String: kSecMatchLimitAll,
                      kSecReturnPersistentRef as String: kCFBooleanTrue,
                      kSecReturnRef as String: kCFBooleanTrue] as [String: Any]

        var osStatus: OSStatus = errSecSuccess

        var queryResult: AnyObject?
        osStatus = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        guard osStatus == errSecSuccess else {
            let osStatusString = String(SecCopyErrorMessageString(osStatus, nil) ?? "")
            Log.shared.error(message: "Error when getting code singing identity from ref: \(osStatusString)", category: String(describing: self))
            return nil
        }

        guard let identityDict = queryResult as? [[String: AnyObject]] else {
            Log.shared.error(message: "Error when getting query result items for code signing identity from ref", category: String(describing: self))
            return nil
        }

        return identityDict.first
    }

    static func codeSigningIdentity(persistentRef: Data?) -> SecIdentity? {
        guard let codeSigningIdentityDict = self.codeSigningIdentityDict(persistentRef: persistentRef) else {
            return nil
        }

        guard
            let secIdentityObject = codeSigningIdentityDict[kSecValueRef as String],
            CFGetTypeID(secIdentityObject) == SecIdentityGetTypeID() else {
                return nil
        }

        // swiftlint:disable:next force_cast
        return (secIdentityObject as! SecIdentity)
    }

    static func popUpButtonMenu(forCodeSigningIdentityDicts identityDicts: [[String: AnyObject]]) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "None", action: nil, keyEquivalent: ""))
        for identity in identityDicts {
            guard
                let secIdentityObject = identity[kSecValueRef as String],
                CFGetTypeID(secIdentityObject) == SecIdentityGetTypeID(),
                let secPersistentRef = identity[kSecValuePersistentRef as String] as? Data else {
                    continue
            }
            // swiftlint:disable:next force_cast
            let secIdentity = secIdentityObject as! SecIdentity
            let menuItem = NSMenuItem()
            menuItem.title = identity[kSecAttrLabel as String] as? String ?? "Unknown Certificate"
            menuItem.representedObject = secPersistentRef
            menuItem.image = secIdentity.certificateIconSmall
            menu.addItem(menuItem)
        }
        return menu
    }
}
