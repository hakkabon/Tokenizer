//
//  TokenizerToken.swift
//  Tokenizer
//
//  Created by Ulf Akerstedt-Inoue on 2025/11/03.
//  Copyright © 2025 hakkabon software. All rights reserved.
//

import Foundation

// Define the Token structure using String.Index range
public struct Token {
    public let type: TokenType
    // A range in the *original* input string that this token occupies.
    // This provides the position data without storing a bulky SourceLocation struct
    public let range: Range<String.Index>
    
    public init(type: TokenType, range: Range<String.Index>) {
        self.type = type
        self.range = range
    }
    
    // Helper to get the actual location information from the range (aka. pretty print range),
    // requires access to the original string.
    public func location(in input: String) -> (start: Int, end: Int) {
        // Get the integer offset for the lower and upper bounds
        let startOffset = input.distance(from: input.startIndex, to: range.lowerBound)
        let endOffset = input.distance(from: input.startIndex, to: range.upperBound)
        
        return (start: startOffset, end: endOffset)
    }
}

extension Token: CustomStringConvertible {
    
    public var description: String {
        return "(\(type) range: \(range))"
    }
}

extension Token: Equatable {
    
    public static func == (lhs: Token, rhs: Token) -> Bool {
        return lhs.type == rhs.type && lhs.range == rhs.range
    }
}

extension Token: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(range)
    }
}
