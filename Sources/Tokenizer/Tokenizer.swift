//
//  Tokenizer.swift
//  Tokenizer
//
//  Created by Ulf Akerstedt-Inoue on 2019/01/08.
//

import Foundation

public class Tokenizer: Sequence, IteratorProtocol {

    public enum ContextDependent {
        case none
        case binary
        case decimal
        case octal
        case hexadecimal
    }

    public enum IdentifierKind {
        case char
        case string
    }

    struct TokenBuffer {
        var tokens: [Token?] = []
        var index = 0
    }
    private var buffer: TokenBuffer = TokenBuffer()

    public var contextDependent: ContextDependent = .none
    
    fileprivate var characters: UnicodeScalarView
    fileprivate var trie: Trie = Trie()
    private(set) var filterComments: Bool = false
    private(set) var symbols = Set<String>(arrayLiteral: "'", "\"", "//", "/*", "*/")
    private(set) var keywords = Set<String>()
    private(set) var identifierKind: IdentifierKind = .string

    public init(source: String,
                buffer size: Int = 5,
                filterComments filter: Bool = false,
                symbols: Set<String>,
                keywords: Set<String>,
                identifier: IdentifierKind = .string)
    {
        buffer = TokenBuffer(tokens: Array(repeating: .none, count: size))
        characters = UnicodeScalarView(source.unicodeScalars)

        self.filterComments = filter
        self.symbols.formUnion(Set(symbols))
        self.keywords = Set(keywords)
        self.identifierKind = identifier

        // Insert all character-based symbols into the Trie.
        self.symbols.forEach { trie.insert(word: $0) }
        
        // prefill buffer
        for _ in 1...buffer.tokens.count { updateBuffer() }
        
        // start condition
        assert(buffer.index == 0)
    }

    // Generates an array of tokens from a source string.
    public func tokenize() -> [Token] {
        var tokens: [Token] = []
        while let token = next() {
            if case .comment(_) = token { if filterComments { continue } }
            tokens.append(token)
        }
        if !self.characters.isEmpty {
            tokens.append(.invalid(.unrecognizedInput(String(characters))))
        }
        return tokens
    }
    
    /// Create an iterator.
    public func makeIterator() -> Tokenizer {
        return self
    }

    /// Return a single token, or nil.
    public func next() -> Token? {
        let token = buffer.tokens[buffer.index]
        updateBuffer()
        return token
    }
    
    private func nextToken() -> Token? {
        
        // Skip all irrelevant characters until we find something.
        characters.skipWhitespace()

        // Match any symbol as long as possible (munch principle).
        guard let char = characters.first else { return nil }
        let munchNode = trie.walkSequence(for: Character(char)) { (node) in
            if self.characters.isEmpty == false {
                self.characters.removeFirst()
                return self.characters.first != nil ? Character(self.characters.first!) : nil
            } else {
                return nil
            }
        }
        
        // Remaining character(s) may contain literals, keywords or comments.
        if let symbol = munchNode.word {
            switch symbol {
            case "'": return characters.parseLiteral(until: "'")
            case "\"": return characters.parseLiteral(until: "\"")
            case "//": return characters.parseLineComment()
            case "/*": return characters.parseBlockComment(match: "*/")
            case "*/": fatalError("multiline comment illformed")
            default:
                return .symbol(symbol)
            }
        } else { // From here on we parse identifiers or numbers.
            if let scalar = characters.first, CharacterSet.alphanumerics.contains(scalar) {
                switch contextDependent {
                case .none:
                    
                    switch identifierKind {
                    case .char:
                        if let ch = self.characters.readCharacter(where: { CharacterSet.letters.contains($0) } ) {
                            return .char(Character(ch))
                        } else {
                            if let number = self.characters.readCharacters(where: {
                                $0 >= UnicodeScalar("0") && $0 <= UnicodeScalar("9")
                            }) {
                                return .number(.decimal(number.integerValue ?? 0))
                            }
                        }
                    case .string:
                        if CharacterSet.letters.contains(scalar) {
                            return characters.parseIdentifier(keywords: self.keywords)
                        } else {
                            if let number = self.characters.readCharacters(where: {
                                $0 >= UnicodeScalar("0") && $0 <= UnicodeScalar("9")
                            }) {
                                return .number(.decimal(number.integerValue ?? 0))
                            }
                        }
                    }

                case .binary:
                    if let number = self.characters.readCharacters(where: {
                        $0 == UnicodeScalar("0") || $0 == UnicodeScalar("1")
                    }) {
                        return .number(.binary(Int(number.binaryValue ?? 0)))
                    }

                case .decimal:
                    if let number = self.characters.readCharacters(where: {
                        $0 >= UnicodeScalar("0") && $0 <= UnicodeScalar("9")
                    }) {
                        return .number(.decimal(number.integerValue ?? 0))
                    }

                case .octal:
                    if let number = self.characters.readCharacters(where: {
                        $0 >= UnicodeScalar("0") && $0 <= UnicodeScalar("9")
                    }) {
                        return .number(.octal(number.octalValue ?? 0))
                    }

                case .hexadecimal:
                    if let number = self.characters.readCharacters(where: {
                        $0 >= UnicodeScalar("0") && $0 <= UnicodeScalar("9") ||
                        $0 >= UnicodeScalar("A") && $0 <= UnicodeScalar("F") ||
                        $0 >= UnicodeScalar("a") && $0 <= UnicodeScalar("f")
                    }) {
                        return .number(.octal(number.octalValue ?? 0))
                    }
                }
            }
        }
        return nil
    }

