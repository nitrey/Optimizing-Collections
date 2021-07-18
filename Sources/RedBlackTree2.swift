import Foundation

public final class RedBlackTree2<T: Comparable> {
    
    fileprivate var root: Node?
    
    public init() {
        self.root = nil
    }
    
    fileprivate class Node {
        var color: Color2
        var value: T
        var left: Node?
        var right: Node?
        var mutationCount: Int64
        
        required init(_ color: Color2, _ value: T, _ left: Node?, _ right: Node?) {
            self.color = color
            self.value = value
            self.left = left
            self.right = right
            self.mutationCount = 0
        }
    }
}

// MARK: - Collection

extension RedBlackTree2 {
    
    func forEach(_ body: (T) throws -> Void) rethrows {
        try root?.forEach(body)
    }
    
    func contains(_ element: T) -> Bool {
        return root?.contains(element) ?? false
    }
}

private extension RedBlackTree2.Node {
    
    func forEach(_ body: (T) throws -> Void) rethrows {
        try left?.forEach(body)
        try body(value)
        try right?.forEach(body)
    }
    
    func contains(_ element: T) -> Bool {
        if element == value {
            return true
        } else if element < value {
            return left?.contains(element) ?? false
        } else {
            return right?.contains(element) ?? false
        }
    }
}

// MARK: - Indices

public final class Weak<T: AnyObject> {
    weak var value: T?
    
    init(_ value: T) {
        self.value = value
    }
}

extension RedBlackTree2 {
    
    public struct Index {
        fileprivate weak var root: Node?
        fileprivate var path: [Weak<Node>]
        fileprivate var mutationCount: Int64?
        
        fileprivate init(root: Node?, path: [Weak<Node>]) {
            self.root = root
            self.path = path
            self.mutationCount = root?.mutationCount
        }
    }
    
    public var startIndex: Index {
        var path: [Weak<Node>] = []
        var node = root
        while let n = node {
            path.append(Weak(n))
            node = n.left
        }
        return Index(root: root, path: path)
    }
    
    public var endIndex: Index {
        return Index(root: root, path: [])
    }
    
    public subscript(_ index: Index) -> T? {
        precondition(index.isValid(for: root))
        return index.path.last!.value!.value
    }
    
    public func index(after i: Index) -> Index {
        var result = i
        formIndex(after: &result)
        return result
    }
    
    public func formIndex(after i: inout Index) {
        precondition(i.isValid(for: root))
        i.formSuccessor()
    }
    
    public func index(before i: Index) -> Index {
        var result = i
        formIndex(before: &result)
        return result
    }
    
    public func formIndex(before i: inout Index) {
        precondition(i.isValid(for: root))
        i.formPredecessor()
    }
}

// MARK: - Validation

extension RedBlackTree2.Index {
    
    fileprivate func isValid(for root: RedBlackTree2.Node?) -> Bool {
        return root === self.root && root?.mutationCount == self.mutationCount
    }
    
    fileprivate static func validate(_ left: RedBlackTree2<T>.Index, _ right: RedBlackTree2<T>.Index) -> Bool {
        return left.root === right.root
            && left.mutationCount == right.mutationCount
            && left.mutationCount == left.root?.mutationCount
    }
    
    fileprivate var current: RedBlackTree2<T>.Node? {
        guard let last = path.last else { return nil }
        return last.value
    }
}

// MARK: - Index Comparable

extension RedBlackTree2.Index: Comparable {
    
    public static func == (lhs: RedBlackTree2<T>.Index, rhs: RedBlackTree2<T>.Index) -> Bool {
        precondition(validate(lhs, rhs))
        return lhs.current === rhs.current
    }
    
    public static func < (lhs: RedBlackTree2<T>.Index, rhs: RedBlackTree2<T>.Index) -> Bool {
        precondition(validate(lhs, rhs))
        guard let left = lhs.current else { return false }
        guard let right = rhs.current else { return true }
        return left.value < right.value
    }
    
    public mutating func formSuccessor() {
        guard let current = current else { fatalError("Invalid index passed to function `formSuccessor`") }
        if var n = current.right {
            path.append(Weak(n))
            while let next = n.left {
                path.append(Weak(n))
                n = next
            }
        } else {
            path.removeLast()
            var n = current
            while let parent = self.current {
                if parent.left === n { return }
                n = parent
                path.removeLast()
            }
        }
    }
    
    public mutating func formPredecessor() {
        let current = self.current
        precondition(current != nil || root != nil)
        if var node = (current == nil) ? root : current!.left {
            path.append(Weak(node))
            while let n = node.right {
                path.append(Weak(n))
                node = n
            }
        } else {
            var n = current
            path.removeLast()
            while let parent = self.current {
                if parent.right === n { return }
                n = parent
                path.removeLast()
            }
        }
    }
}

// MARK: - Sequence

extension RedBlackTree2 {
    
