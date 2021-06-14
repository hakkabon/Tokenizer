import XCTest
@testable import Tokenizer

final class CommentsTests: XCTestCase {

    let symbols: [String] = ["|", ".", "¶", ">", "#", "-", "{","[", "<", "(", "+", "'", "}", "]", ")", ";", "*"]
    let keywords: [String] = []
    
    func testFilterLineComment() throws {
        let input = """
        // Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        """
        let tokenizer = Tokenizer(source: input, filterComments: true, symbols: Set(symbols), keywords: Set(keywords))
        let tokens = tokenizer.tokenize()
        XCTAssertTrue(tokenizer.isEmpty)
        XCTAssertEqual(tokens, [])
    }

    func testLineComment() throws {
        let input = """
        // Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        """
        let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords))
        let tokens = tokenizer.tokenize()
        XCTAssertTrue(tokenizer.isEmpty)
        XCTAssertEqual(tokens, [.comment(" Lorem ipsum dolor sit amet, consectetur adipiscing elit.")])
    }

    func testFilterBlockComment() throws {
        let input = """
        /*
         * Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
         * incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
         * nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
         */
        
        """
        let tokenizer = Tokenizer(source: input, filterComments: true, symbols: Set(symbols), keywords: Set(keywords))
        let tokens = tokenizer.tokenize()
        XCTAssertTrue(tokenizer.isEmpty)
        XCTAssertEqual(tokens, [])
    }

    func testBlockComment() throws {
        let input = """
        /*
         * Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
         * incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
         * nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
         */
        """
        let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords))
        let tokens = tokenizer.tokenize()
        XCTAssertTrue(tokenizer.isEmpty)
        XCTAssertTrue(tokens.count == 1)
    }
}
