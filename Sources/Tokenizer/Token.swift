import Foundation

public enum Token {
    case symbol(String)
    case keyword(String)
    case identifier(String)         // non quoted identifier
    case literal(String)            // quoted identifier '...' or "..."
    case number(String)
    case comment(String)            // // ... or /* ... */
    case space(Int)
    case invalid(TokenError)        // not valid symbol of any kind 'unrecognized'
}

extension Token: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .symbol(type): return "symbol: '\(type)'"
        case let .keyword(type): return "symbol: '\(type)'"
        case let .identifier(value): return "identifier: '\(value)'"
        case let .literal(value): return "literal: '\(value)'"
        case let .number(value): return "number: '\(value)'"
        case let .comment(value): return "comment: '\(value)'"
        case let .space(count): return Array(repeating: " ", count: count).joined()
        case let .invalid(value): return "imvalid: '\(value)'"
        }
    }
}

extension Token: Equatable {
    static public func == (lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case let (.symbol(a),.symbol(b)): return a == b
        case let (.keyword(a),.keyword(b)): return a == b
        case let (.identifier(a),.identifier(b)): return a == b
        case let (.literal(a),.literal(b)): return a == b
        case let (.number(a),.number(b)): return a == b
        case let (.comment(a),.comment(b)): return a == b
        case let (.space(a),.space(b)): return a == b
        case let (.invalid(a),.invalid(b)): return a == b
        default: return false
        }
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

public enum TokenError: Error, Equatable {
    case unexpectedEndOfTokens
    case unrecognizedInput(String)
    case unterminatedString
    case malformedNumber
}
