import Foundation

public final class List<T> {
    
    public let value: T
    public private(set) var next: List<T>?
    
    public init(_ value: T, next: List<T>? = nil) {
        self.value = value
        self.next = next
    }
    
    public func cons(_ value: T) -> List<T> {
        return List(value, next: self)
    }
    
    public func reversed() -> List<T> {
        var last: List = self
        var current: List? = self.next
        self.next = nil
        while let cur = current {
            current = cur.next
            cur.next = last
            last = cur
        }
        return last
    }
}

extension List: CustomStringConvertible where T: CustomStringConvertible {
    
    public var description: String {
        var values: [T] = [value]
        var current = self
        while let next = current.next {
            values.append(next.value)
            current = next
        }
        return values
            .map { $0.description }
            .joined(separator: ", ")
    }
}

extension List: ExpressibleByArrayLiteral {
    
    public convenience init(arrayLiteral elements: T...) {
        guard !elements.isEmpty else { fatalError() }
        self.init(elements[0])
        var last = self
        for index in 1 ..< elements.count {
            let node = List(elements[index])
            last.next = node
            last = node
        }
    }
}
