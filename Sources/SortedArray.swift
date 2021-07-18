import Foundation

public struct SortedArray<T: Comparable> {
    
    private var storage: [T] = []
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Private
    
    private func index(for element: T) -> Int {
        var start = storage.startIndex
        var end = storage.endIndex
        while start < end {
            let mid = start + (end - start) / 2
            if storage[mid] > element {
                end = mid
            } else {
                start = mid + 1
            }
        }
        return start
    }
}

extension SortedArray: RandomAccessCollection {
    
    public typealias Indices = CountableRange<Int>
    
    public var startIndex: Int { storage.startIndex }
    
    public var endIndex: Int { storage.endIndex }
    
    public subscript(index: Int) -> T { storage[index] }
    
    public func index(of element: T) -> Int? {
        let index = self.index(for: element)
        guard index < storage.endIndex, storage[index] == element else {
            return nil
        }
        return index
    }
    
    public func forEach(_ body: (T) throws -> Void) rethrows {
        try storage.forEach(body)
    }
    
    public func sorted() -> [T] {
        return storage
    }
}

// MARK: - SortedSet

extension SortedArray: SortedSet {
    
    public var description: String {
        String(describing: storage)
    }
    
    @discardableResult
    public mutating func insert(_ newElement: T) -> (didInsert: Bool, memberAfterInsert: T) {
        let index = self.index(for: newElement)
        if index < storage.endIndex, storage[index] == newElement {
            return (didInsert: false, memberAfterInsert: storage[index])
        } else {
            storage.insert(newElement, at: index)
            return (didInsert: true, memberAfterInsert: newElement)
        }
    }
        
    public func contains(_ element: T) -> Bool {
        let index = self.index(for: element)
        return index < storage.endIndex && storage[index] == element
    }
}
