# ProfileCreator 0.2.1 (Beta 6)

Please report any bugs, feature requests or suggestions as an issue to this repository.

## Updated Features

### New Signing Certificate selection

This version fixed a bug where a prompt to authenticate ProfileCreator for private key access to certain certificates was shown to some users.

The fix required another reference to the keychain item to be saved than in previous versions.

**This means that if you have selected a signing certificate as default in Preferences or a specific certificate for each profile, you will only see a string of numbers. You will need to re-select that certificate to update the reference.**

You can still export with the old reference in my testing, but it will not show as selected in the list of certificates.

### New Signing Certificate search optioins

In the Preferences under _Profile Defaults_ you can now expand the signing identity search to include:

* System Keychain
* Untrusted Certs
* Expired Certs

## New Features

### Change path for the profile library

You can now in the application Preferences under _Library_ select a custom path to a folder where the application will store the profile save files.

If the path is empty or invalid, the default path will be used instead.

## New Preferences

### Library

* **ProfileLibraryPath**
Path to the folder where the profile settings are saved.

### Profile Defaults

* **SigningCertificateSearchSystemKeychain**
Include signing certificates from the System Keychain (default false)

* **SigningCertificateShowUntrusted**
Include signing certificates that are not considered trusted (default false)

* **SigningCertificateShowExpired**
Include signing certificates that have expired (default false)

## New Payloads

* com.apple.FileVault2 (macOS)
* com.apple.SubmitDiagInfo (macOS)

## Updated Payloads

### ManagedInstalls (Munki)

* Changed the `SoftwareRepoURL` key from required to enabled.

### com.apple.applicationaccess (Restrictions)

* Added the key `allowDiagnosticSubmission`

## Bug Fixes

* Fixed a bug where the export setting "Payload Content Style: XML" was never used even if selected.
* ...and many minor bug fixes. 

## Known Issues

* When saving a profile for the first time, on rare occasions it might not save and won't be recognized after a restart.
 (Never found a way to replicate, only rare reports. If this happens to you, please contact me or file an issue.)

## Contribute

There are many ways to contribute to this project. Here are a few listed below:

* Test and report bugs or incorrect behavior both in the UI and in the exported profiles.
* Language and spelling errors. (English is not my native language).
* Missing payloads or payload keys. (Contribute to the [ProfileManifests](https://github.com/erikberglund/ProfileManifests) repository to improve the manifests used to define all payloads, keys and their interactions.)
* Add feature requests or suggestions by opening an issue in this repository.
