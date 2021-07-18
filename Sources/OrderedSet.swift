import Foundation

private final class Canary {}

public struct OrderedSet<T: Comparable> {
    
    private var storage = NSMutableOrderedSet()
    private var canary = Canary()
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Private
    
    private static func compare(_ a: Any, _ b: Any) -> ComparisonResult {
        let a = a as! T
        let b = b as! T
        if a < b { return .orderedAscending }
        if a > b { return .orderedDescending }
        return .orderedSame
    }
    
    private mutating func makeUniqueIfNeeded() {
        guard !isKnownUniquelyReferenced(&canary) else { return }
        storage = storage.mutableCopy() as! NSMutableOrderedSet
        canary = Canary()
    }
}

// MARK: - Collection

extension OrderedSet: RandomAccessCollection {
    
    public typealias Index = Int
    public typealias Indices = CountableRange<Int>
    
    public var startIndex: Int { 0 }
    
    public var endIndex: Int { storage.count - 1 }
    
    public subscript(index: Int) -> T { storage[index] as! T }
    
    public func forEach(_ body: (T) -> Void) {
        storage.forEach {
            body($0 as! T)
        }
    }
    
    public func index(of element: T) -> Int? {
        let index = storage.index(
            of: element,
            inSortedRange: NSRange(0 ..< storage.count),
            usingComparator: OrderedSet.compare
        )
        return index == NSNotFound ? nil : index
    }
    
}

// MARK: - SortedSet

extension OrderedSet: SortedSet {
    
    public var description: String {
        String(describing: storage)
    }
    
    public func contains(_ element: T) -> Bool {
        return storage.contains(element) || index(of: element) != nil
    }
    
    @discardableResult
    public mutating func insert(_ newElement: T) -> (didInsert: Bool, memberAfterInsert: T) {
        let index = storage.index(
            of: newElement,
            inSortedRange: NSRange(0 ..< storage.count),
            options: .insertionIndex,
            usingComparator: OrderedSet.compare
        )
        if index < endIndex, storage[index] as! T == newElement {
            return (didInsert: false, memberAfterInsert: storage[index] as! T)
        } else {
            makeUniqueIfNeeded()
            storage.insert(newElement, at: index)
            return (didInsert: true, memberAfterInsert: newElement)
        }
    }
}
