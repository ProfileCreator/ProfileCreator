# ProfileCreator 0.3.0

Please report any bugs, feature requests or suggestions as an issue to this repository.

## Alternate Downloads

If the downloaded .dmg doesn't open correctly for you, please try one of the alternative downloads provided.

## ProfileCreator Wiki

Remeber that the ProfileCreator [wiki](https://github.com/erikberglund/ProfileCreator/wiki) is continuously updated with information about the application and the included payloats.

## New Features

### Icon

Thanks to the very generous Tom Bridge and [Technolutionary, LLC](https://www.technolutionary.com), we now have an Icon for ProfileCreator!

![icon](https://github.com/erikberglund/ProfileCreator/blob/master/resources/wiki/128.png)

The icon is made by the artist Katherine M. Ahern which you can find at her website: [kateahern.com](kateahern.com)

### App Updates

From this version and forward the application will show a notification whenever a new version of the app is released. 

And through the Sparkle framework you will also be able to update the application in place without needing to manually download it from GitHub.

### Notes

A text box has been added where the value for the key `pfm_note` will be shown to bring extra attention to some aspect of the payload key.

### Substitution Variables

A new key in the manifest allows the manifest creator to define available substitution variables for the specific key.

Substitution variables are shown in purple and will show a popover when hovering the mouse over them describing the variable and the source for it's replacement.

### Button: Import

An import button is now available for all keys that support drag/drop as a method of importing data for a payload key.

### Button: Remove

A "Remove" button is now available for data payload keys where files can be added. (#156)

### Additional Payload Key Information

Added additional fields to the footer introduced in version 0.2.5:

- Scope (Shows if a payload key is only supported in a subset of the scupes for the entire payload)

### On Demand loading of dynamic local preferences manifests

From this version, the local preferences generated manifest are only loaded if that option is selected from the app preferences.

### Multiple selections in tableview allowed

It is now possible to select multiple rows in a tableview.

### New build versioning system

To comply with the Sparkle framework for updates, the build number `CFBundleVersion` will from now on always be incremented for each release.

## New Payloads

- com.apple.coreservices.uiagent (macOS) (Added by @erikberglund)
- com.apple.mDNSResponder (macOS) (Added by @erikberglund)
- com.apple.security (macOS) (Added by @erikberglund)
- com.apple.screencapture (macOS) (Added by @erikberglund)
- com.apple.Siri (macOS) (Added by @erikberglund)
- com.apple.assistant.support (macOS) (Added by @erikberglund)
- com.apple.TimeMachine (macOS) (Added by @erikberglund)
- com.apple.finder (custom settings) (macOS) (Added by @erikberglund)
- com.apple.systemuiserver (macOS) (Added by @erikberglund)
- com.apple.FinalCut (macOS) (Added by @wegotoeleven)
- com.google.Keystone (macOS) (Added by @apizz)
- com.jamf.connect.login-Okta (macOS) (Added by @arekdreyer and @erikberglund)
- com.jamf.connect.login-OpenID (macOS) (Added by @arekdreyer and @erikberglund)
- com.jamf.connect.sync (macOS) (Added by @arekdreyer and @erikberglund)
- com.jamf.connect.verify (macOS) (Added by @arekdreyer and @erikberglund)

## Updated Payloads

### .GlobalPreferences
- @erikberglund added max os version for the CSUIDisable32BitWarning key and now pointing to com.apple.coreservices.uiagent for 10.14

### com.apple.loginwindow
- @WardsParadox added `HiddenUsersList`.

### com.apple.syspolicy.kernel-extension-policy
- @apizz added a `pfm_note` describing an interaction between whitelisting entire Team Identifiers and specific Team- and Bundle Identifiers.

### com.apple.airplay
- @erikberglund added import function for MAC addresses found in csv.

## Bug Fixes

- Fixed issue not being able to select menu items in PopUp Buttons inside tableviews. (#150)  
- Fixed issue where certain icons and features in Dark Mode were not being uses (#149)
- Fixed issue where the application tried to create missing folder inside it's own imported frameworks.
- Fixed issue where the file prompt in file views did not display fileextensions in the prompt if they weren't UTI types.
- Fixed issue where a Combo Box that was the target of an exclusion would not allow changing value via the PopUp button.
- Fixed issue where a Combo Box would not select the title but only the actual value whenever `pfm_range_list_titles` was specified.

## Contribute

If you wish to contribute to this project, the following things are a good starting point:

- Test and report bugs or incorrect behavior both in the UI and in the exported profiles.
- Language and spelling errors. (English is not my native language).
- Missing payloads or payload keys. (Contribute to the ProfileManifests repository to improve the manifests used to define all payloads, keys and their interactions.)
- Add feature requests or suggestions by opening an issue in this repository.
