//
//  TokenizerError.swift
//  Tokenizer
//
//  Created by Ulf Akerstedt-Inoue on 2023/11/11.
//  Copyright © 2023 hakkabon software. All rights reserved.
//

import Foundation

public enum TokenError: Swift.Error {
    case unexpectedEndOfTokens
    case unrecognizedInput(String)
    case unterminatedString(String)     // maybe empty string
    case malformedNumber
}

extension TokenError: CustomStringConvertible {

    public var description: String {
        switch self {
        case .unexpectedEndOfTokens:
            return "found unexpected end of tokens."
        case .unrecognizedInput(let string):
            return "found unrecognized '\(string)' in input."
        case .unterminatedString(let string):
            return "found unterminated '\(string)' in input."
        case .malformedNumber:
            return "found malformed number in input."
        }
    }
}

extension TokenError: Equatable {

    static public func == (lhs: TokenError, rhs: TokenError) -> Bool {
        switch (lhs, rhs) {
        case (.unexpectedEndOfTokens,.unexpectedEndOfTokens): return true
        case let (.unrecognizedInput(a),.unrecognizedInput(b)): return a == b
        case let (.unterminatedString(a),.unterminatedString(b)): return a == b
        case (.malformedNumber,.malformedNumber): return true
        default: return false
        }
    }
}

extension TokenError: Hashable {

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .unexpectedEndOfTokens:
            hasher.combine(self)
        case .unrecognizedInput(let string):
            hasher.combine(string)
        case .unterminatedString(let string):
            hasher.combine(string)
        case .malformedNumber:
            hasher.combine(self)
        }
    }
}
