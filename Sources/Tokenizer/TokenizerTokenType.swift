//
//  TokenizerToken.swift
//  Tokenizer
//
//  Created by Ulf Akerstedt-Inoue on 2019/01/08.
//  Copyright © 2019 hakkabon software. All rights reserved.
//

import Foundation

public enum TokenType: Equatable, Hashable {
    case char(Character)        // single character identifier
    case comment(String)        // single-line: // ... or # ... multi-line: /* ... */ or (* ... *)
    case eof                    // marks end of token stream, which means that "End of Text" or "End of Medium" has been reached
    case identifier(String)     // identifier defined as [_A-Za-z] ([_A-Za-z] | [0-9])*
    case invalid(TokenError)    // not valid symbol of any kind 'unrecognized'
    case keyword(String)        // keywords, eg. const, let, var, function
    case literal(String)        // quoted identifier '...' or "..."
    case number(Numerical)      // any number defined as [0-9]*
    case regex(String)          // regular expression delimited by slash characters: / ... /
    case space(Int)             // white space characters
    case symbol(String)         // symbols, eg. () {} [] + - * / : := ::= (BNF and EBNF notation)

    public var value: String {
        switch self {
        case .char(let char): return "\(char)"
        case .comment(let comment): return comment
        case .eof: return "¶"
        case .identifier(let identifier): return identifier
        case .invalid(let invalid): return "\(invalid)"
        case .keyword(let keyword): return keyword
        case .literal(let literal): return literal
        case .number(let number): return "\(number)"
        case .regex(let regex): return regex
        case .space(let n): return "\(n)"
        case .symbol(let symbol): return symbol
        }
    }
}

extension TokenType: CustomStringConvertible {

    public var description: String {
        switch self {
        case .char(let lexeme): return "character: '\(lexeme)'"
        case .comment(let lexeme): return "comment: '\(lexeme)'"
        case .eof: return "eof: ¶"
        case .identifier(let lexeme): return "identifier: '\(lexeme)'"
        case .invalid(let lexeme): return "imvalid: '\(lexeme)'"
        case .keyword(let lexeme): return "symbol: '\(lexeme)'"
        case .literal(let lexeme): return "literal: '\(lexeme)'"
        case .number(let lexeme): return "number: '\(lexeme)'"
        case .regex(let lexeme): return "regex: '\(lexeme)'"
        case .space(let n):
            return Array(repeating: " ", count: n).joined()
        case .symbol(let lexeme): return "symbol: '\(lexeme)'"
        }
    }
}

public enum Numerical: Hashable, Equatable {
    case binary(Int)
    case decimal(Int)
    case octal(Int)
    case hexadecimal(Int)
}
