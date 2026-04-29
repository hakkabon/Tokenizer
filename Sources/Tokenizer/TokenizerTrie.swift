//
//  TokenizerTrie.swift
//  Tokenizer
//
//  Created by Ulf Akerstedt-Inoue on 2019/01/08.
//  Copyright © 2019 hakkabon software. All rights reserved.
//

import Foundation

/// An immutable, recursive Trie implementation.
public indirect enum Trie<Element: Hashable> {
    case empty
    case node(isTerminating: Bool, children: [Element: Trie<Element>])
}

extension Trie {

    /// Returns a NEW Trie containing the inserted sequence.
    public func inserting<S: Sequence>(_ sequence: S) -> Trie<Element> where S.Element == Element {
        var generator = sequence.makeIterator()
        return inserting(&generator)
    }

    private func inserting<I: IteratorProtocol>(_ iterator: inout I) -> Trie<Element> where I.Element == Element {
        guard let head = iterator.next() else {
            // End of sequence: mark this node as terminating
            switch self {
            case .empty:
                return .node(isTerminating: true, children: [:])
            case .node(_, let children):
                return .node(isTerminating: true, children: children)
            }
        }

        // Recursive step: update or create the child node
        var children: [Element: Trie<Element>] = switch self {
            case .node(_, let c): c
            case .empty: [:]
        }

        let child = children[head, default: Trie.empty].inserting(&iterator)
        children[head] = child
        
        // Note: If self was empty, it wasn't terminating previously, so isTerminating is false.
        return .node(isTerminating: self.isTerminating, children: children)
    }

    var isTerminating: Bool {
        if case .node(let isTerminating, _) = self { return isTerminating }
        return false
    }
}

extension Trie {

    /// Lists all valid sequences (words) contained in the Trie.
    public var words: [[Element]] {
        func discover(from node: Trie<Element>, path: [Element]) -> [[Element]] {
            guard case let .node(isTerminating, children) = node else { return [] }
            
            var results = isTerminating ? [path] : []
            for (element, child) in children {
                results += discover(from: child, path: path + [element])
            }
            return results
        }
        return discover(from: self, path: [])
    }
}

extension Trie {

    /// Finds the longest matching sequence from a UnicodeScalarView without
    /// prematurely consuming non-matching scalars.
    public func longestMatch(in scalars: inout UnicodeScalarView) -> [Element]? where Element == Character {
        var currentTrie = self
        var bestMatchEndIndex = scalars.startIndex
        var longestPath: [Element] = []
        
        var currentIndex = scalars.startIndex
        var currentPath: [Element] = []

        while currentIndex < scalars.endIndex {
            // If the current node marks a valid word, remember this position
            if currentTrie.isTerminating {
                bestMatchEndIndex = currentIndex
                longestPath = currentPath
            }

            let scalar = Character(scalars[currentIndex])
            
            // Try to move deeper
            if case let .node(_, children) = currentTrie, let nextTrie = children[scalar] {
                currentPath.append(scalar)
                currentTrie = nextTrie
                currentIndex = scalars.index(after: currentIndex)
            } else {
                break
            }
        }

        // Final check for termination at the very end of the string
        if currentTrie.isTerminating {
            bestMatchEndIndex = currentIndex
            longestPath = currentPath
        }

        // Maximum Munch: Advance the actual view only to the end of the best match
        if !longestPath.isEmpty || self.isTerminating {
//            scalars.removeFirst(scalars.distance(from: scalars.startIndex, to: bestMatchEndIndex))
            scalars.removeUntil(bestMatchEndIndex)
            return longestPath
        }

        return nil
    }
}





























#if false

class TrieNode<T: Hashable> {
    var value: T?
    weak var parent: TrieNode?
    var children: [T: TrieNode] = [:]
    var isTerminating = false
    var isLeaf: Bool {
        return children.count == 0
    }

    init(value: T? = nil, parent: TrieNode? = nil) {
        self.value = value
        self.parent = parent
    }
    
    func add(value: T) {
        guard children[value] == nil else { return }
        children[value] = TrieNode(value: value, parent: self)
    }
}

class Trie {
    typealias Node = TrieNode<Character>

    /// The number of words in the trie
    public var count: Int {
        return wordCount
    }
    /// Is the trie empty?
    public var isEmpty: Bool {
        return wordCount == 0
    }
    /// All words currently in the trie
    public var words: [String] {
        return wordsInSubtrie(rootNode: root, partialWord: "")
    }
    fileprivate let root: Node = Node()
    fileprivate var wordCount: Int = 0
}

extension Trie {

    /// Inserts a word into the trie.  If the word is already present,
    /// there is no change.
    ///
    /// - Parameter word: the word to be inserted.
    func insert(word: String) {
        guard !word.isEmpty else { return }
        var currentNode = root
        for character in word.lowercased() {
            if let childNode = currentNode.children[character] {
                currentNode = childNode
            } else {
                currentNode.add(value: character)
                currentNode = currentNode.children[character]!
            }
        }
        // Word already present?
        guard !currentNode.isTerminating else {
            return
        }
        wordCount += 1
        currentNode.isTerminating = true
    }

    /// Determines whether a word is in the trie.
    ///
    /// - Parameter word: the word to check for
    /// - Returns: true if the word is present, false otherwise.
    func contains(word: String) -> Bool {
        guard !word.isEmpty else { return false }
        var currentNode = root
        for character in word.lowercased() {
            guard let childNode = currentNode.children[character] else {
                return false
            }
            currentNode = childNode
        }
        return currentNode.isTerminating
    }
    
    /// Returns an array of words in a subtrie of the trie
    ///
    /// - Parameters:
    ///   - rootNode: the root node of the subtrie
    ///   - partialWord: the letters collected by traversing to this node
    /// - Returns: the words in the subtrie
    fileprivate func wordsInSubtrie(rootNode: Node, partialWord: String) -> [String] {
        var subtrieWords = [String]()
        var previousLetters = partialWord
        if let value = rootNode.value {
            previousLetters.append(value)
        }
        if rootNode.isTerminating {
            subtrieWords.append(previousLetters)
        }
        for childNode in rootNode.children.values {
            let childWords = wordsInSubtrie(rootNode: childNode, partialWord: previousLetters)
            subtrieWords += childWords
        }
        return subtrieWords
    }

    func longestMatch(for char: Character?, nextCharacter: @escaping ((Node) -> Character?) ) -> (Node, word: String?) {
        var word: String = ""
        
        func next(node: Node, character ch: Character?) -> Node {
            if let char = ch, let child = node.children[char] {
                word.append(char)
                return next(node: child, character: nextCharacter(child))
            } else {
                return node
            }
        }

        guard let char = char else { return (root, nil) }
        
        if let child = root.children[char] {
            word.append(char)
            return (next(node: child, character: nextCharacter(child)), word)
        } else {
            return (root, nil)
        }
    }
}

#endif
