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
    /// The number of times the data occurs in the old array
    var oldCounter: Int = 0
    /// The number of times the data occurs in the new array
    var newCounter: Int = 0
    /// The indexes of the data in the old array which act like a stack
    var oldIndexes: Array<Int?> = Array<Int?>()
    /// Flag marking if the data has been updated between arrays by equality check
    var updated: Bool = false
    /// Returns `true` if the data occur on both sides, `false` otherwise
    var occurOnBothSides: Bool {
        return newCounter > 0 && oldCounter > 0
    }
    var hasOldIndexes: Bool {
        return !oldIndexes.isEmpty
    }
    func push(new index: Int?) {
        newCounter += 1
        oldIndexes.append(index)
    }
    func push(old index: Int?) {
        oldCounter += 1;
        oldIndexes.append(index)
    }
    func popOldIndex() -> Int? {
        return oldIndexes.removeLast()
    }
}

/// Symbol table uses the old/new array `diffIdentifier` as the key and `Entry` as the value.
private struct EntryTable {
    var store = Dictionary<AnyHashable, Entry>()
    mutating func entry(forKey key: AnyHashable) -> Entry {
        if let entry = store[key] {
            return entry
        } else {
            let entry = Entry()
            store[key] = entry
            return entry
        }
    }
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
        var table = EntryTable()
        
        // pass 1
        var newRecords = newArray.map { (element) -> Record in
            let entry = table.entry(forKey: element.diffIdentifier)
            entry.push(new: nil)
            return Record(entry)
        }
        
        // pass 2
        var oldRecords = oldArray.enumerated().reversed().map { (i, element) -> Record in
            let entry = table.entry(forKey: element.diffIdentifier)
            entry.push(old: i)
            return Record(entry)
        }
        
        // pass 3
        newRecords.enumerated().filter { $1.entry.occurOnBothSides }.forEach { (i, record) in
            let entry = record.entry
            assert(entry.hasOldIndexes, "Old indexes is empty while iterating new item \(i). Should have nil")
            guard let oldIndex = entry.popOldIndex() else {
                return
            }
            // if an item occurs in the new and old array, it is unique
            // assign the index of new and old records to the opposite index (reverse lookup)
            newRecords[i].index = oldIndex
            oldRecords[oldIndex].index = i
        }
        
        var inserts = [Int]()
        var deletes = [Int]()
        var updates = [Int]()
        var moves = [(from: Int, to: Int)]()
        
        // pass 4
        var runningOffset = 0
        let deleteOffsets = oldRecords.enumerated().map { (i, record) -> Int in
            let deleteOffset = runningOffset
            // if the record index in the new array doesn't exist, its a delete
            if record.index == nil {
                deletes.append(i)
                runningOffset += 1
            }
            return deleteOffset;
        }
        
        // pass 5
        runningOffset = 0
        newRecords.enumerated().forEach { (i, record) in
            let insertOffset = runningOffset
            if let oldIndex = record.index {
                // note that an entry can be updated /and/ moved
                let n = newArray.itemOnStartIndex(advancedBy: i)
                let o = oldArray.itemOnStartIndex(advancedBy: oldIndex)
                if n != o {
                    updates.append(oldIndex)
                }
                let deleteOffset = deleteOffsets[oldIndex]
                if (oldIndex - deleteOffset + insertOffset) != i {
                    moves.append((from: oldIndex, to: i))
                }
            } else { // add to inserts if the opposing index is nil
                inserts.append(i)
                runningOffset += 1
            }
        }
        
        return nil;
    }
}
