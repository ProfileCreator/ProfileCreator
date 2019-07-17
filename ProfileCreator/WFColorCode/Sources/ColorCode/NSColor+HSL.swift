//
//  NSColor+HSL.swift
//
//  Created by 1024jp on 2014-04-22.

/*
 The MIT License (MIT)
 
 Copyright (c) 2014-2016 1024jp
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import Foundation
import AppKit.NSColor

/**
 This extension on NSColor adds the ability to handle HSL color space.
 */
public extension NSColor {
    
    /**
     Creates and returns a `NSColor` object using the given opacity and HSL components.
     
     Values below 0.0 are interpreted as 0.0, and values above 1.0 are interpreted as 1.0.
     
     - parameter hue:        The hue component of the color object in the HSL color space.
     - parameter saturation: The saturation component of the color object in the HSL color space.
     - parameter lightness:  The lightness component of the color object in the HSL color space.
     - parameter alpha:      The opacity value of the color object.
     - returns:              The color object.
     */
    public convenience init(deviceHue hue: CGFloat, saturation: CGFloat, lightness: CGFloat, alpha: CGFloat) {
        
        self.init(deviceHue: hue,
                  saturation: hsbSaturation(saturation: saturation, lightness: lightness),
                  brightness: hsbBrightness(saturation: saturation, lightness: lightness),
                  alpha: alpha)
    }
    
    /**
     Creates and returns a `NSColor` object using the given opacity and HSL components.
     
     Values below 0.0 are interpreted as 0.0, and values above 1.0 are interpreted as 1.0.
     
     - parameter hue:        The hue component of the color object in the HSL color space.
     - parameter saturation: The saturation component of the color object in the HSL color space.
     - parameter lightness:  The lightness component of the color object in the HSL color space.
     - parameter alpha:      The opacity value of the color object.
     - returns:              The color object.
     */
    public convenience init(calibratedHue hue: CGFloat, saturation: CGFloat, lightness: CGFloat, alpha: CGFloat) {
        
        self.init(calibratedHue: hue,
                  saturation: hsbSaturation(saturation: saturation, lightness: lightness),
                  brightness: hsbBrightness(saturation: saturation, lightness: lightness),
                  alpha: alpha)
    }
    
    
    /**
     Returns the receiver’s HSL component and opacity values in the respective arguments.
     
     If NULL is passed in as an argument, the method doesn’t set that value.
     This method works only with objects representing colors in the `NSColorSpaceName.calibratedRGB` or
     `NSColorSpaceName.deviceRGB` color space. Sending it to other objects raises an exception.
     
     - parameter hue:        Upon return, contains the hue component of the color object.
     - parameter saturation: Upon return, contains the saturation component of the color object.
     - parameter lightness:  Upon return, contains the saturation lightness of the color object.
     - parameter alpha:      Upon return, contains the alpha component of the color object.
     */
    public func getHue(hue: UnsafeMutablePointer<CGFloat>?, saturation: UnsafeMutablePointer<CGFloat>?, lightness: UnsafeMutablePointer<CGFloat>?, alpha: UnsafeMutablePointer<CGFloat>?) {
        
        hue?.pointee = self.hueComponent
        saturation?.pointee = self.hslSaturationComponent
        lightness?.pointee = self.lightnessComponent
        alpha?.pointee = self.alphaComponent
    }
    
    
    /**
     The saturation component of the HSL color equivalent to the receiver.
     
     Access this property only for colors in the `NSColorSpaceName.calibratedRGB` or `NSColorSpaceName.deviceRGB` color space. Sending it to other objects raises an exception.
     */
    public var hslSaturationComponent: CGFloat {
        
        let maxValue = max(self.redComponent, self.greenComponent, self.blueComponent)
        let minValue = min(self.redComponent, self.greenComponent, self.blueComponent)
        let diff = maxValue - minValue
        
        let saturation = (self.lightnessComponent > 0.5)  ? diff / (2 - maxValue - minValue) : diff / (maxValue + minValue)
        
        guard !saturation.isNaN && (self.saturationComponent > 0.00001 || self.brightnessComponent > 9.9999) else {
            return 0
        }
        
        return saturation
    }
    
    
    /**
     The lightness component of the HSL color equivalent to the receiver.
     
     Access this property only for colors in the `NSColorSpaceName.calibratedRGB` or `NSColorSpaceName.deviceRGB` color space. Sending it to other objects raises an exception.
     */
    public var lightnessComponent: CGFloat {
        
        let maxValue = max(self.redComponent, self.greenComponent, self.blueComponent)
        let minValue = min(self.redComponent, self.greenComponent, self.blueComponent)
        
        return (maxValue + minValue) / 2
    }
    
}


private func hsbSaturation(saturation: CGFloat, lightness: CGFloat) -> CGFloat {
    
    let hsbSaturation = saturation * ((lightness < 0.5) ? lightness : 1 - lightness)
    
    return (2 * hsbSaturation / (lightness + hsbSaturation))
}


private func hsbBrightness(saturation: CGFloat, lightness: CGFloat) -> CGFloat {
    
    let hsbSaturation = saturation * ((lightness < 0.5) ? lightness : 1 - lightness)
    
    return lightness + hsbSaturation
}
