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

// MARK: - Indexing



// MARK: - Node

fileprivate extension BTree {
    
    class Node {
        let order: Int
        var elements: [T]
        var children: [Node]
        var mutationCount: Int64
        
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
    
    func insert(_ element: T) -> (old: T?, splinter: BTree<T>.Node.Splinter?) {
        let slot = findSlot(of: element)
        if slot.matched {
            return (old: elements[slot.index], splinter: nil)
        }
        mutationCount += 1
        if isLeaf {
            elements.insert(element, at: slot.index)
            return (old: nil, splinter: isTooLarge ? split() : nil)
        } else {
            let (old, splinter) = makeChildUnique(at: slot.index).insert(element)
            guard let s = splinter else {
                return (old, nil)
            }
            elements.insert(s.separator, at: slot.index)
            children.insert(s.node, at: slot.index + 1)
            return (old: nil, splinter: isTooLarge ? split() : nil)
        }
    }
    
    // MARK: - Private
    
    private var isLeaf: Bool {
        children.isEmpty
    }
    
    private var isTooLarge: Bool {
        children.count >= order
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
            node.children.append(contentsOf: self.children[middle ... count])
            self.children.removeSubrange(middle ... count)
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
