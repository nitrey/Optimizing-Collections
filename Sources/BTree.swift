import Foundation

public struct BTree<T: Comparable> {
    
    private var root: Node
    
    // MARK: - Init
    
    public init(order: Int) {
        self.root = Node(order: order)
    }
    
    // MARK: - Private
    
    private mutating func makeRootUnique() -> Node {
        guard !isKnownUniquelyReferenced(&root) else { return root }
        root = root.clone()
        return root
    }
}

// MARK: - Index

extension BTree {
    
    public struct Index: Comparable {
        fileprivate weak var root: Node?
        fileprivate var mutationCount: UInt64
        
        fileprivate var path: [UnsafePathElement]
        fileprivate var current: UnsafePathElement
        
        init(startOf tree: BTree) {
            self.root = tree.root
            self.mutationCount = tree.root.mutationCount
            self.path = []
            self.current = UnsafePathElement(tree.root, 0)
            while !current.isLeaf { push(0) }
        }
        
        init(endOf tree: BTree) {
            self.root = tree.root
            self.mutationCount = tree.root.mutationCount
            self.path = []
            self.current = UnsafePathElement(tree.root, tree.root.elements.count)
        }
        
        fileprivate func validate(for root: BTree<T>.Node) {
            precondition(self.root === root && self.mutationCount == root.mutationCount)
        }
        
        private static func validate(_ lhs: BTree<T>.Index, _ rhs: BTree<T>.Index) {
            precondition(lhs.root === rhs.root)
            precondition(lhs.mutationCount == rhs.mutationCount)
            precondition(lhs.root != nil)
            precondition(lhs.mutationCount == lhs.root!.mutationCount)
        }
        
        private mutating func push(_ slot: Int) {
            path.append(current)
            let child = current.node.children[current.slot]
            current = UnsafePathElement(child, slot)
        }
        
        private mutating func pop() {
            current = path.removeLast()
        }
        
        fileprivate mutating func formSuccessor() {
            precondition(!self.current.isAtEnd, "Cannot advance beyound endIndex")
            current.slot += 1
            if current.isLeaf {
                while current.isAtEnd, current.node !== root {
                    pop()
                }
            } else {
                while !current.isLeaf {
                    push(0)
                }
            }
        }
        
        fileprivate mutating func formPredecessor() {
            if current.isLeaf {
                while current.slot == 0, current.node !== root {
                    pop()
                }
                precondition(current.slot > 0, "Cannot go below startIndex")
                current.slot -= 1
            } else {
                while !current.isLeaf {
                    let c = current.child
                    push(c.isLeaf ? c.elements.count - 1 : c.elements.count)
                }
            }
        }
        
        // MARK: - Comparable
        
        public static func == (left: BTree<T>.Index, right: BTree<T>.Index) -> Bool {
            validate(left, right)
            return left.current == right.current
        }
        
        public static func < (left: BTree<T>.Index, right: BTree<T>.Index) -> Bool {
            validate(left, right)
            switch (left.current.value, right.current.value) {
            case let (a?, b?):
                return a < b
            case (.some, nil):
                return true
            case (nil, _):
                return false
            }
        }
    }
}

// MARK: - Collection

extension BTree: SortedSet {
    
    public var startIndex: Index {
        Index(startOf: self)
    }
    public var endIndex: Index {
        Index(endOf: self)
    }
    
    public subscript(index: Index) -> T {
        index.validate(for: root)
        return index.current.value!
    }
    
    public func formIndex(after i: inout Index) {
        i.validate(for: root)
        i.formSuccessor()
    }
    
    public func formIndex(before i: inout Index) {
        i.validate(for: root)
        i.formPredecessor()
    }
    
    public func index(after i: Index) -> Index {
        i.validate(for: root)
        var i = i
        i.formSuccessor()
        return i
    }
    
    public func index(before i: Index) -> Index {
        i.validate(for: root)
        var i = i
        i.formPredecessor()
        return i
    }
}

// MARK: - CustomStringConvertible

extension BTree: CustomStringConvertible {
    
    public var description: String {
        var levels: [Int: [String]] = [:]
        
        func includeInLines(_ node: Node, index: Int) {
            let description = node.elements
                .map { "\($0)" }
                .joined(separator: ",")
            if var lvlArray = levels[index] {
                lvlArray.append(description)
                levels[index] = lvlArray
            } else {
                levels[index] = [description]
            }
            node.children.forEach {
                includeInLines($0, index: index + 1)
            }
        }
        includeInLines(root, index: 0)
        let lines = levels
            .sorted { $0.key < $1.key }
            .map { $1.joined(separator: " - ") }
        let maxLineLength = lines
            .map { $0.count }
            .max() ?? 0
        return lines
            .map { line in
                let diff = maxLineLength - line.count
                if diff > 1 {
                    let indentCount = diff / 2
                    return String(repeating: " ", count: indentCount) + line
                } else {
                    return line
                }
            }
            .joined(separator: "\n")
    }
}

// MARK: - UnsafePathElement

