//
//  NSColor+ColorCode.swift
//
//  Created by 1024jp on 2014-04-22.

/*
 The MIT License (MIT)
 
 Copyright (c) 2014-2018 1024jp
 
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

public enum ColorCodeType: Int, CaseIterable {
    
    /// 6-digit hexadecimal color code with # symbol. For example: `#ffffff`
    case hex = 1
    
    /// 3-digit hexadecimal color code with # symbol. For example: `#fff`
    case shortHex
    
    /// CSS style color code in RGB. For example: `rgb(255,255,255)`
    case cssRGB
    
    /// CSS style color code in RGB with alpha channel. For example: `rgba(255,255,255,1)`
    case cssRGBa
    
    /// CSS style color code in HSL. For example: `hsl(0,0%,100%)`
    case cssHSL
    
    /// CSS style color code in HSL with alpha channel. For example: `hsla(0,0%,100%,1)`
    case cssHSLa
    
    /// CSS style color code with keyrowd. For example: `White`
    case cssKeyword
}



/**
 This extension on NSColor allows creating NSColor instance from a CSS color code string, or color code string from a NSColor instance.
 */
public extension NSColor {
    
    /**
     Creates and returns a `NSColor` object using the given color code. Or returns `nil` if color code is invalid.
     
     Example usage:
     ```
     var type: ColorCodeType?
     let whiteColor = NSColor(colorCode: "hsla(0,0%,100%,0.5)", type: &type)
     let hex = whiteColor.colorCode(type: .hex)  // => "#ffffff"
     ```
     
     - parameter colorCode:  The CSS3 style color code string. The given code as hex or CSS keyword is case insensitive.
     - parameter type:       Upon return, contains the detected color code type.
     */
    convenience init?(colorCode: String, type: inout ColorCodeType?) {
        
        let code = colorCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let codeRange = NSRange(location: 0, length: code.utf16.count)
        
        // detect code type
        guard let (detectedType, result) = ColorCodeType.allCases.lazy
            .compactMap({ type -> (ColorCodeType, NSTextCheckingResult)? in
                let pattern: String = {
                    switch type {
                    case .hex:
                        return "^#[0-9a-fA-F]{6}$"
                    case .shortHex:
                        return "^#[0-9a-fA-F]{3}$"
                    case .cssRGB:
                        return "^rgb\\( *([0-9]{1,3}) *, *([0-9]{1,3}) *, *([0-9]{1,3}) *\\)$"
                    case .cssRGBa:
                        return "^rgba\\( *([0-9]{1,3}) *, *([0-9]{1,3}) *, *([0-9]{1,3}) *, *([0-9.]+) *\\)$"
                    case .cssHSL:
                        return "^hsl\\( *([0-9]{1,3}) *, *([0-9.]+)% *, *([0-9.]+)% *\\)$"
                    case .cssHSLa:
                        return "^hsla\\( *([0-9]{1,3}) *, *([0-9.]+)% *, *([0-9.]+)% *, *([0-9.]+) *\\)$"
                    case .cssKeyword:
                        return "^[a-zA-Z]+$"
                    }
                }()
                let regex = try! NSRegularExpression(pattern: pattern)
                
                guard let match = regex.firstMatch(in: code, range: codeRange) else {
                    return nil
                }
                return (type, match)
                
            }).first else { return nil }
        
        // create color from result
        switch detectedType {
        case .hex:
            let hex = Int(code.dropFirst(), radix: 16)!
            self.init(hex: hex)
            
        case .shortHex:
            let hex = Int(code.dropFirst(), radix: 16)!
            let r = (hex & 0xF00) >> 8
            let g = (hex & 0x0F0) >> 4
            let b = (hex & 0x00F)
            self.init(calibratedRed: CGFloat(r) / 15, green: CGFloat(g) / 15, blue: CGFloat(b) / 15, alpha: 1.0)
            
        case .cssRGB:
            let r = Double(code[result.range(at: 1)])!
            let g = Double(code[result.range(at: 2)])!
            let b = Double(code[result.range(at: 3)])!
            self.init(calibratedRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1.0)
            
        case .cssRGBa:
            let r = Double(code[result.range(at: 1)])!
            let g = Double(code[result.range(at: 2)])!
            let b = Double(code[result.range(at: 3)])!
            let a = Double(code[result.range(at: 4)])!
            self.init(calibratedRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a))
            
        case .cssHSL:
            let h = Double(code[result.range(at: 1)])!
            let s = Double(code[result.range(at: 2)])!
            let l = Double(code[result.range(at: 3)])!
            self.init(calibratedHue: CGFloat(h) / 360, saturation: CGFloat(s) / 100, lightness: CGFloat(l) / 100, alpha: 1.0)
            
        case .cssHSLa:
            let h = Double(code[result.range(at: 1)])!
            let s = Double(code[result.range(at: 2)])!
            let l = Double(code[result.range(at: 3)])!
            let a = Double(code[result.range(at: 4)])!
            self.init(calibratedHue: CGFloat(h) / 360, saturation: CGFloat(s) / 100, lightness: CGFloat(l) / 100, alpha: CGFloat(a))
            
        case .cssKeyword:
            let lowercase = code.lowercased()
            guard let hex = colorKeywordMap.first(where: { $0.key.lowercased() == lowercase })?.value else {
                    return nil
                }
            self.init(hex: hex)
        }
        
