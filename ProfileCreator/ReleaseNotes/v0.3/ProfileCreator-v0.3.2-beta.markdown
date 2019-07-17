# ProfileCreator 0.3.2

Please report any bugs, feature requests or suggestions as an issue to this repository.

## Alternate Downloads

If the downloaded .dmg doesn't open correctly for you, please try one of the alternative downloads provided.

## ProfileCreator Wiki

Remeber that the ProfileCreator [wiki](https://github.com/erikberglund/ProfileCreator/wiki) is continuously updated with information about the application and the included payloats.

## New Features

### Open Source

ProfileCreator is now Open Source under the GNU General Public License v3.0.

I write about this and the reasons why I have to stop developing this application in a blog post here: 

### Ability to reorder TableView rows.

It's now possible to reorder TableView rows and to add rows directly below the selected row.

## New Payloads

- edu.psu.macoslaps (macOS) (Added by @erikberglund)
- com.apple.iWork.Numbers (macOS) (Added by @tom.case)
- com.apple.iWork.Keynote (macOS) (Added by @tom.case)
- com.apple.iWork.Pages (macOS) (Added by @tom.case)
- com.apple.iTunes (macOS) (Added by @tom.case)
- com.apple.iBooksX (macOS) (Added by @tom.case)

## Updated Payloads

### com.microsoft.rdc.macos

- @erikberglund added `ClientSettings.EnforceCredSSPSupport`

### com.apple.coreservices.uiagent

- @erikberglund and @apizz fixed a typo on the key `CSUIDisable32BitWarnings` 

### com.apple.TCC.configuration-profile-policy

- @erikberglund added the new TCC keys for 10.15.

### com.apple.Safari

- @tom.case added `CanPromptForNotifications`, `EnableExtensions`, `DidDisableIndividualExtensionsAfterRemovingOnOffSwitchIfNecessary`.

### com.apple.smartcard

- @AndrewWCarson added `tokenRemovalAction`. 

### ManagedInstall

- @apizz added `LicenseInfoURL`, 

## Bug Fixes

- Fixed issue...

## Contribute

If you wish to contribute to this project, the following things are a good starting point:

- Test and report bugs or incorrect behavior both in the UI and in the exported profiles.
- Language and spelling errors. (English is not my native language).
- Missing payloads or payload keys. (Contribute to the ProfileManifests repository to improve the manifests used to define all payloads, keys and their interactions.)
- Add feature requests or suggestions by opening an issue in this repository.
