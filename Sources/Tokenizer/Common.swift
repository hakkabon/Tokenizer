//
//  Common.swift
//  Tokenizer
//
//  Created by Ulf Akerstedt-Inoue on 2019/01/08.
//

import Foundation

/// Allow pattern matching on *Characters*
func ~=(pattern: (Character) -> (Bool), value: Character) -> Bool {
    return pattern(value)
}

func isSpace(_ ch: Character) -> Bool {
    for scalar in ch.unicodeScalars {
        if CharacterSet.whitespaces.contains(scalar) { return true }
    }
    return false
}

// Skip '\n' '\r' and '\r\n'.
func isNewline(_ ch: Character) -> Bool {
    for scalar in ch.unicodeScalars {
        if CharacterSet.newlines.contains(scalar) { return true }
    }
    return false
}

// MARK: - A few useful Character extensions

extension Character {

    var value: Int32 {
        return Int32(String(self).unicodeScalars.first!.value)
    }

    var isDigit: Bool {
        return "0123456789abcdefoxX".contains(self)
    }

    var isAlphanumeric: Bool {
        return isalnum(value) != 0 || self == "_"
    }
}

// MARK: - String extensions

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
