//
//  UnicodeScalarView+Extensions.swift
//  Tokenizer
//
//  Copyright © 2017 Nick Lockwood. All rights reserved.
//

import Foundation

extension UnicodeScalarView {

    mutating func skipWhitespace() {
        let whitespace = CharacterSet.whitespacesAndNewlines
        while let scalar = self.first, whitespace.contains(scalar) {
            self.removeFirst()
        }
    }

    mutating func readCharacter(where matching: (UnicodeScalar) -> Bool = { _ in true }) -> UnicodeScalar? {
        guard let char = first, matching(char) else { return nil }
        let index = self.index(after: startIndex)
        self = suffix(from: index)
        return char
    }
    
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