        type = detectedType
    }
    
    
    /**
     Creates and returns a `NSColor` object using the given color code. Or returns `nil` if color code is invalid.
     
     - parameter colorCode:  The CSS3 style color code string. The given code as hex or CSS keyword is case insensitive.
     */
    convenience init?(colorCode: String) {
        
        var type: ColorCodeType?
        
        self.init(colorCode: colorCode, type: &type)
    }
    
    
    /**
     Creates and returns a `NSColor` object using the given hex color code. Or returns `nil` if color code is invalid.
     
     Example usage:
     ```
     let redColor = NSColor(hex: 0xFF0000, alpha:1.0)
     let hex = redColor.colorCode(type: .hex)  // => "#ff0000"
     ```
     
     - parameter hex:        The 6-digit hexadecimal color code.
     - parameter alpha:      The opacity value of the color object.
     */
    convenience init?(hex: Int, alpha: CGFloat = 1.0) {
        
        guard (0...0xFFFFFF).contains(hex) else {
            return nil
        }
        
        let r = (hex & 0xFF0000) >> 16
        let g = (hex & 0x00FF00) >> 8
        let b = (hex & 0x0000FF)
        
        self.init(calibratedRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: alpha)
    }
    
    
    /// Creates and returns a `<String, NSColor>` paired dictionary represents all keyword colors specified in CSS3. The names are in upper camel-case.
    static var stylesheetKeywordColors: [String: NSColor] = colorKeywordMap.mapValues { NSColor(hex: $0)! }
    
    
    /**
     Returns the receiver’s color code in desired type.
     
     This method works only with objects representing colors in the `NSColorSpaceName.calibratedRGB` or `NSColorSpaceName.deviceRGB` color space. Sending it to other objects raises an exception.
     
     - parameter type:       The type of color code to format the returned string. You may use one of the types listed in `ColorCodeType`.
     - returns:              The color code string formatted in the input type.
     */
    func colorCode(type: ColorCodeType) -> String? {
        
        let r = Int(round(255 * self.redComponent))
        let g = Int(round(255 * self.greenComponent))
        let b = Int(round(255 * self.blueComponent))
        let alpha = self.alphaComponent
        
        switch type {
        case .hex:
            return String(format: "#%02x%02x%02x", r, g, b)
            
        case .shortHex:
            return String(format: "#%1x%1x%1x", r / 16, g / 16, b / 16)
            
        case .cssRGB:
            return String(format: "rgb(%d,%d,%d)", r, g, b)
            
        case .cssRGBa:
            return String(format: "rgba(%d,%d,%d,%g)", r, g, b, alpha)
            
        case .cssHSL, .cssHSLa:
            let hue = self.hueComponent
            let saturation = self.hslSaturationComponent
            let lightness = self.lightnessComponent
            
            let h = (saturation > 0) ? Int(round(360 * hue)) : 0
            let s = Int(round(100 * saturation))
            let l = Int(round(100 * lightness))
            
            if type == .cssHSLa {
                return String(format: "hsla(%d,%d%%,%d%%,%g)", h, s, l, alpha)
            }
            return String(format: "hsl(%d,%d%%,%d%%)", h, s, l)
            
        case .cssKeyword:
            let rHex = (r & 0xff) << 16
            let gHex = (g & 0xff) << 8
            let bHex = (b & 0xff)
            let hex = rHex + gHex + bHex
            return colorKeywordMap.first { $0.value == hex }?.key
        }
    }
    
}



private extension String {
    
    subscript(range: NSRange) -> SubSequence {
        
        return self[Range(range, in: self)!]
    }
    
}
