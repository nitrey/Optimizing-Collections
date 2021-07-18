import Foundation

public enum RedBlackTree<T: Comparable> {
    case empty
    indirect case node(_ color: Color, _ element: T, _ left: RedBlackTree<T>, _ right: RedBlackTree<T>)
    
    public init() {
        self = .empty
    }
}

// MARK: - SortedSet

extension RedBlackTree {
    
    public func contains(_ element: T) -> Bool {
        switch self {
        case .empty:
            return false
        case .node(_, let value, let left, let right):
            if element == value {
                return true
            } else if element < value {
                return left.contains(element)
            } else {
                return right.contains(element)
            }
        }
    }
    
    @discardableResult
    public mutating func insert(_ newElement: T) -> (hasInserted: Bool, memberAfterInsert: T) {
        let (tree, old) = self.inserting(newElement)
        self = tree
        if let old = old {
            return (false, old)
        } else {
            return (true, newElement)
        }
    }
    
    public func inserting(_ newElement: T) -> (tree: RedBlackTree, existingMember: T?) {
        let (tree, existingMember) = _inserting(newElement)
        if case let (.node(.red, value, left, right)) = tree {
            let fixedTree: RedBlackTree = .node(.black, value, left, right)
            return (fixedTree, existingMember)
        } else {
            return (tree, existingMember)
        }
    }
    
    // MARK: - Private
    
    private func _inserting(_ newElement: T) -> (tree: RedBlackTree, existingMember: T?) {
        switch self {
        case .empty:
            let tree: RedBlackTree = .node(.red, newElement, .empty, .empty)
            return (tree, nil)
        case .node(_, newElement, _, _):
            return (self, nil)
        case let .node(color, value, left, right) where value > newElement:
            let (newLeft, oldValue) = left._inserting(newElement)
            if let old = oldValue {
                return (tree: self, existingMember: old)
            } else {
                let tree = balancedTree(color, value, newLeft, right)
                return (tree: tree, existingMember: nil)
            }
        case let .node(color, value, left, right):
            let (newRight, oldValue) = right._inserting(newElement)
            if let old = oldValue {
                return (tree: self, existingMember: old)
            } else {
                let tree = balancedTree(color, value, left, newRight)
                return (tree: tree, existingMember: nil)
            }
        }
    }
    
    private func balancedTree(_ color: Color, _ value: T, _ left: RedBlackTree<T>, _ right: RedBlackTree<T>) -> RedBlackTree<T> {
        switch (color, value, left, right) {
        case let (.black, z, .node(.red, y, .node(.red, x, a, b), c), d):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
            
        case let (.black, z, .node(.red, x, a, .node(.red, y, b, c)), d):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
            
        case let (.black, x, a, .node(.red, z, .node(.red, y, b, c), d)):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
            
        case let (.black, x, a, .node(.red, y, b, .node(.red, z, c, d))):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
            
        default:
            return .node(color, value, left, right)
        }
    }
}

// MARK: - Index

extension RedBlackTree {
    
    public struct Index: Comparable {
        fileprivate var value: T?
        
        public static func == (lhs: Index, rhs: Index) -> Bool {
            lhs.value == rhs.value
        }
        
        public static func < (lhs: Index, rhs: Index) -> Bool {
            if let lv = lhs.value, let rv = rhs.value {
                return lv < rv
            } else {
                return lhs.value != nil
            }
        }
    }
}

// MARK: - Collection

extension RedBlackTree: Collection {
    
    public func forEach(_ body: (T) throws -> Void) rethrows {
        guard case .node(_, let value, let left, let right) = self else { return }
        try left.forEach(body)
        try body(value)
        try right.forEach(body)
    }
    
    public var count: Int {
        switch self {
        case .empty:
            return 0
        case let .node(_, _, left, right):
            return left.count + 1 + right.count
        }
    }
    
    public func min() -> T? {
        switch self {
        case .empty:
            return nil
        case let .node(_, value, left, _):
            return left.min() ?? value
        }
    }
    
    public func max() -> T? {
        var current = self
        var maxValue: T?
        while case let .node(_, value, _, right) = current {
            maxValue = value
            current = right
        }
        return maxValue
    }
    
    public var startIndex: Index {
        Index(value: self.min())
    }
    
    public var endIndex: Index {
        Index(value: nil)
    }
    
    public subscript(i: Index) -> T {
        return i.value!
    }
    
    public func index(after i: Index) -> Index {
        guard let element = i.value else { fatalError("Out of range index") }
        let (hasFound, next) = self.value(following: element)
        precondition(hasFound, "Invalid index passed as input. Tree doesn't contain value of index.")
        return Index(value: next)
    }
    
    public func index(before i: Index) -> Index {
        if let element = i.value {
            let (hasFound, previous) = value(preceding: element)
            precondition(hasFound, "Invalid index passed as input. Tree doesn't contain value of index.")
            return Index(value: previous)
        } else {
            guard let max = self.max() else { fatalError("Out of range index") }
            return Index(value: max)
        }
    }
    
    // MARK: - Private
    
    private func value(following element: T) -> (hasFound: Bool, next: T?) {
        switch self {
        case .empty:
            return (false, nil)
        case .node(_, element, _, let right):
            return (true, right.min())
        case let .node(_, value, left, _) where value > element:
            let (hasFound, next) = left.value(following: element)
            return (hasFound, next ?? value)
        case let .node(_, _, _, right):
            return right.value(following: element)
        }
    }
    
    private func value(preceding element: T) -> (hasFound: Bool, next: T?) {
        var node: RedBlackTree = self
        var lastFound: T?
        while case let .node(_, value, left, right) = node {
            if value < element {
                lastFound = value
                node = left
            } else if value > element {
                node = right
            } else { // if value == element
                return (true, left.max() ?? lastFound)
            }
        }
        return (false, lastFound)
    }
}

// MARK: - CustomStringConvertible

extension RedBlackTree: CustomStringConvertible {
    
    public var description: String {
        diagram("", "", "")
    }
    
    private func diagram(_ top: String, _ root: String, _ bottom: String) -> String {
        switch self {
        case .empty:
            return root + "•\n"
        case let .node(color, value, .empty, .empty):
            return root + "\(color.symbol) \(value)\n"
        case let .node(color, value, left, right):
            return right.diagram(top + "    ", top + "┌───", top + "│   ")
                + root + "\(color.symbol) \(value)\n"
                + left.diagram(bottom + "│   ", bottom + "└───", bottom + "    ")
        }
    }
}

// MARK: - Color

public enum Color {
    case red
    case black
    
    var symbol: String {
        switch self {
        case .red: return "🔴"
        case .black: return "⚫️"
        }
    }
}
