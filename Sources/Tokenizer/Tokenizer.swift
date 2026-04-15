//
//  Tokenizer.swift
//  Tokenizer
//
//  Created by Ulf Akerstedt-Inoue on 2019/01/08.
//  Copyright © 2019 hakkabon software. All rights reserved.
//

import Foundation

protocol TokenBufferDelegate {
    var characters: UnicodeScalarView { get }
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

    /// Return a single token. The `eof` token marks end of token stream.
    public func get() -> Token {
        return tokens.get()
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

        /// Provides the next token from the buffer and increments current index.
        mutating func get() -> Token {
            let token = buffer[index]
            updateBuffer()
            return token ?? Token(type: .eof, range: (delegate?.characters.endIndex)! ..< (delegate?.characters.endIndex)!)
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

    // Input source character transformed to `UnicodeScalarView`s.
    var characters: UnicodeScalarView

    // Tokens are accessed via a buffer of variable length.
    private var tokens: TokenBuffer

    // Symbols are matched using a Trie.
    private var trie = Trie<Character>.empty

    // Always keep a default set of symbols for identifying literals, line comments and block comments.
    private(set) var symbols = Set<String>(arrayLiteral: ".", ";", ":", "'", "\"", "#", "/", "//", "/*", "*/", "(*", "*)")

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
        self.symbols.forEach { symbol in
            trie = trie.inserting(symbol)
        }

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

        // Inspect matched symbol sequence: we may have a complete symbol match or we may have
        // matched the beginning of a literal or comment, in which case we proceed with further
        // parsing to complete the token. The character view will only be consumed when matched.
        if let symbolScalars = trie.longestMatch(in: &characters) {
            let symbol = String(symbolScalars)
            switch symbol {
            case "'": return characters.parseLiteral(until: "'")
            case "\"": return characters.parseLiteral(until: "\"")
            case "/": return characters.parseRegexDefinition(until: "/")
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

    /// Peek `n` tokens ahead of current token.
    public func peek(ahead n: Int) -> Token? {
        return tokens.peek(ahead: n)
    }
}
