// swiftlint:disable:next file_header
//  PropertyListXMLReader.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/23/2015.
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

/// The `PropertyListXMLReaderError` enum declares errors that can occur when reading data in the
/// property list XML format.
enum PropertyListXMLReaderError: Error {
    /// Indicates that the XML for the property list is invalid. 
    case invalidXML
}

/// Instances of `PropertyListXMLReader` read Property List XML data and return a property list item
/// representation of that data. These should be used to read Property List XML files instead of
/// using `NSPropertyListSerialization`s, as `PropertyListXMLReaders` create dictionaries whose
/// key/value pairs are ordered the same as in the XML.
class PropertyListXMLReader: NSObject {
    /// The property list item that the reader has read.
    private var propertyListItem: PropertyListItem?

    /// The XML data that the reader reads.
    let XMLData: Data

    /// Initializes a new `PropertyListXMLReader` with the specified XML data.
    /// - parameter XMLData: The XML data that the instance should read.
    init(XMLData: Data) {
        self.XMLData = XMLData
        super.init()
    }

    /// Reads the instance’s XML data and returns the resulting property list item. If the reader has
    /// previously read the data, it simply returns the property list item that resulted from the 
    /// previous read.
    /// 
    /// - throws: `PropertyListXMLReaderError.InvalidXML` if the instance’s XML data is not valid 
    ///       Property List XML data.
    /// - returns: A `PropertyListItem` representation of the instance’s XML data.
    func readData() throws -> PropertyListItem {
        if let propertyListItem = propertyListItem {
            return propertyListItem
        }

        let XMLDocument = try Foundation.XMLDocument(data: XMLData, options: XMLNode.Options(rawValue: 0))
        guard let propertyListXMLElement = XMLDocument.rootElement()?.children?.first as? XMLElement,
            let propertyListItem = PropertyListItem(XMLElement: propertyListXMLElement) else {
                throw PropertyListXMLReaderError.invalidXML
        }

        self.propertyListItem = propertyListItem
        return propertyListItem
    }
}

/// This private extension adds the ability to create a new `PropertyListItem` with an XML element. It
/// is used by `PropertyListXMLReader.readData()` to recursively create a property list item from a
/// Property List XML document’s root element.
extension PropertyListItem {
    /// Returns the property list item representation of the specified XML element. Returns nil if the
    /// element cannot be represented using a property list item.
    /// - parameter XMLElement: The XML element
    init?(XMLElement: Foundation.XMLElement) {
        guard let elementName = XMLElement.name else {
            return nil
        }

        switch elementName {
        case "array":
            var array = PropertyListArray()

            if let children = XMLElement.children {
                for childXMLNode in children where childXMLNode is Foundation.XMLElement {
                    guard
                        let childXMLElement = childXMLNode as? Foundation.XMLElement,
                        let element = PropertyListItem(XMLElement: childXMLElement) else {
                        return nil
                    }

                    array.append(element)
                }
            }

            self = .array(array)
        case "dict":
            var dictionary = PropertyListDictionary()

            if let children = XMLElement.children {
                guard children.count % 2 == 0 else {
                    return nil
                }

                var childGenerator = children.makeIterator()

                while let keyNode = childGenerator.next() {
                    guard let keyElement = keyNode as? Foundation.XMLElement,
                        keyElement.name == "key",
                        let key = keyElement.stringValue,
                        !dictionary.containsKey(key),
                        let valueElement = childGenerator.next() as? Foundation.XMLElement,
                        let value = PropertyListItem(XMLElement: valueElement) else {
                            return nil
                    }

                    dictionary.addKey(key, value: value)
                }
            }

            self = .dictionary(dictionary)
        case "data":
            guard let base64EncodedString = XMLElement.stringValue,
                let data = Data(base64Encoded: base64EncodedString) else {
                    return nil
            }

            self = .data(data as NSData)
        case "date":
            guard let dateString = XMLElement.stringValue,
                let date = DateFormatter.propertyListXML.date(from: dateString) else {
                    return nil
            }

            self = .date(date as NSDate)
        case "integer", "real":
            guard let numberString = XMLElement.stringValue,
                let number = NumberFormatter.propertyList.number(from: numberString) else {
                    return nil
            }

            self = .number(number)
        case "true":
            self = .boolean(true)
        case "false":
            self = .boolean(false)
        case "string":
            guard let string = XMLElement.stringValue else {
                return nil
            }

            self = .string(string as NSString)
        default:
            return nil
        }
    }
}
