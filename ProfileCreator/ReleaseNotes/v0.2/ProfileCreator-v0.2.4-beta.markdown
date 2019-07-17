# ProfileCreator 0.2.4 (Beta 9)

Please report any bugs, feature requests or suggestions as an issue to this repository.

## New Features

## Updated Features

#### ProfileManifest Repository

Much work has gone into updating the [ProfileManifest](https://github.com/erikberglund/ProfileManifests) Repository.

* The [Getting Started](https://github.com/erikberglund/ProfileManifests/wiki/Getting-Started) wiki page is now completed to guide anyone to creating their own manifests for ProifleCreator.
* [Manifest Format Version 4](https://github.com/erikberglund/ProfileManifests/wiki/Manifest-Format-Versions#format-version-4) was added with new keys.

#### Manifest Alias Key

A new alias was added to the `pfm_type` values. Now it's possible to write `real` as well as `float` to describe a floating point value type.

(https://github.com/erikberglund/ProfileCreator/issues/86)

#### Checkbox for `pfm_range_list` choice.

A new option was added to allow a `pfm_range_list` with exactly two items in it's array to be represented as a checkbox.

## New Preferences

## Updated Preferences

## New Payloads

* com.apple.security.certificatetransparency (macOS)
* com.apple.Enterprise-Connect (macOS)
* com.google.Chrome (macOS)
* com.github.salopensource.sal (macOS)
* com.pratikkumar.airserver-mac (macOS) (Added by @apizz) (https://github.com/erikberglund/ProfileManifests/pull/9)
* com.sqwarq.DetectX-Swift (macOS) (Added by @apizz) (https://github.com/erikberglund/ProfileManifests/pull/9)
* menu.nomad.shares (macOS) (Added by @apizz) (https://github.com/erikberglund/ProfileManifests/pull/9)
* com.apple.Spotlight (macOS) (Added by @apizz) (https://github.com/erikberglund/ProfileManifests/pull/12)
* com.apple.TextEdit (macOS) (Added by @apizz) (https://github.com/erikberglund/ProfileManifests/pull/12)
* com.apple.logic10 (macOS) (Added by @walkintom)

## Updated Payloads

Updated all payloads currently in ProfileCreator with the changes in the latest Configuration Profile Reference. 

* com.apple.mail.managed
* com.apple.security.FDERecoveryRedirect
* com.apple.SetupAssistant.managed
* com.apple.wifi.managed

### .GlobalPreferences

* @Zolotkey added the key `MultipleSessionEnabled` (https://github.com/erikberglund/ProfileManifests/pull/6)

### com.apple.SoftwareUpdate

* @kevinmcox added the key `SUDisableEVCheck`. (https://github.com/erikberglund/ProfileManifests/pull/7)

### com.microsoft.Word

* @kevinmcox added the key `DisableResumeAssistant` (https://github.com/erikberglund/ProfileManifests/pull/10)

### com.apple.dock

* @qu1gl3s added the key `show-recents` (https://github.com/erikberglund/ProfileManifests/pull/14)


## Bug Fixes

* Fixed a bug when entering fingerprint with invalid characters in the SCEP payload.
* Fixed a bug where you could only add one item to an array of dictionaries before you had to de-select and re-select the payload to add another.
* Fixed a bug in the base642data value processor where the conversion from data to string sometimes returned nil.
* Fixed a bug where a payload key contained a period (.) at the root of the KeyPath it would be set incorrectly.
* Fixed a bug where the exclusion message was hidden if a textfield was larger than 1 line. (https://github.com/erikberglund/ProfileCreator/issues/87)
* Fixed a bug where the exclusion condition was not updated when text was entered in text fields. (https://github.com/erikberglund/ProfileCreator/issues/83)
* Fixed a bug where an array inside a dictionary did not store the entered value correct until you saved, closed and reopened the profile. (https://github.com/erikberglund/ProfileCreator/issues/82)
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
