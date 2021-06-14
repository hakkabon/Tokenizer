import XCTest
@testable import Tokenizer

final class TokenizerTests: XCTestCase {

    let symbols = ["|", "\\", "^", ":", ",", "$", ".", "\"", "¶", ">", "#", "-", "{","[", "<", "(",
    "(?:", "(?|", "[:", "+", "+?", "'", "}", "]", ":]", ")", ";", "/", "*", "*?", "?", "??"]

    let keywords = ["alnum", "alpha", "ascii", "blank", "cntrl", "digit",
    "graph", "lower", "print", "punct", "space", "upper", "word", "xdigit"]

    func testIterator() throws {
        let input = "abc"
        let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords))
        while let token = tokenizer.next() {
            switch token {
            case .symbol("-"): break
            case let .identifier(id): print("\(id)")
            default: break
            }
        }
        XCTAssertTrue(tokenizer.isEmpty)
    }

    func testCharIdentifier() throws {
        let input = "abc"
        let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords), identifier: .char)
        
        let tokens = tokenizer.tokenize()
        XCTAssertEqual(tokens, [.char("a"), .char("b"), .char("c")])
    }

    func testStringIdentifier() throws {
        let input = "abc"
        let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords))
        
        let tokens = tokenizer.tokenize()
        XCTAssertEqual(tokens, [.identifier("abc")])
    }

    func testPeek() throws {
        let input = "[a-z]"
        let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords))
        if tokenizer.peek(ahead: 1) == .symbol("[") {
            tokenizer.consume()
        }
        if tokenizer.peek(ahead: 1) == .symbol("a") {
            tokenizer.consume()
        }
        if tokenizer.peek(ahead: 1) == .symbol("-") {
            tokenizer.consume()
        }
        if tokenizer.peek(ahead: 1) == .symbol("z") {
            tokenizer.consume()
        }
        if tokenizer.peek(ahead: 1) == .symbol("]") {
            tokenizer.consume()
        }
        XCTAssertTrue(tokenizer.isEmpty)
    }

    func testMatchMix() throws {
        let input = "[a-z]"
        let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords))
        
        if tokenizer.peek(ahead: 1) == .symbol("[") { tokenizer.consume() }
        if case let .symbol(sym) = tokenizer.next() { XCTAssertEqual(sym, "a") }
        if tokenizer.peek(ahead: 1) == .symbol("-") { tokenizer.consume() }
        if case let .symbol(sym) = tokenizer.next() { XCTAssertEqual(sym, "z") }
        if case let .symbol(sym) = tokenizer.next() { XCTAssertEqual(sym, "]") }
        XCTAssertTrue(tokenizer.isEmpty)
    }

    func testMaximumMunch() throws {
        let input = "((?:(?|ab??*?+?"
        let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords))
        
        if tokenizer.peek(ahead: 1) == .symbol("(") { tokenizer.consume() }
        if case let .symbol(sym) = tokenizer.next() { XCTAssertEqual(sym, "(?:") }
        if case let .symbol(sym) = tokenizer.next() { XCTAssertEqual(sym, "(?|") }
        if tokenizer.peek(ahead: 1) == .identifier("ab") { tokenizer.consume() }
        if case let .symbol(sym) = tokenizer.next() { XCTAssertEqual(sym, "??") }
        if case let .symbol(sym) = tokenizer.next() { XCTAssertEqual(sym, "*?") }
        if case let .symbol(sym) = tokenizer.next() { XCTAssertEqual(sym, "+?") }
        XCTAssertTrue(tokenizer.isEmpty)
    }


    func testTokens() throws {
        let symbols = ["|", "\\", "^", ":", "=", "*", "+"]
        let keywords = ["alnum", "alpha", "ascii", "blank", "cntrl" ]
        let input =  "5 + 23 * 3 = 74"
        let tokens = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords)).tokenize()
        XCTAssertEqual(tokens, [.number(.decimal(5)), .symbol("+"), .number(.decimal(23)), .symbol("*"),
                                .number(.decimal(3)), .symbol("="), .number(.decimal(74))])
    }

    func testRegexp() throws {
        let symbols = ["|", "\\", "^", ":", ",", "$", ".", "\"", "¶", ">", "#", "-", "{","[", "<", "(",
        "(?:", "(?|", "[:", "+", "+?", "'", "}", "]", ":]", ")", ";", "/", "*", "*?", "?", "??"]
        let keywords = ["alnum", "alpha", "ascii", "blank", "cntrl", "digit", "graph", "lower", "print",
                        "punct", "space", "upper", "word", "xdigit"]
        let input = "[a-z]"
        let tokens = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords)).tokenize()
        XCTAssertEqual(tokens, [.symbol("["), .identifier("a"), .symbol("-"), .identifier("z"), .symbol("]")])
    }
}
