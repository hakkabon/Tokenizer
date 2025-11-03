//
//  UnicodeScalarView.swift
//  Tokenizer
//
//  This is a really simple drop-in replacement for String.UnicodeScalarView
//  As of Swift 3.2, String.UnicodeScalarView no longer supports slice operations, and
//  String.UnicodeScalarView.Subsequence is ~5x slower
//
//  Only a small subset of methods are implemented, specifically the ones useful for
//  implementing a parser or lexer that consumes a string by repeatedly calling popFirst()
//
//  I've benchmarked popFirst() as ~1.2x faster than String.UnicodeScalarView in Swift 3.1
//  and ~7x faster than String.UnicodeScalarView.Subsequence in swift 3.2 and 4.0
//
//  Copyright © 2017 Nick Lockwood. All rights reserved.
//

import Foundation

public struct UnicodeScalarView {
    public typealias Index = String.UnicodeScalarView.Index
    
    private let characters: String.UnicodeScalarView
    public private(set) var startIndex: Index
    public private(set) var endIndex: Index
    
    public init(_ unicodeScalars: String.UnicodeScalarView) {
        characters = unicodeScalars
        startIndex = characters.startIndex
        endIndex = characters.endIndex
    }
    
    public init(_ string: String) {
        self.init(string.unicodeScalars)
    }
    
    public var first: UnicodeScalar? {
        return isEmpty ? nil : characters[startIndex]
    }
    
    public var isEmpty: Bool {
        return startIndex == endIndex
    }

    public var range: Range<String.Index> {
        return (startIndex ..< endIndex)
    }

    public subscript(_ index: Index) -> UnicodeScalar {
        return characters[index]
    }
    
    public func index(after index: Index) -> Index {
        return characters.index(after: index)
    }
    
    public func index(_ i: Index, offsetBy n: Int) -> Index {
        return characters.index(i, offsetBy: n)
    }
    
    public subscript(r: Range<Index>) -> UnicodeScalarView {
        var view = UnicodeScalarView(characters)
        view.startIndex = r.lowerBound
        view.endIndex = r.upperBound
        return view
    }
    
    public subscript(r: ClosedRange<Index>) -> UnicodeScalarView {
        var view = UnicodeScalarView(characters)
        view.startIndex = r.lowerBound
        view.endIndex = r.upperBound
        return view
    }
    
    public func prefix(upTo index: Index) -> UnicodeScalarView {
        var view = UnicodeScalarView(characters)
        view.startIndex = startIndex
        view.endIndex = index
        return view
    }
    
    public func suffix(from index: Index) -> UnicodeScalarView {
        var view = UnicodeScalarView(characters)
        view.startIndex = index
        view.endIndex = endIndex
        return view
    }
    
    public func dropFirst() -> UnicodeScalarView {
        var view = UnicodeScalarView(characters)
        view.startIndex = characters.index(after: startIndex)
        view.endIndex = endIndex
        return view
    }
    
    /// Returns the remaining characters
    public var unicodeScalars: String.UnicodeScalarView.SubSequence {
        return characters[startIndex ..< endIndex]
    }
    
    public mutating func popFirst() -> UnicodeScalar? {
        if isEmpty {
            return nil
        }
        let char = characters[startIndex]
        startIndex = characters.index(after: startIndex)
        return char
    }
    
    /// Will crash if n > remaining char count
    public mutating func removeFirst(_ n: Int = 1) {
        startIndex = characters.index(startIndex, offsetBy: n)
    }
    
    /// Will crash if collection is empty
    @discardableResult
    public mutating func removeFirst() -> UnicodeScalar {
        let oldIndex = startIndex
        startIndex = characters.index(after: startIndex)
        return characters[oldIndex]
    }
}

typealias _UnicodeScalarView = UnicodeScalarView

extension String {
    init(_ unicodeScalarView: _UnicodeScalarView) {
        self.init(unicodeScalarView.unicodeScalars)
    }
}

extension Substring.UnicodeScalarView {
    init(_ unicodeScalarView: _UnicodeScalarView) {
        self.init(unicodeScalarView.unicodeScalars)
    }
}
