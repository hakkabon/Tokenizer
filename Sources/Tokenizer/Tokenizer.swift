//
//  Tokenizer.swift
//  Tokenizer
//
//  Created by Ulf Akerstedt-Inoue on 2019/01/08.
//  Copyright © 2019 hakkabon software. All rights reserved.
//

import Foundation

protocol TokenBufferDelegate {
    func nextToken() -> Token?
}

extension Tokenizer: Sequence, IteratorProtocol {

    /// Returns an iterator to iterate over tokens, one by one.
    public func makeIterator() -> Tokenizer {
        return self
    }

    /// Return a single token, or nil.
    public func next() -> Token? {
        return tokens.next()
    }
}

public class Tokenizer: TokenBufferDelegate {

    struct TokenBuffer {
        var buffer: [Token?]
        var index: Int = 0
        var delegate: TokenBufferDelegate?

        /// Initialize `TokenBuffer` with with given buffer size.
        init(_ bufferSize: Int) {
            buffer = Array(repeating: .none, count: bufferSize)
        }

        /// Prefill buffer with token values.
        mutating func initialize() {
            for _ in 1...buffer.count { updateBuffer() }
        }
        
        /// Fills current slot with next token and increments current index.
        mutating func updateBuffer() {
            buffer[index] = delegate?.nextToken()
            index = (index+1) % buffer.count
        }

        /// Provides the next token from the buffer and increments current index.
        mutating func next() -> Token? {
            let token = buffer[index]
            updateBuffer()
            return token
        }

        /// Consumes one token from the buffer of tokens.
        mutating func consume() {
            updateBuffer()
        }

        /// Peek at current character for a symbol match.
        func peek(ahead n: Int) -> Token? {
            assert((n>0) && n < buffer.count)
            return buffer[(index+n-1) % buffer.count]
        }
    }
    
    /// Tokens are identified character by character or strings.
    /// Character type is useful when tokenizing regular expressions.
    public enum LexemeType {
        case char
        case string
    }

    // Input source character.
//    var source: String = ""

//    private var currentIndex: String.Index

    // Input source character transformed to `UnicodeScalarView`s.
    var characters: UnicodeScalarView

    // Tokens are accessed via a buffer of variable length.
    private var tokens: TokenBuffer

    // Symbols and keywords and stored and matched using a Trie.
    fileprivate var trie: Trie = Trie()

    // Always keep a default set of symbols for identifying literals, line comments and block comments.
    private(set) var symbols = Set<String>(arrayLiteral: ".", ";", ":", "'", "\"", "#", "//", "/*", "*/", "(*", "*)")

    // No default set of keywords.
    private(set) var keywords = Set<String>()

    // Default identifier type is string based.
    private(set) var lexemeType: LexemeType = .string

    public init(_ source: String, buffer size: Int = 5, symbols: Set<String>, keywords: Set<String>, lexeme: LexemeType = .string) {
        
        self.characters = UnicodeScalarView(source.unicodeScalars)
        
        self.symbols.formUnion(Set(symbols))
        self.keywords = Set(keywords)
        self.lexemeType = lexeme

        // Create and initialize the token buffer.
        self.tokens = TokenBuffer(size)
        self.tokens.delegate = self

        // Insert all character-based symbols into the Trie.
        self.symbols.forEach { trie.insert(word: $0) }
        // Token buffer has to be initialized last, after all symbols and keywords are inserted into the Trie.
        self.tokens.initialize()
    }

    /// Generates an array of tokens from a source string.
    public func tokenize() -> [Token] {
        var tokens: [Token] = []
        while let token = next() {
            tokens.append(token)
        }
        // If there are still characters left unrecognized, the tokenizer is in an error state,
        // and the remaining characters are handled as `.unrecognizedInput(_,_)`.
        let lexeme = String(characters)
        if !self.characters.isEmpty {
            tokens.append(
                Token(type: TokenType.invalid(TokenError.unrecognizedInput(lexeme)), range: characters.range)
            )
        }
        return tokens
    }

