//
//  TokenizerUtils.swift
//  Tokenizer
//
//  Created by Ulf Akerstedt-Inoue on 2019/01/08.
//  Copyright © 2019 hakkabon software. All rights reserved.
//

import Foundation

extension String {
    
    func contains(other: String) -> String.Index {
        var start = startIndex
        repeat {
            let subString = self[start ..< endIndex]
            start = self.index(after: start)
            if subString.hasPrefix(other) {
                return start
            }
        } while start < endIndex
        return startIndex
    }
    
    /// Trims prefix from string.
    func trim(prefix: String) -> String {
        return hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }

    /// Standard binary prefix
    var binaryPrefix: String { return "0b" }
    
    /// Standard octal prefix
    var octalPrefix: String { return "0o" }
    
    /// Standard hex prefix
    var hexPrefix: String { return "0x" }
  
    /// Converts string to Int value
    var integerValue: Int? { return Int(self, radix: 10) }
    
    /// Converts string to UInt value
    var unsignedIntegerValue: UInt? { return UInt(self, radix: 10) }

    /// Converts string to binary value, ignoring any 0b prefix
    var binaryValue: Int? {
        return Int(trim(prefix: binaryPrefix), radix: 2)
    }
    
    /// Converts string to octal value, ignoring any 0o prefix, supporting 0 prefix
    var octalValue: Int? {
        return Int(trim(prefix: octalPrefix), radix: 8)
    }
    
    /// Converts string to hex value. This supports 0x, 0X prefix if present
    var hexValue: Int? {
        return Int(trim(prefix: hexPrefix).trim(prefix: "0X"), radix: 16)
    }
    
    /// Converts string to its unsigned binary value, ignoring any 0b prefix
    var unsignedBinaryValue: UInt? {
        return UInt(trim(prefix: binaryPrefix), radix: 2)
    }
    
    /// Converts string to its unsigned octal value, ignoring any 0o prefix
    var unsignedOctalValue: UInt? {
        return UInt(trim(prefix: octalPrefix), radix: 8)
    }
    
    /// Converts string to unsigned hex value. This supports 0x prefix if present
    var unsignedHexValue: UInt? {
        return UInt(trim(prefix: hexPrefix).trim(prefix: "0X"), radix: 16)
    }
}

public extension String.Index {

    func lineAndColumn(in string: String) -> (line: Int, column: Int) {
        var line = 1, column = 1
        let linebreaks = CharacterSet.newlines
        let scalars = string.unicodeScalars
        var index = scalars.startIndex
        while index < self {
            if linebreaks.contains(scalars[index]) {
                line += 1
                column = 1
            } else {
                column += 1
            }
            index = scalars.index(after: index)
        }
        return (line: line, column: column)
    }
}

func lineAndColumn(for range: Range<String.Index>, in fullString: String) -> (line: Int, column: Int) {
    guard !range.isEmpty else { return (0,0) }

    let targetStartIndex = range.lowerBound
    var currentLine = 1
    var currentColumn = 1
    var currentIndex = fullString.startIndex

    while currentIndex < fullString.endIndex {
        if currentIndex == targetStartIndex {
            return (line: currentLine, column: currentColumn)
        }

        if fullString[currentIndex] == "\n" {
            currentLine += 1
            currentColumn = 1 // Reset column for the new line
        } else {
            currentColumn += 1
        }
        currentIndex = fullString.index(after: currentIndex)
    }

    return (currentLine, currentColumn)
}

extension String {
    
    // Bad preformance. Try to avoid it.
    func lineAndColumn(for range: Range<String.Index>) -> (startLine: Int, startColumn: Int, endLine: Int, endColumn: Int) {
        guard !range.isEmpty, range.lowerBound >= startIndex, range.upperBound <= endIndex else {
            return (0,0,0,0)
        }

        var currentLine = 1
        var currentColumn = 1
        var startLine: Int = 1
        var startColumn: Int = 1
        var endLine: Int = 1
        var endColumn: Int = 1

        for (index, character) in self.enumerated() {
            let stringIndex = self.index(self.startIndex, offsetBy: index)

            if stringIndex == range.lowerBound {
                startLine = currentLine
                startColumn = currentColumn
            }

            if stringIndex == range.upperBound {
                endLine = currentLine
                endColumn = currentColumn
            }

            if character.isNewline {
                currentLine += 1
                currentColumn = 1
            } else {
                currentColumn += 1
            }
        }

        // Handle the case where the range ends exactly at the end of the string
        if range.upperBound == endIndex {
            endLine = currentLine
            endColumn = currentColumn
        }
        return (startLine, startColumn, endLine, endColumn)
    }
}
