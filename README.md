# Tokenizer

## A tokenizer written in the Swift programming language.
Simple tool that may come handy when you need split a longer string into smaller pices that corresponds to known symbols and keywords. First, specify all known symbols and keywords and provide the input string to be tokenized.

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
  let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords), identifier: .char)
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
  let tokenizer = Tokenizer(source: input, symbols: Set(symbols), keywords: Set(keywords))
	
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
