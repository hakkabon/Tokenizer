import XCTest
@testable import Tokenizer

final class TokenizerTests: XCTestCase {

    let symbols = ["|", "\\", "^", ":", ",", "$", ".", "\"", "¶", ">", "#", "-", "{","[", "<", "(",
    "(?:", "(?|", "[:", "+", "+?", "'", "}", "]", ":]", ")", ";", "/", "*", "*?", "?", "??"]

    let keywords = ["alnum", "alpha", "ascii", "blank", "cntrl", "digit",
    "graph", "lower", "print", "punct", "space", "upper", "word", "xdigit"]
    
    func testIterator() throws {
        let input1 = "abc"
        let tokenizer = Tokenizer(source: input1, symbols: Set(symbols), keywords: Set(keywords))
        while let _ = tokenizer.next() {
        }
        XCTAssertTrue(tokenizer.isEmpty)
    }

    func testPeek() throws {
        let input1 = "[a-z]"
        let tokenizer = Tokenizer(source: input1, symbols: Set(symbols), keywords: Set(keywords))
        if tokenizer.peek(match: "[") {
            tokenizer.consume()
        }
        if tokenizer.peek(match: "a") {
            tokenizer.consume()
        }
        if tokenizer.peek(match: "-") {
            tokenizer.consume()
        }
        if tokenizer.peek(match: "z") {
            tokenizer.consume()
        }
        if tokenizer.peek(match: "]") {
            tokenizer.consume()
        }
        XCTAssertTrue(tokenizer.isEmpty)
    }

    func testMaximumMunch() throws {
        let input1 = "((?:(?|ab??*?+?"
        let tokenizer = Tokenizer(source: input1, symbols: Set(symbols), keywords: Set(keywords))
        if tokenizer.peek(match: "(") {
            tokenizer.consume()
        }
        if case let .symbol(sym) = tokenizer.nextToken() {
            XCTAssertEqual(sym, "(?:")
        }
        if case let .symbol(sym) = tokenizer.nextToken() {
            XCTAssertEqual(sym, "(?|")
        }
        if tokenizer.peek(match: "a") {
            tokenizer.consume()
        }
        if tokenizer.peek(match: "b") {
            tokenizer.consume()
        }
        if case let .symbol(sym) = tokenizer.nextToken() {
            XCTAssertEqual(sym, "??")
        }
        if case let .symbol(sym) = tokenizer.nextToken() {
            XCTAssertEqual(sym, "*?")
        }
        if case let .symbol(sym) = tokenizer.nextToken() {
            XCTAssertEqual(sym, "+?")
        }
        XCTAssertTrue(tokenizer.isEmpty)
    }
    
    func testTokens() throws {
        let symbols = ["|", "\\", "^", ":", "=", "*", "+"]
        let keywords = ["alnum", "alpha", "ascii", "blank", "cntrl" ]
        let input =  "5 + 23 * 3 = 74"
        let tokens = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords)).tokenize()
        XCTAssertEqual(tokens, [.number("5"), .symbol("+"), .number("23"), .symbol("*"), .number("3"), .symbol("="), .number("74")])
    }

    func testRegexp() throws {
        let symbols = ["|", "\\", "^", ":", ",", "$", ".", "\"", "¶", ">", "#", "-", "{","[", "<", "(",
        "(?:", "(?|", "[:", "+", "+?", "'", "}", "]", ":]", ")", ";", "/", "*", "*?", "?", "??"]
        let keywords = ["alnum", "alpha", "ascii", "blank", "cntrl", "digit", "graph", "lower", "print", "punct", "space", "upper", "word", "xdigit"]
        let input = "[a-z]"
        let tokens = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords)).tokenize()
        XCTAssertEqual(tokens, [.symbol("["), .identifier("a"), .symbol("-"), .identifier("z"), .symbol("]")])
    }

    static var allTests = [
        ("testIterator", testIterator),
        ("testPeek", testPeek),
        ("testMaximumMunch", testMaximumMunch),
        ("testTokens", testTokens),
    ]
}