    /// Returns true if input string has been processed.
    public var isEmpty: Bool {
        return characters.isEmpty
    }

    /// Consumes one token from the buffer of tokens.
    public func consume() {
        updateBuffer()
    }

    /// Peek at current character for a symbol match.
    public func peek(ahead n: Int) -> Token? {
        assert((n>0) && n < buffer.tokens.count)
        return buffer.tokens[(buffer.index+n-1) % buffer.tokens.count]
    }

    // Fills current slot with next token and increments current index.
    private func updateBuffer() {
        buffer.tokens[buffer.index] = nextToken()
        buffer.index = (buffer.index+1) % buffer.tokens.count
    }
}

extension UnicodeScalarView {

    /// Read characters until any newline character is matched.
    mutating func parseLineComment() -> Token? {
        return readCharacters(where: {
            !CharacterSet.newlines.contains($0)
        })
        .map { .comment($0) }
    }
    
    /// Read characters until closing comment marker '*/' character is matched.
    /// Small bug: Character following a `*` is never copied when the comment match
    /// fails.
    mutating func parseBlockComment(match symbol: String) -> Token? {
        let start = self
        var string = ""
        while let scalar = self.popFirst() {
            if scalar == "*" {
               if let next = self.popFirst(), next == "/" {
                    return .comment(string)
                }
            }
            string.append(Character(scalar))
        }
        self = start
        return nil
    }

    mutating func parseLiteral(until terminator: Unicode.Scalar) -> Token? {
        var string = ""
        while let scalar = self.popFirst() {
            switch scalar {
            case terminator:
                return .literal(string)
            default:
                string.append(Character(scalar))
            }
        }
        return .invalid(.unterminatedString)
    }
        
    // Parses a token containing any consecutive digit (0-9) characters, or nil
    mutating func parseDigit() -> Token? {
        return readCharacters(where: {
            $0 >= UnicodeScalar("0") && $0 <= UnicodeScalar("9")
        })
            .map { .number(.decimal($0.integerValue ?? 0)) }
    }
    
    // Parses identifier lexically conforming to [A-Za-z] ( [A-Za-z_] | [0-9] )*
    mutating func parseIdentifier(keywords: Set<String>) -> Token? {
        guard let head = self.first, CharacterSet.letters.contains(head) else { return nil }
        
        var name = String(self.removeFirst())
        while let c = self.first, CharacterSet.alphanumerics.contains(c) || c == "_" {
            name.append(Character(self.removeFirst()))
        }
        
        if keywords.contains(name) {
            return .keyword(name)
        } else {
            return .identifier(name)
        }
    }
}
