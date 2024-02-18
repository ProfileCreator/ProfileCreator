<p align="center">
  <img width="256" height="256" src="https://github.com/ProfileCreator/ProfileCreator/blob/master/resources/wiki/256.png">
</p>

[![Latest pre-release version tag](https://img.shields.io/github/tag-date/WillYu91/ProfileCreator.svg)](https://github.com/WillYu91/ProfileCreator/releases/tag/v0.3.5) ![macOS version support](https://img.shields.io/badge/macOS-10.12%2B-success) ![Latest release download total](https://img.shields.io/github/downloads/WillYu91/ProfileCreator/v0.3.6/total)


# Download

See the latest download in [Releases](https://github.com/WillYu91/ProfileCreator/releases)

# Contribute

If you want to contribute to the payloads available in this project, please go to the ProfileManifests repo:

[ProfileManifests](https://github.com/ProfileCreator/ProfileManifests)

There is a getting started guite to describe the basics on how to create your own manifest:

[ProfileManifests - Getting Started](https://github.com/ProfileCreator/ProfileManifests/wiki/Getting-Started)

# ProfileCreator
macOS application to create configuration profiles.

![ProfileCreator](https://github.com/WillYu91/ProfileCreator/blob/master/resources/screenshots/ProfileCreator.png)

# System Requirements
ProfileCreator requires macOS 11 or newer.

# Development

## Getting started
In order to develop for ProfileCreator, the following pieces of software are required
- Xcode 14 or higher
- macOS 12.0 or higher

## Compiling
Upon first clone, please update the submodules before attempting to compile

`git submodule update --init --recursive`

In order to compile ProfileCreator, please navigate to where the Xcode Project file is located and run the following command

`xcodebuild -project ProfileCreator.xcodeproj -scheme ProfileCreator -configuration Debug`

This will compile the application and output the result in the DerivedData path as set by your Xcode preferences. The default DerivedData location will be `~/Library/Developer/Xcode/DerivedData/`.

In addition, please take a look at the [ProfileManifests](https://github.com/ProfileCreator/ProfileManifests) project which supplies ProfileCreator with its payloads is very much active!

# Have Questions?
Consult [the wiki](https://github.com/ProfileCreator/ProfileCreator/wiki). Join the conversion over in the #profilecreator channel in the [MacAdmins Slack](https://www.macadmins.org/).

# Acknowledgements

Icon is created by Katherine M. Ahern:

* [kateahern.com](https://kateahern.com)

UI Icons have been taken from the following sites:

* [icons8.com](https://icons8.com)

Open Source code included in this project:

* [WFColorCode](https://github.com/1024jp/WFColorCode)
* [Highlightr](https://github.com/raspu/Highlightr)
