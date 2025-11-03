import Testing
@testable import Tokenizer

@Test
func testLineComment() async throws {
    let symbols: [String] = []
    let keywords: [String] = []
    let input = """
    // Lorem ipsum dolor sit amet, consectetur adipiscing elit.
    """
    let tokenizer = Tokenizer(input, symbols: Set(symbols), keywords: Set(keywords))
    let tokens = tokenizer.tokenize()
    #expect(tokenizer.isEmpty == true)
    #expect(tokens == [
        Token(type: .comment(" Lorem ipsum dolor sit amet, consectetur adipiscing elit."), range:  input.index(input.startIndex, offsetBy: +2) ..< input.endIndex)
    ])
}

@Test
func testBlockComment() async throws {
    let symbols: [String] = []
    let keywords: [String] = []
    let input = """
    /*
     * Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
     * incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
     * nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
     */
    """
    let tokenizer = Tokenizer(input, symbols: Set(symbols), keywords: Set(keywords))
    let tokens = tokenizer.tokenize()
    #expect(tokenizer.isEmpty == true)
    #expect(tokens.count == 1)
}
