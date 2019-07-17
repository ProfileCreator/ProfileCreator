//
//  ColorCodeTests.swift
//  WFColorCode
//
//  Created by 1024jp on 2014-09-02.

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

import XCTest
import ColorCode

class ColorCodeTests: XCTestCase {

    func testColorCreation() {
        
        let whiteColor = NSColor.white.usingColorSpaceName(.calibratedRGB)
        var type: ColorCodeType?
        
        XCTAssertEqual(NSColor(colorCode: "#ffffff", type: &type), whiteColor)
        XCTAssertEqual(type, .hex)
        
        XCTAssertEqual(NSColor(colorCode: "#fff", type: &type), whiteColor)
        XCTAssertEqual(type, .shortHex)
        
        XCTAssertEqual(NSColor(colorCode: "rgb(255,255,255)", type: &type), whiteColor)
        XCTAssertEqual(type, .cssRGB)
        
        XCTAssertEqual(NSColor(colorCode: "rgba(255,255,255,1)", type: &type), whiteColor)
        XCTAssertEqual(type, .cssRGBa)
        
        XCTAssertEqual(NSColor(colorCode: "hsl(0,0%,100%)", type: &type), whiteColor)
        XCTAssertEqual(type, .cssHSL)
        
        XCTAssertEqual(NSColor(colorCode: "hsla(0,0%,100%,1)", type: &type), whiteColor)
        XCTAssertEqual(type, .cssHSLa)
        
        XCTAssertEqual(NSColor(colorCode: "white", type: &type), whiteColor)
        XCTAssertEqual(type, .cssKeyword)
        
        XCTAssertNil(NSColor(colorCode: "", type: &type))
        
        XCTAssertNil(NSColor(colorCode: "foobar", type: &type))
    }
    
    
    func testWhite() {
        
        let color = NSColor.white.usingColorSpaceName(.calibratedRGB)
        
        XCTAssertEqual(color?.colorCode(type: .hex), "#ffffff")
        XCTAssertEqual(color?.colorCode(type: .shortHex), "#fff")
        XCTAssertEqual(color?.colorCode(type: .cssRGB), "rgb(255,255,255)")
        XCTAssertEqual(color?.colorCode(type: .cssRGBa), "rgba(255,255,255,1)")
        XCTAssertEqual(color?.colorCode(type: .cssHSL), "hsl(0,0%,100%)")
        XCTAssertEqual(color?.colorCode(type: .cssHSLa), "hsla(0,0%,100%,1)")
        XCTAssertEqual(color?.colorCode(type: .cssKeyword), "White")
    }
    
    
    func testBlack() {
        
        XCTAssertEqual(NSColor(colorCode: "#000000")?.colorCode(type: .cssKeyword), "Black")
    }
    
    
    func testHSLaColorCode() {
        
        let colorCode = "hsla(203,10%,20%,0.3)"
        var type: ColorCodeType?
        let color = NSColor(colorCode: colorCode, type: &type)
        
        XCTAssertEqual(type, .cssHSLa)
        XCTAssertEqual(color?.colorCode(type: .cssHSLa), colorCode)
    }
    
    
    func testHexColorCode() {
        
        var type: ColorCodeType?
        let color = NSColor(colorCode: "#0066aa", type: &type)
        
        XCTAssertEqual(type, .hex)
        XCTAssertEqual(color?.colorCode(type: .hex), "#0066aa")
        XCTAssertEqual(color?.colorCode(type: .shortHex), "#06a")
    }
    
    
    func testHSL() {
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var lightness: CGFloat = 0
        var alpha: CGFloat = 0
        let color = NSColor(deviceHue: 0.1, saturation: 0.2, lightness: 0.3, alpha: 0.4)
        
        color.getHue(hue: &hue, saturation: &saturation, lightness: &lightness, alpha: &alpha)
        
        XCTAssertEqual(hue, 0.1, accuracy: 3)
        XCTAssertEqual(saturation, 0.2, accuracy: 3)
        XCTAssertEqual(lightness, 0.3, accuracy: 3)
        XCTAssertEqual(alpha, 0.4, accuracy: 3)
    }
    
    
    func testHex() {
        
        let color = NSColor(hex: 0xFF6600, alpha: 1.0)
        
        XCTAssertEqual(color?.colorCode(type: .hex), "#ff6600")
        XCTAssertNil(NSColor(hex: 0xFFFFFF + 1, alpha: 1.0))
    }
    
    
    func testKeyword() {
        
        var type: ColorCodeType?
        let color = NSColor(colorCode: "MidnightBlue", type: &type)
        
        XCTAssertEqual(type, .cssKeyword)
        XCTAssertEqual(color?.colorCode(type: .cssKeyword), "MidnightBlue")
        XCTAssertEqual(color?.colorCode(type: .hex), "#191970")
        XCTAssertNil(NSColor(colorCode: "foobar"))
        
        let keywordColors = NSColor.stylesheetKeywordColors
        let keyword = "Orange"
        XCTAssertEqual(keywordColors[keyword], NSColor(colorCode: keyword))
    }
    
}
