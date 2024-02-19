//
//  ValueImportProcessors.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

class ValueImportProcessors {

    // MARK: -
    // MARK: Variables

    public static let shared = ValueImportProcessors()

    // MARK: -
    // MARK: Initialization

    private init() {}

    public func processor(withIdentifier identifier: String) -> ValueImportProcessor? {

        // FIXME: Temporary
        switch identifier {
        case "com.apple.security.firewall.Applications":
            return ValueImportProcessorFirewallApplications()
        case "com.apple.asam.AllowedApplications":
            return ValueImportProcessorASAMApplications()
        case "com.apple.syspolicy.kernel-extension-policy.AllowedTeamIdentifiers":
            return ValueImportProcessorKernelExtensionPolicyTeamIdentifiers()
        case "com.apple.syspolicy.kernel-extension-policy.AllowedKernelExtensions":
            return ValueImportProcessorKernelExtensionPolicyKernelExtensions()
        case "com.apple.syspolicy.system-extension-policy.SystemExtensionsBundleIdentifier":
            return ValueImportProcessorSystemExtensionPolicyBundleIdentifier()
        case "com.apple.syspolicy.system-extension-policy.SystemExtensionsTypes":
            return ValueImportProcessorSystemExtensionPolicyAllowedTypes()
        case "com.apple.syspolicy.system-extension-policy.RemovableSystemExtensions":
            return ValueImportProcessorSystemExtensionPolicyRemovable()
        case "com.apple.applicationaccess.new.whiteList":
            return ValueImportProcessorApplicationAccessWhiteList()
        case "public.folder":
            return ValueImportProcessorDirectory()
        case "com.apple.dashboard.whiteList":
            return ValueImportProcessorDashboardWhiteList()
        case "com.apple.TCC.configuration-profile-policy.services":
            return ValueImportProcessorPrivacyPolicy()
        case "com.apple.TCC.configuration-profile-policy.services.AppleEvents":
            return ValueImportProcessorPrivacyPolicyAppleEvents()
        case "com.apple.dock.static-apps":
            return ValueImportProcessorDockStaticApps()
        case "com.apple.dock.static-others":
            return ValueImportProcessorDockStaticOthers()
        case "com.apple.security.certificatetransparency":
            return ValueImportProcessorCertificateTransparency()
        case "lineValueForFormat":
            return ValueImportProcessorLineValue()
        default:
            return nil
        }
    }
}