    public struct Iterator: IteratorProtocol {
        
        private let tree: RedBlackTree2<T>
        private var index: RedBlackTree2<T>.Index
        
        init(_ tree: RedBlackTree2<T>) {
            self.tree = tree
            self.index = tree.startIndex
        }
        
        public mutating func next() -> T? {
            guard let last = index.path.last else {
                return nil // end index
            }
            defer { index.formSuccessor() }
            return last.value!.value
        }
    }
    
    public func makeIterator() -> Iterator {
        return Iterator(self)
    }
}

// MARK: - SortedSet

extension RedBlackTree2 {
    
    public func insert(_ newElement: T) -> (hasInserted: Bool, memberAfterInsert: T) {
        guard let root = makeRootUnique() else {
            self.root = Node(.black, newElement, nil, nil)
            return (true, newElement)
        }
        defer { root.color = .black }
        return root.insert(newElement)
    }
}

extension RedBlackTree2.Node {
    
    fileprivate func insert(_ newElement: T) -> (hasInserted: Bool, memberAfterInsert: T) {
        mutationCount += 1
        if newElement < value {
            if let left = makeLeftUnique() {
                let result = left.insert(newElement)
                if result.hasInserted { self.balance() }
                return result
            } else {
                self.left = .init(.red, newElement, nil, nil)
                return (hasInserted: true, memberAfterInsert: newElement)
            }
            
        } else if newElement > value {
            if let right = makeRightUnique() {
                let result = right.insert(newElement)
                if result.hasInserted { self.balance() }
                return result
            } else {
                self.right = .init(.red, newElement, nil, nil)
                return (hasInserted: true, memberAfterInsert: newElement)
            }
            
        } else {
            return (hasInserted: false, memberAfterInsert: value)
        }
    }
}

// MARK: - Balancing

extension RedBlackTree2.Node {
    
    fileprivate func balance() {
        guard color == .black else { return }
        if left?.color == .red {
            if left?.left?.color == .red {
                let l = left!
                let ll = l.left!
                swap(&self.value, &l.value)
                (self.left, l.left, l.right, self.right) = (ll, l.right, self.right, l)
                self.color = .red
                l.color = .black
                ll.color = .black
                return
            }
            if left?.right?.color == .red {
                let l = left!
                let lr = l.right!
                swap(&self.value, &lr.value)
                (l.right, lr.left, lr.right, self.right) = (lr.left, lr.right, self.right, lr)
                self.color = .red
                l.color = .black
                lr.color = .black
                return
            }
        }
        if right?.color == .red {
            if right?.left?.color == .red {
                let r = right!
                let rl = r.left!
                swap(&self.value, &rl.value)
                (self.left, rl.left, rl.right, r.left) = (rl, self.left, rl.left, rl.right)
                self.color = .red
                r.color = .black
                rl.color = .black
                return
            }
            if right?.right?.color == .red {
                let r = right!
                let rr = r.right!
                swap(&self.value, &r.value)
                (self.left, r.left, r.right, self.right) = (r, self.left, r.left, rr)
                self.color = .red
                r.color = .black
                rr.color = .black
                return
            }
        }
    }
}

// MARK: - Copy on write

extension RedBlackTree2 {
    
    private func makeRootUnique() -> Node? {
        if root != nil, isKnownUniquelyReferenced(&root) {
            root = root!.clone()
        }
        return root
    }
}

extension RedBlackTree2.Node {
    
    fileprivate func clone() -> RedBlackTree2.Node {
        return .init(color, value, left, right)
    }
    
    fileprivate func makeLeftUnique() -> RedBlackTree2.Node? {
        if left != nil, isKnownUniquelyReferenced(&left) {
            left = left!.clone()
        }
        return left
    }
    
    fileprivate func makeRightUnique() -> RedBlackTree2.Node? {
        if right != nil, isKnownUniquelyReferenced(&right) {
            right = right!.clone()
        }
        return right
    }
}

// MARK: - CustomStringConvertible

extension RedBlackTree2: CustomStringConvertible {
    
    public var description: String {
        return diagram(for: root)
    }
}

private func diagram<Element>(for node: RedBlackTree2<Element>.Node?,
                              _ top: String = "",
                              _ root: String = "",
                              _ bottom: String = "") -> String {
    guard let node = node else {
        return root + "•\n"
    }
    if node.left == nil && node.right == nil {
        return root + "\(node.color.symbol) \(node.value)\n"
    }
    return diagram(for: node.right, top + "    ", top + "┌───", top + "│   ")
        + root + "\(node.color.symbol) \(node.value)\n"
        + diagram(for: node.left, bottom + "│   ", bottom + "└───", bottom + "    ")
}

// MARK: - Color

fileprivate enum Color2 {
    case red
    case black
    
    var symbol: String {
        switch self {
        case .red: return "🔴"
        case .black: return "⚫️"
        }
    }
}
