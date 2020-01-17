# ProfileCreator 0.2.2 (Beta 7)

Please report any bugs, feature requests or suggestions as an issue to this repository.

## New Features

### New Payload Library: Local Preferences (Experimental)

In the Payload library there is now a new icon of an iMac symbolising local preferences.

Under this menu item all settings currently defined on your local Mac are listed by domain.

These preferences are collected from the UserDefaults API for all domains that have a property list file in any of the following locations:

* /Library/Preferences
* ~/Library/Preferences
* ~/Library/Preferences/ByHost

The settings are combined from all locations into one manifest that is then read by ProfileCreator with the current settings as default values.

By default only the preferences for applications in the Applications folder is shown, but you can enable to show all preferences from the settings.

The description for each key tells where that settings is read from, in cases where the preference is set in multiple domains this might.

** IMPORTANT: This feature is experimental and will continue to be updated in the coming betas.

Current limitations are:

*  Collection types (arrays and dictinoary) cannot export default values.
*  Multilevel nested Dictionaries or Array of Dictionaries does not display their contents correctly.
*  Settings are only read on application launch.
*  Application launch time is slower.
* .GlobalPreferences includes the preferences for ProfileCreator.
*  Not all preferences are included, only those with a .plist file in any of the following locations:
* /Library/Preferences
* ~/Library/Preferences
* ~/Library/Preferences/ByHost
** 

### Change path for the profile library groups

You can now in the application Preferences under _Library_ select a custom path to a folder where the application will store the profile group save files.

If the path is empty or invalid, the default path will be used instead.

## Updated Features

### Developer Menu

* New item: `Show Payload Manifest` that will show a text representation of the current manifest.

### Profile Importing

* Importing profiles now ignores the following keys included by management applications:
- Keys with prefix: **ABT_** (LANrev)

## New Preferences

### Library

* **ProfileGroupLibraryPath**
Path to the folder where the profile group settings are saved.

### Payloads

* **PayloadLibraryShowCustom**
Show the custom payloads created by the user (not available yet) or unknown payloads imported. 

* **PayloadLibraryShowApplicationsFolderOnly**
Include only preferences for applications under /Applications in the Local Preferences view. If set to false, include all preferences.

## New Payloads

* com.apple.FileVault2 (macOS)
* com.apple.SubmitDiagInfo (macOS)
* com.microsoft.autoupdate.fba (macOS)
* com.microsoft.errorreporting (macOS)
* com.microsoft.Excel (macOS)
* com.microsoft.Office365ServiceV2 (macOS)
* com.microsoft.OneDrive (macOS)
* com.microsoft.OneDriveUpdater (macOS)
* com.microsoft.onenote.mac (macOS)
* com.microsoft.Powerpoint (macOS)
* com.microsoft.Word (macOS)
* com.skype.skype (macOS)
* com.grahamgilbert.crypt (macOS)

## Updated Payloads

### ManagedInstalls (Munki)

* Changed the `SoftwareRepoURL` key from required to enabled.

### com.apple.applicationaccess (Restrictions)

* Added the key `allowDiagnosticSubmission`

## Bug Fixes

* Fixed a bug where the general data imports (like scripts for LoginWindow) did not save the imported value.
* Fixed a bug where pasting formatted text kept the formatting in the TextField. (#66)
* Fixed a bug where entering integer values in certain fields returned an unexpected error (#67)
* Fixed a bug where removing a custom imported payload from the profile did not "stick" after save. (#69)
* Fixed a bug where converting betweeen hex strings and data not showed the correct string in the UI.
* Fixed a bug where dropping a .mobileconfig on the app icon didn't import the profile if there was any warnings.
* Now payloads that don't have an icon set will use a generic dotted square as icon instead of empty space.
* ...and many minor bug fixes. 

## Known Issues

* When a profile is repoened by the application at launch, the application doesn't recognize that it's open and multiple copies of the same profile may be open at the same time.

* When saving a profile for the first time, on rare occasions it might not save and won't be recognized after a restart.
(Never found a way to replicate, only rare reports. If this happens to you, please contact me or file an issue.)

## Contribute

There are many ways to contribute to this project. Here are a few listed below:

* Test and report bugs or incorrect behavior both in the UI and in the exported profiles.
* Language and spelling errors. (English is not my native language).
* Missing payloads or payload keys. (Contribute to the [ProfileManifests](https://github.com/erikberglund/ProfileManifests) repository to improve the manifests used to define all payloads, keys and their interactions.)
* Add feature requests or suggestions by opening an issue in this repository.
