//
//  TokenizerToken.swift
//  Tokenizer
//
//  Created by Ulf Akerstedt-Inoue on 2019/01/08.
//  Copyright © 2019 hakkabon software. All rights reserved.
//

import Foundation

public enum TokenType: Equatable, Hashable {
    case symbol(String)         // symbols, eg. () {} [] + - * / : := ::= (BNF and EBNF notation)
    case keyword(String)        // keywords, eg. const, let, var, function
    case literal(String)        // quoted identifier '...' or "..."
    case identifier(String)     // identifier defined as [_A-Za-z] ([_A-Za-z] | [0-9])*
    case char(Character)        // single character identifier
    case number(Numerical)      // any number defined as [0-9]*
    case comment(String)        // single-line: // ... or # ... multi-line: /* ... */ or (* ... *)
    case space(Int)             // white space characters
    case invalid(TokenError)    // not valid symbol of any kind 'unrecognized'

    public var value: String {
        switch self {
        case .symbol(let lexeme): return lexeme
        case .keyword(let lexeme): return lexeme
        case .literal(let lexeme): return lexeme
        case .identifier(let lexeme): return lexeme
        case .char(let lexeme): return "\(lexeme)"
        case .number(let lexeme): return "\(lexeme)"
        case .comment(let lexeme): return lexeme
        case .space(let lexeme): return "\(lexeme)"
        case .invalid(let lexeme): return "\(lexeme)"
        }
    }
}

extension TokenType: CustomStringConvertible {

    public var description: String {
        switch self {
        case .symbol(let lexeme): return "symbol: '\(lexeme)'"
        case .keyword(let lexeme): return "symbol: '\(lexeme)'"
        case .literal(let lexeme): return "literal: '\(lexeme)'"
        case .identifier(let lexeme): return "identifier: '\(lexeme)'"
        case .char(let lexeme): return "character: '\(lexeme)'"
        case .number(let lexeme): return "number: '\(lexeme)'"
        case .comment(let lexeme): return "comment: '\(lexeme)'"
        case .space(let lexeme):
            return Array(repeating: " ", count: lexeme).joined()
        case .invalid(let lexeme): return "imvalid: '\(lexeme)'"
        }
    }
}

public enum Numerical: Hashable, Equatable {
    case binary(Int)
    case decimal(Int)
    case octal(Int)
    case hexadecimal(Int)
}
