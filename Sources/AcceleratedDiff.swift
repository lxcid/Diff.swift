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

/// Used to track elements while diffing.
/// We expect to keep a reference of entry, thus its declaration as (final) class.
private final class Entry {
}

private struct Record {
    let entry: Entry
    var index: Int?
    init(_ entry: Entry) {
        self.entry = entry
        self.index = nil
    }
}

public extension Collection where Iterator.Element: Equatable & AcceleratedDiffable {
    public func acceleratedDiff(_ other: Self) -> AcceleratedDiff {
        return Self.diffing(oldArray: self, newArray: other)!
    }
    
    // FIXME: (stan@trifia.com) Temporary returns nullable to satisfy the compiler. Remove nullable in the future…
    private static func diffing(oldArray: Self, newArray: Self) -> AcceleratedDiff? {
        // symbol table uses the old/new array `diffIdentifier` as the key and `Entry` as the value
        var table = Dictionary<AnyHashable, Entry>()
        
        // pass 1
        var newRecords = newArray.map { (element) -> Record in
            let key = element.diffIdentifier
            if let entry = table[key] {
                // FIXME: (stan@trifia.com) entry.push(new: nil)
                return Record(entry)
            } else {
                let entry = Entry()
                // FIXME: (stan@trifia.com) entry.push(new: nil)
                return Record(entry)
            }
        }
        
        return nil;
    }
}
