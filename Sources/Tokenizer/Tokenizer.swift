import Foundation

public class Tokenizer: Sequence, IteratorProtocol {
    fileprivate var characters: UnicodeScalarView
    fileprivate var trie: Trie = Trie()
    private(set) var filterComments: Bool = false
    private(set) var symbols = Set<String>()
    private(set) var keywords = Set<String>()

    public init(source: String, filterComments filter: Bool = false, symbols: Set<String>, keywords: Set<String>) {
        characters = UnicodeScalarView(source.unicodeScalars)

        self.filterComments = filter
        self.symbols = Set(symbols)
        self.keywords = Set(keywords)

        // Insert all character-based symbols into the Trie.
        symbols.forEach { trie.insert(word: $0) }
    }

    // Generates an array of tokens from a source string. This is a very simple tokenizer
    // that parses basic arithmetic expressions.
    public func tokenize() -> [Token] {
        var tokens: [Token] = []
        while var token = nextToken() {
            if filterComments {
                while case .comment(_) = token { token = nextToken() ?? .invalid(.unexpectedEndOfTokens) }
            }
            tokens.append(token)
        }
        if !self.characters.isEmpty {
            tokens.append(.invalid(.unrecognizedInput(String(characters))))
        }

        return tokens
    }
    
    public func makeIterator() -> Tokenizer {
        return self
    }

    public func next() -> Token? {
        return nextToken()
    }
    
    // This only ever returns a single token, or nil
    func nextToken() -> Token? {
        
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
        
        // Parsed character(s) may be a symbol or a literal.
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
                if CharacterSet.letters.contains(scalar) {
                    return characters.parseIdentifier(keywords: self.keywords)
                } else {
                    if let number = self.characters.readCharacters(where: {
                        $0 >= UnicodeScalar("0") && $0 <= UnicodeScalar("9")
                    }) {
                        return .number(number)
//                        switch String(number.prefix(2)) {
//                        case number.binaryPrefix: return .number(number.binaryValue ?? 0)
//                        case number.octalPrefix: return .number(number.octalValue ?? 0)
//                        case number.hexPrefix:return .number(number.hexValue ?? 0)
//                        default: return .number(number.integerValue ?? 0)
//                        }
                    }
                }
            }
        }
        return nil
    }
    

    public var isEmpty: Bool {
        return characters.isEmpty
    }

    public var first: Character? {
        return characters.isEmpty ? nil : Character(characters[characters.startIndex])
    }
    
    public func consume() {
        return characters.removeFirst()
    }

    // Peek at current character for a symbol match.
    public func peek(match symbol: Character) -> Bool {
        if let scalar = characters.first, symbol == Character(scalar) {
            return true
        }
        return false
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
    mutating func parseBlockComment(match symbol: String) -> Token? {
        let start = self
        var string = ""
        while let scalar = self.popFirst() {
            if scalar == "*" {
                if self.popFirst() == "/" {
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
        
    // parses a token containing any consecutive digit (0-9) characters, or nil
    mutating func parseDigit() -> Token? {
        return readCharacters(where: {
            $0 >= UnicodeScalar("0") && $0 <= UnicodeScalar("9")
        })
            .map { .number($0) }
    }
    
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
