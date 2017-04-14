//
//  ACRAutocomplete.swift
//  Bard
//
//  Created by Reginald Tan on 2017-04-14.
//  Copyright © 2017 ROP Labs. All rights reserved.
//

import Foundation

public protocol Searchable : Hashable {
    func keywords() -> [String]
}

public class AutoComplete<T : Searchable> {
    
    var nodes : [Character : AutoComplete<T>]?
    var items  : [T]?
    
    public init() { }
    
    public func insert(object: T) {
        for string in object.keywords() {
            var tokens =  tokenize(string)
            var at = 0
            var max = tokens.count
            insert(&tokens, at: &at, max: &max, object: object)
        }
    }
    
    private func insert(inout tokens: [Character], inout at: Int, inout max: Int, object: T) {
        
        if at < max {
            
            let current = tokens[at]
            at += 1
            
            if nodes == nil {
                nodes = [Character : AutoComplete<T>]()
            }
            
            if nodes![current] == nil {
                nodes![current] = AutoComplete<T>()
            }
            
            nodes![current]!.insert(&tokens, at: &at, max: &max, object: object)
            
        } else {
            if items == nil {
                items = [T]()
            }
            items!.append(object)
        }
    }
    
    public func insert(set: [T]) {
        for object in set {
            insert(object)
        }
    }
    
    public func search(string: String) -> [T] {
        var mergedResults : Set<T>?
        
        for word in string.componentsSeparatedByString(" ") {
            var wordResults = Set<T>()
            var tokens = tokenize(word)
            find(&tokens, into: &wordResults)
            if mergedResults == nil {
                mergedResults = wordResults
            } else {
                mergedResults = mergedResults?.intersect(wordResults)
            }
        }
        
        return mergedResults == nil ? [] : Array(mergedResults!)
    }
    
    func insertAll(inout into results: Set<T>) {
        if let items = items {
            for t in items {
                results.insert(t)
            }
        }
        
        guard let nodes = nodes else {
            return
        }
        
        for (_, child) in nodes {
            child.insertAll(into: &results)
        }
    }
    
    private func find(inout tokens : [Character], inout into results: Set<T>) {
        guard tokens.count > 0 else {
            insertAll(into: &results)
            return
        }
        
        guard let nodes = nodes else {
            return
        }
        
        let current = tokens.removeAtIndex(0)

        nodes[current]?.find(&tokens, into: &results)
    }
    
    private func tokenize(string: String) -> [Character] {
        return Array(string.lowercaseString.characters)
    }
}
