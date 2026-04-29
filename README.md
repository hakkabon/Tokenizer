# Tokenizer

## A tokenizer written in the Swift programming language.

A tokenizer is typically implemented as a structure or class that iterates through an input string, identifying and extracting meaningful sequences of characters (tokens) based on a set of rules.
Here is a simple, illustrative example of a basic tokenizer for arithmetic expressions.

#### Basic Arithmetic Tokenizer Example

This example demonstrates tokenizing a simple string like `10 + 2 * (3 - 1)` into its components.

Output of the Example

```swift
number: 'decimal(10)' location: (start: 0, end: 2)
symbol: '+' location: (start: 3, end: 4)
number: 'decimal(2)' location: (start: 5, end: 6)
symbol: '*' location: (start: 7, end: 8)
symbol: '(' location: (start: 9, end: 10)
number: 'decimal(3)' location: (start: 10, end: 11)
symbol: '-' location: (start: 12, end: 13)
number: 'decimal(1)' location: (start: 14, end: 15)
symbol: ')' location: (start: 15, end: 16)
```

Below are examples of how the library is used within Swift source code.
This library may come handy when you need split a longer string into smaller pices that corresponds to known symbols and keywords. First, specify all known symbols and keywords and provide the input string to be tokenized.

```swift
  let symbols = ["|", "\\", "^", ":", ",", "$", ".", "\"", "¶", ">", "#", "-", "{","[", "<", "(",
   				 "'", "}", "]", ":]", ")", ";", "/", "*"]
  let keywords = ["alnum", "alpha", "ascii", "blank", "cntrl", "digit"]
  let input = "abc"
  let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords))
```

Tokenize the complete string at once.

```swift
  let input = "abc"
  let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords))
  let tokens = tokenizer.tokenize() // [.identifier("abc")]
```

Alphanumeric identifiers can be recognized character by character.

```swift
  let input = "abc"
  let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords), lexeme:: .char)
  let tokens = tokenizer.tokenize() // [.char("a"), .char("b"), .char("c")]
```

Iterate over the recognized tokens using a while loop.

```swift
  while let token = tokenizer.next() {
    switch token {
    case .symbol("-"): 
	  // ...
    case let .identifier(id): 
	  // ...
	
    }
  }
```

Tokens can be extracted by using Swift-style pattern matching and by using look-ahead into the unparsed string.

```swift
  let input = "[a-z]"
  let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords), lexeme:: .char)
	
  if tokenizer.peek(ahead: 1) == .symbol("[") { tokenizer.consume() }
  if case let .symbol(sym) = tokenizer.next() { /* ... */ }
  if tokenizer.peek(ahead: 1) == .symbol("-") { tokenizer.consume() }
  if case let .symbol(sym) = tokenizer.next() { /* ... */ }
  if case let .symbol(sym) = tokenizer.next() { /* ... */ }
```

## Install using Swift Package Manager

Use the Swift Package Manager that is included in Xcode 8.0 and all subsequent releases. Add a new dependency to your
project or add a dependency to your `PackageDescription` file referencing the `Tokenizer` module as shown below.

```swift
import PackageDescription

let package = Package(
  name: "YourProject",
  dependencies: [
    .package(name: "Tokenizer", url: "https://github.com/hakkabon/tokenizer", from: "1.0.3"),
  ]
)
```

Add `Tokenizer` as a dependency to your target(s):

```swift
targets: [
.target(
    name: "YourTarget",
    dependencies: ["Tokenizer"]),
```

## License

MIT