    /// Processes input characters from start to end in order to find chunks of characters that
    /// are grouped into certain defined token classes. The purpose is to give meaning to a
    /// stream of characters, the tokens, and ignore anything else contained in the character
    /// stream.
    func nextToken() -> Token? {
        // Skip all irrelevant characters until we find something.
        characters.skipWhitespace()

        // Match any symbol as long as possible (munch principle).
        let munchIndex = characters.startIndex
        guard let char = characters.first else { return nil }
        let munchNode = trie.longestMatch(for: Character(char)) { (node) in
            // if first `char` matched, try next character from characters, if there is any.
            self.characters.removeFirst()
            return self.characters.first != nil ? Character(self.characters.first!) : nil
        }

        // Inspect matched symbol sequence: we may have a complete symbol match or we may have
        // matched the beginning of a literal or comment, in which case we proceed with further
        // parsing to complete the token.
        if let symbol = munchNode.word {
            switch symbol {
            case "'": return characters.parseLiteral(until: "'")
            case "\"": return characters.parseLiteral(until: "\"")
            case "#": return characters.parseLineComment()
            case "//": return characters.parseLineComment()
            case "/*": return characters.parseBlockComment(match: "*/")
            case "(*": return characters.parseBlockComment(match: "*)")
            case "*/": fatalError("multiline comment illformed")
            case "*)": fatalError("multiline comment illformed")
            default:
                return Token(type: .symbol(symbol), range: munchIndex ..< characters.startIndex)
            }
        }
        
        // If we don't have any symbols maching so far, we have to look for
        // identifiers keywords, or numbers in the remaining character(s).
        else { // From here on we parse identifiers or numbers.
            if let scalar = characters.first, CharacterSet.alphanumerics.contains(scalar) {
                switch lexemeType {
                case .char:
                    if CharacterSet.letters.contains(scalar) {
                        return characters.parseCharacter()
                    } else {
                        return characters.parseDigits()
                    }
                case .string:
                    if CharacterSet.letters.contains(scalar) {
                        return characters.parseIdentifier(keywords: self.keywords)
                    } else {
                        return characters.parseDigits()
                    }
                }
            }
        }
        
        // If we get here, we have something we cannot make any sense of.
        // The token classes may not be sufficient to cover the complete problem domain.
        return nil
    }

    /// Returns true if input string has been processed.
    public var isEmpty: Bool {
        return characters.isEmpty
    }

    /// Consumes one token from the buffer of tokens.
    public func consume() {
        tokens.consume()
    }

    /// Peek at current character for a symbol match.
    public func peek(ahead n: Int) -> Token? {
        return tokens.peek(ahead: n)
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
    
    /// Read characters until closing comment marker '*/' or '*)' character is matched.
    mutating func parseBlockComment(match symbol: String) -> Token? {
        precondition(symbol.unicodeScalars.count == 2)
        let symbolUnicodeScalars = Array(symbol.unicodeScalars)
        let start = self
        var string = ""
        while let scalar = self.popFirst() {
            if scalar == symbolUnicodeScalars[0] {
               if let next = self.popFirst(), next == symbolUnicodeScalars[1] {
                   return Token( type: .comment(string), range: start.startIndex ..< self.endIndex)
                }
            }
            string.append(Character(scalar))
        }
        self = start
        return nil
    }

    // Parse character token containing exactly one character.
    mutating func parseCharacter() -> Token? {
        let startIndex = self.startIndex
        guard let ch = readCharacter(where: { CharacterSet.letters.contains($0) } ) else {
            return nil
        }
        return Token(type: .char(Character(ch)), range: startIndex ..< self.startIndex)
    }

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
        
    // Parses a token containing any consecutive digit (0-9) characters, or nil
    mutating func parseDigits() -> Token? {
        let startIndex = self.startIndex
        return readCharacters(where: {
            $0 >= UnicodeScalar("0") && $0 <= UnicodeScalar("9")
        })
        .map { Token(type: .number(.decimal($0.integerValue ?? 0)), range: startIndex ..< self.startIndex) }
    }
    
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
    
    func extractSubstring(source: UnicodeScalarView, from range: Range<String.Index>) -> String {
        return String(source[range.lowerBound ..< range.upperBound])
    }
}
