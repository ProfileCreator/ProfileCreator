
WFColorCode
=============================

[![Build Status](http://img.shields.io/travis/1024jp/WFColorCode.svg?style=flat)](https://travis-ci.org/1024jp/WFColorCode)
[![codecov.io](https://codecov.io/gh/1024jp/WFColorCode/branch/develop/graphs/badge.svg)](https://codecov.io/gh/1024jp/WFColorCode)
[![Carthage compatible](https://img.shields.io/badge/Carthage-✔-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SPM compatible](https://img.shields.io/badge/SPM-✔-4BC51D.svg?style=flat)](https://swift.org/package-manager/)
[![CocoaPods version](http://img.shields.io/cocoapods/v/WFColorCode.svg?style=flat)](https://cocoapods.org/pods/WFColorCode)
[![CocoaPods platform](http://img.shields.io/cocoapods/p/WFColorCode.svg?style=flat)](https://cocoapods.org/pods/WFColorCode)

__WFColorCode__ is a NSColor extension that allows creating NSColor instance from a CSS color code string, or color code string from a NSColor instance.  It also adds the ability to handle HSL color space.

* __Requirements__: OS X 10.9 or later
* __ARC__: ARC enabled



Usage
-----------------------------
WFColorCode supports the following color code styles.

```swift
/// color code type
enum ColorCodeType: Int {
    case hex        // #ffffff
    case shortHex   // #fff
    case cssRGB     // rgb(255,255,255)
    case cssRGBa    // rgba(255,255,255,1)
    case cssHSL     // hsl(0,0%,100%)
    case cssHSLa    // hsla(0,0%,100%,1)
    case cssKeyword // White
};
```

### Example
Import `ColorCode` to use.

```swift
import ColorCode

// create NSColor instance from HSLa color code
var type: ColorCodeType?
let whiteColor = NSColor(colorCode: "hsla(0,0%,100%,0.5)", type: &type)
let hex: String = whiteColor.colorCode(type: .hex)  // => "#ffffff"

// create NSColor instance from HSLa values
let color = NSColor(deviceHue:0.1, saturation:0.2, lightness:0.3, alpha:1.0)

// create NSColor instance from a CSS3 keyword
let ivoryColor = NSColor(colorCode: "ivory")

// get HSL values from NSColor instance
var hue: CGFloat = 0
var saturation: CGFloat = 0
var lightness: CGFloat = 0
var alpha: CGFloat = 0
color.getHue(hue: &hue, saturation: &saturation, lightness: &lightness, alpha: &alpha)
```



Installation
-----------------------------

### Framework via Carthage
WFColorCode is Carthage compatible. Add the following line to your Cartfile.

```ruby
github "1024jp/WFColorCode" ~> 2.0.0
```

### Framework via Cocoapods
WFColorCode is also available via [CocoaPods](http://cocoapods.org). You can easily install it adding the following line to your Podfile:

```ruby
pod "WFColorCode"
```

### Swift Package Manager
WFColorCode is also Swift Package Manager compatible.

### Source files
If you use neither CocoaPods nor Carthage, place NSColor+ColorCode.swift and NSColor+HSL.swift in Classes/ directory somewhere in your project.



License
-----------------------------
© 2014-2018 1024jp.

The source code is distributed under the terms of the __MIT License__. See the bundled "[LICENSE](LICENSE)" for details.
