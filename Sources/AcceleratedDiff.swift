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

private final class Entry {
}

public extension Collection where Iterator.Element: Equatable & AcceleratedDiffable {
    public func acceleratedDiff(_ other: Self) -> AcceleratedDiff {
        return Self.diffing(oldArray: self, newArray: other)!;
    }
    
    // FIXME: (stan@trifia.com) Temporary returns nullable to satisfy the compiler. Remove nullable in the future…
    private static func diffing(oldArray: Self, newArray: Self) -> AcceleratedDiff? {
        // symbol table uses the old/new array `diffIdentifier` as the key and `Entry` as the value
        var table = Dictionary<AnyHashable, Entry>();
        
        return nil;
    }
}
