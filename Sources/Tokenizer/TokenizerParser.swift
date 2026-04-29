//
//  TokenizerParser.swift
//  Tokenizer
//
//  Created by Ulf Akerstedt-Inoue on 2026/04/15.
//  Copyright © 2026 hakkabon software. All rights reserved.
//

import Foundation

extension UnicodeScalarView {
    
    /// Read characters until enclosing forward-slash character is matched.
    mutating func parseRegexDefinition(until terminator: Unicode.Scalar) -> Token? {
        var string = ""
        let startIndex = self.startIndex
        while let scalar = self.popFirst() {
            switch scalar {
            case terminator:
                return Token(type: .regex(string), range: startIndex ..< self.index(self.startIndex, offsetBy: -1))
            default:
                string.append(Character(scalar))
            }
        }
        return Token(type: .invalid(.unterminatedString(string)), range: startIndex ..< self.startIndex)
    }
}

extension UnicodeScalarView {
    
    /// Read characters until any newline character is matched.
    mutating func parseLineComment() -> Token? {
        let startIndex = self.startIndex
        return readCharacters(where: {
            !CharacterSet.newlines.contains($0)
        })
        .map { Token(type: .comment($0), range: startIndex ..< self.startIndex) }
    }
}

extension UnicodeScalarView {

    /// Read characters until closing comment marker '*/' or '*)' character is matched.
    mutating func parseBlockComment(match symbol: String) -> Token? {
        precondition(symbol.unicodeScalars.count == 2)
        let symbolUnicodeScalars = Array(symbol.unicodeScalars)
        let start = self
        var string = ""
        while let scalar = self.popFirst() {
            if scalar == symbolUnicodeScalars[0] {
                if let next = self.popFirst(), next == symbolUnicodeScalars[1] {
                    return Token(type: .comment(string), range: start.startIndex ..< self.endIndex)
                }
            }
            string.append(Character(scalar))
        }
        self = start
        return nil
    }
}

extension UnicodeScalarView {

    // Parse character token containing exactly one character.
    mutating func parseCharacter() -> Token? {
        let startIndex = self.startIndex
        guard let ch = readCharacter(where: { CharacterSet.letters.contains($0) } ) else {
            return nil
        }
        return Token(type: .char(Character(ch)), range: startIndex ..< self.startIndex)
    }
}

extension UnicodeScalarView {

    // Parse literal string containing any character until closing `terminator` character is matched.
    mutating func parseLiteral(until terminator: Unicode.Scalar) -> Token? {
        var string = ""
        let startIndex = self.startIndex
        while let scalar = self.popFirst() {
            switch scalar {
            case terminator:
                return Token(type: .literal(string), range: startIndex ..< self.index(self.startIndex, offsetBy: -1))
            default:
                string.append(Character(scalar))
            }
        }
        return Token(type: .invalid(.unterminatedString(string)), range: startIndex ..< self.startIndex)
    }
}

extension UnicodeScalarView {

    // Parses a token containing any consecutive digit (0-9) characters, or nil
    mutating func parseDigits() -> Token? {
        let startIndex = self.startIndex
        return readCharacters(where: {
            $0 >= UnicodeScalar("0") && $0 <= UnicodeScalar("9")
        })
        .map { Token(type: .number(.decimal($0.integerValue ?? 0)), range: startIndex ..< self.startIndex) }
    }
}

extension UnicodeScalarView {

    // Parses identifier lexically conforming to [A-Za-z] ( [A-Za-z_-] | [0-9] )*
    mutating func parseIdentifier(keywords: Set<String>) -> Token? {
        guard let head = self.first, CharacterSet.letters.contains(head) else { return nil }
        
        let startIndex = self.startIndex
        var name = String(self.removeFirst())
        while let c = self.first, CharacterSet.alphanumerics.contains(c) || c == "_" || c == "-" {
            name.append(Character(self.removeFirst()))
        }
        
        if keywords.contains(name) {
            return Token(type: .keyword(name), range: startIndex ..< self.startIndex)
        } else {
            return Token(type: .identifier(name), range: startIndex ..< self.startIndex)
        }
    }
}

extension UnicodeScalarView {
    
    mutating func skipWhitespace() {
        let whitespace = CharacterSet.whitespacesAndNewlines
        while let scalar = self.first, whitespace.contains(scalar) {
            self.removeFirst()
        }
    }
}

extension UnicodeScalarView {
    
    mutating func readCharacter(where matching: (UnicodeScalar) -> Bool = { _ in true }) -> UnicodeScalar? {
        guard let char = first, matching(char) else { return nil }
        let index = self.index(after: startIndex)
        self = suffix(from: index)
        return char
    }
}

extension UnicodeScalarView {
    
    mutating func readCharacters(where matching: (UnicodeScalar) -> Bool) -> String? {
        var index = startIndex
        var count = 0
        
        while index < endIndex {
            if !matching(self[index]) {
                break
            }
            index = self.index(after: index)
            count += 1
        }
        
        if index > startIndex {
            let string = String(prefix(upTo: index))
            self = suffix(from: index)
            return string
        }
        return nil
    }
}

extension UnicodeScalarView {

    func extractSubstring(source: UnicodeScalarView, from range: Range<String.Index>) -> String {
        return String(source[range.lowerBound ..< range.upperBound])
    }
}
