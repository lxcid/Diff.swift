public struct AcceleratedDiff: DiffProtocol {
    public enum Element {
        case insert(at: Int)
        case delete(at: Int)
        case update(at: Int)
        case move(from: Int, to: Int)
    }
    
    /// Returns the position immediately after the given index.
    ///
    /// - Parameter i: A valid index of the collection. `i` must be less than
    ///   `endIndex`.
    /// - Returns: The index value immediately after `i`.
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    /// An array of particular diff operations
    public let elements: [AcceleratedDiff.Element]
}

public protocol AcceleratedDiffable {
    var diffIdentifier: AnyHashable { get }
}

public extension Collection where Iterator.Element: Equatable & AcceleratedDiffable {
    public func acceleratedDiff(_ other: Self) -> AcceleratedDiff {
        
    }
}
