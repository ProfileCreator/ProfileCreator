//
//  StreamReader.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

class StreamReader {

    let encoding: String.Encoding
    let chunkSize: Int
    var fileHandle: FileHandle?
    var fileData: Data?
    let delimData: Data
    var buffer: Data
    var offset = 0
    var atEof: Bool

    init?(path: String, delimiter: String = "\n", encoding: String.Encoding = .utf8, chunkSize: Int = 4_096) {

        guard let fileHandle = FileHandle(forReadingAtPath: path),
            let delimData = delimiter.data(using: encoding) else {
                return nil
        }
        self.encoding = encoding
        self.chunkSize = chunkSize
        self.fileHandle = fileHandle
        self.fileData = nil
        self.delimData = delimData
        self.buffer = Data(capacity: chunkSize)
        self.atEof = false
    }

    init?(data: Data, delimiter: String = "\n", encoding: String.Encoding = .utf8, chunkSize: Int = 4_096) {

        guard let delimData = delimiter.data(using: encoding) else {
            return nil
        }
        self.encoding = encoding
        self.chunkSize = chunkSize
        self.fileHandle = nil
        self.fileData = data
        self.delimData = delimData
        self.buffer = Data(capacity: chunkSize)
        self.atEof = false

    }

    deinit {
        self.close()
    }

    /// Return next line, or nil on EOF.
    func nextLine() -> String? {
        if self.fileHandle != nil {
            while !self.atEof {
                if let range = self.buffer.range(of: self.delimData) {
                    // Convert complete line (excluding the delimiter) to a string:
                    let line = String(data: buffer.subdata(in: 0..<range.lowerBound), encoding: self.encoding)
                    // Remove line (and the delimiter) from the buffer:
                    buffer.removeSubrange(0..<range.upperBound)
                    return line
                }
                if let tmpData = self.fileHandle?.readData(ofLength: self.chunkSize), !tmpData.isEmpty {
                    self.buffer.append(tmpData)
                } else {
                    // EOF or read error.
                    self.atEof = true
                    if !self.buffer.isEmpty {
                        // Buffer contains last line in file (not terminated by delimiter).
                        let line = String(data: self.buffer as Data, encoding: self.encoding)
                        self.buffer.count = 0
                        return line
                    }
                }
            }
        } else if let fileData = self.fileData {
            var lineData: Data?
            _ = fileData.withUnsafeBytes { (rawPtr: UnsafeRawBufferPointer) in
                let mutRawPointer = UnsafeMutableRawPointer(mutating: rawPtr.baseAddress!)
                let totalSize = fileData.count
                while !self.atEof {
                    if let range = buffer.range(of: delimData) {
                        lineData = self.buffer.subdata(in: 0..<range.lowerBound)
                        self.buffer.removeSubrange(0..<range.upperBound)
                        return
                    }
                    if self.offset < totalSize {
                        let chunkSize = self.offset + self.chunkSize > totalSize ? totalSize - self.offset : self.chunkSize
                        let chunk = Data(bytesNoCopy: mutRawPointer + self.offset, count: chunkSize, deallocator: Data.Deallocator.none)
                        self.buffer.append(chunk)
                        self.offset += chunkSize
                    } else {
                        self.atEof = true
                        if !self.buffer.isEmpty {
                            lineData = self.buffer as Data
                            self.buffer.count = 0
                            return
                        }
                    }
                }

                return ()
            }

            if let data = lineData, let line = String(data: data, encoding: self.encoding) {
                return line
            }
        }
        return nil
    }

    /// Start reading from the beginning of file.
    func rewind() {
        if let fileHandle = self.fileHandle {
            fileHandle.seek(toFileOffset: 0)
        }
        self.offset = 0
        self.buffer.count = 0
        self.atEof = false
    }

    /// Close the underlying file. No reading must be done after calling this method.
    func close() {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}

extension StreamReader: Sequence {
    func makeIterator() -> AnyIterator<String> {
        return AnyIterator {
            self.nextLine()
        }
    }
}
