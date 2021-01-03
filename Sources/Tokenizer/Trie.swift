//
//  Trie.swift
//  Lexer
//
//  Created by Ulf Akerstedt-Inoue on 2019/01/08.
//

import Foundation

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

    func walkSequence(for char: Character?, nextCharacter: @escaping ((Node) -> Character?) ) -> (Node, word: String?) {
        var word: String = ""
        
        func next(node: Node, character ch: Character?) -> Node {
            if let char = ch, let child = node.children[char] {
                word.append(char)
                return next(node: child, character: nextCharacter(child))
            } else {
                return node
            }
        }

        guard let char = char else { return (root,nil) }
        
        if let child = root.children[char] {
            word.append(char)
            return (next(node: child, character: nextCharacter(child)),word)
        } else {
            return (root,nil)
        }
    }
}
