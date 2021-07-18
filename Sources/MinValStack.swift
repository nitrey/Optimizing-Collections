import Foundation

public final class MinValStack {

    private var storage: [(element: Int, minValue: Int)] = []
    
    // MARK: - Public
    
    public init() {}
    
    public func push(_ newValue: Int) {
        let newMinValue: Int = {
            guard let (_, lastMinValue) = storage.last else { return newValue }
            return min(lastMinValue, newValue)
        }()
        storage.append(
            (element: newValue, minValue: newMinValue)
        )
    }
    
    @discardableResult
    public func pop() -> Int? {
        return storage.popLast()?.element
    }
    
    public func getMin() -> Int? {
        return storage.last?.minValue
    }
}
