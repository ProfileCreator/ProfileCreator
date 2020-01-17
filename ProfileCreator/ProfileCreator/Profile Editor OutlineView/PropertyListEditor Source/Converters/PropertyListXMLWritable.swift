// swiftlint:disable:next file_header
//  PropertyListXMLWritable.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/19/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// The `PropertyListXMLWritable` protocol defines a single method that adds a property list item’s
/// data as child XML elements of a property List XML element. It is used to save Property List XML
/// documents instead of using `NSPropertyListSerialization`; the former maintains the order or 
/// a dictionary’s key/value pairs, while the latter does not. All PropertyListItems conform to 
/// this protocol via the extensions below.
///
/// While one could conceivably use the method in this protocol directly, it is better to use
/// `PropertyListXMLWritable.propertyListXMLDocumentData()`, which will produce a complete Property
/// List XML document.
protocol PropertyListXMLWritable {
    /// Adds the conforming instance’s data to the specified XML element as children.
    /// - parameter parentXMLElement: The element to which children should be added.
    func addPropertyListXMLElement(to parentXMLElement: XMLElement)
}

/// This protocol extension adds the ability to get a complete property list XML document
extension PropertyListXMLWritable {
    /// Returns the instance’s data as the root property list type in a property list XML document.
    /// - returns: An `NSData` instance containing the XML 
    func propertyListXMLDocumentData() -> Data {
        let baseXMLString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
            "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n" +
            "<plist version=\"1.0\"></plist>"

        do {
            let document = try XMLDocument(xmlString: baseXMLString, options: XMLNode.Options(rawValue: 0))
            guard let rootElement = document.rootElement() else {
                return Data()
            }
            addPropertyListXMLElement(to: rootElement)

            return document.xmlData(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
        } catch {
            return Data()
        }
    }
}

extension PropertyListItem: PropertyListXMLWritable {
    func addPropertyListXMLElement(to parentXMLElement: XMLElement) {
        switch self {
        case let .array(array):
            array.addPropertyListXMLElement(to: parentXMLElement)
        case let .boolean(boolean):
            parentXMLElement.addChild(XMLElement(name: boolean.boolValue ? "true" : "false"))
        case let .data(data):
            parentXMLElement.addChild(XMLElement(name: "data", stringValue: data.base64EncodedString(options: [])))
        case let .date(date):
            parentXMLElement.addChild(XMLElement(name: "date", stringValue: DateFormatter.propertyListXML.string(from: date as Date)))
        case let .dictionary(dictionary):
            dictionary.addPropertyListXMLElement(to: parentXMLElement)
        case let .number(number):
            if number.isInteger {
                parentXMLElement.addChild(XMLElement(name: "integer", stringValue: "\(number.intValue)"))
            } else {
                parentXMLElement.addChild(XMLElement(name: "real", stringValue: "\(number.doubleValue)"))
            }
        case let .string(string):
            parentXMLElement.addChild(XMLElement(name: "string", stringValue: string as String))
        }
    }
}

extension PropertyListArray: PropertyListXMLWritable {
    func addPropertyListXMLElement(to parentXMLElement: XMLElement) {
        let arrayXMLElement = XMLElement(name: "array")
        for element in elements {
            element.addPropertyListXMLElement(to: arrayXMLElement)
        }

        parentXMLElement.addChild(arrayXMLElement)
    }
}

extension PropertyListDictionary: PropertyListXMLWritable {
    func addPropertyListXMLElement(to parentXMLElement: XMLElement) {
        let dictionaryXMLElement = XMLElement(name: "dict")
        for keyValuePair in elements {
            dictionaryXMLElement.addChild(XMLElement(name: "key", stringValue: keyValuePair.key))
            keyValuePair.value.addPropertyListXMLElement(to: dictionaryXMLElement)
        }

        parentXMLElement.addChild(dictionaryXMLElement)
    }
}