fileprivate extension BTree {
    
    struct UnsafePathElement: Equatable {
        
        unowned(unsafe) var node: BTree.Node
        var slot: Int
        
        init(_ node: BTree.Node, _ slot: Int) {
            self.node = node
            self.slot = slot
        }
        
        // MARK: - Supporting properties
        
        var value: T? {
            guard slot < node.elements.count else { return nil }
            return node.elements[slot]
        }
        var child: BTree.Node {
            node.children[slot]
        }
        var isLeaf: Bool {
            node.isLeaf
        }
        var isAtEnd: Bool {
            slot == node.elements.count
        }
        
        // MARK: - Equatable
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.slot == rhs.slot && lhs.node === rhs.node
        }
    }
}

// MARK: - Node

fileprivate extension BTree {
    
    class Node {
        let order: Int
        var elements: [T]
        var children: [Node]
        var mutationCount: UInt64
        
        init(order: Int) {
            self.elements = []
            self.children = []
            self.order = order
            self.mutationCount = 0
        }
        
        func clone() -> Node {
            let clone = Node(order: self.order)
            clone.elements = self.elements
            clone.children = self.children
            return clone
        }
        
        // MARK: - Private
        
        func forEach(_ body: @escaping (T) throws -> Void) rethrows {
            if isLeaf {
                try elements.forEach(body)
            } else {
                for i in elements.indices {
                    try children[i].forEach(body)
                    try body(elements[i])
                }
                try children[elements.endIndex].forEach(body)
            }
        }
        
        func contains(_ element: T) -> Bool {
            let (matched, index) = findSlot(of: element)
            if matched { return true }
            if children.isEmpty { return false }
            return children[index].contains(element)
        }
    }
}

// MARK: - Inserting

extension BTree {
    
    @discardableResult
    public mutating func insert(_ newElement: T) -> (didInsert: Bool, memberAfterInsert: T) {
        let root = makeRootUnique()
        let (old, splinter) = root.insert(newElement)
        if let s = splinter {
            let newRoot = Node(order: root.order)
            newRoot.elements = [s.separator]
            newRoot.children = [root, s.node]
            self.root = newRoot
        }
        return (
            didInsert: old == nil,
            memberAfterInsert: old ?? newElement
        )
    }
}

extension BTree.Node {
    
    struct Splinter {
        let separator: T
        let node: BTree.Node
    }
    
    func insert(_ newElement: T) -> (old: T?, splinter: BTree<T>.Node.Splinter?) {
        let slot = findSlot(of: newElement)
        if slot.matched {
            return (old: elements[slot.index], splinter: nil)
        }
        mutationCount += 1
        if isLeaf {
            elements.insert(newElement, at: slot.index)
            return (old: nil, splinter: isTooLarge ? split() : nil)
        } else {
            let (old, splinter) = makeChildUnique(at: slot.index).insert(newElement)
            guard let s = splinter else {
                return (old, nil)
            }
            elements.insert(s.separator, at: slot.index)
            children.insert(s.node, at: slot.index + 1)
            return (old: nil, splinter: isTooLarge ? split() : nil)
        }
    }
    
    // MARK: - Private
    
    fileprivate var isLeaf: Bool {
        children.isEmpty
    }
    
    private var isTooLarge: Bool {
        elements.count >= order
    }
    
    private func split() -> Splinter {
        let count = elements.count
        let middle = count / 2
        let separator = elements[middle]
        let node = BTree.Node(order: self.order)
        // move elements
        node.elements.append(contentsOf: self.elements[middle + 1 ..< count])
        self.elements.removeSubrange(middle ..< count)
        // move children
        if !isLeaf {
            node.children.append(contentsOf: self.children[middle + 1 ..< count + 1])
            self.children.removeSubrange(middle + 1 ..< count + 1)
        }
        return Splinter(separator: separator, node: node)
    }
    
    private func findSlot(of element: T) -> (matched: Bool, index: Int) {
        var start = 0
        var end = elements.count
        while start < end {
            let mid = start + (end - start) / 2
            if elements[mid] < element {
                start = mid + 1
            } else {
                end = mid
            }
        }
        let matched = start < elements.count && elements[start] == element
        return (matched, start)
    }
    
    private func makeChildUnique(at slot: Int) -> BTree<T>.Node {
        guard !isKnownUniquelyReferenced(&children[slot]) else {
            return children[slot]
        }
        let clone = children[slot].clone()
        children[slot] = clone
        return clone
    }
}

extension BTree {
    
    public init() {
        let order = (cacheSize ?? 32768) / (4 * MemoryLayout<T>.stride)
        self.init(order: Swift.max(16, order))
    }
    
    public func forEach(_ body: @escaping (T) throws -> Void) rethrows {
        try root.forEach(body)
    }
    
    public func contains(_ element: T) -> Bool {
        return root.contains(element)
    }
}

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

public let cacheSize: Int? = {
    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        var result: Int = 0
        var size = MemoryLayout<Int>.size
        let status = sysctlbyname("hw.l1dcachesize", &result, &size, nil, 0)
        guard status != -1 else { return nil }
        return result
    #elseif os(Linux)
        let result = sysconf(Int32(_SC_LEVEL1_DCACHE_SIZE))
        guard result != -1 else { return nil }
        return result
    #else
        return nil // Unknown platform
    #endif
}()
