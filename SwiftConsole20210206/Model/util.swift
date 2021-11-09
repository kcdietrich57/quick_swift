//
//  util.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 3/22/21.
//

import Foundation

func printit(_ msg: String, to fout: FileHandle) {
    let msg2 = msg + "\n"
    fout.write(msg2.data(using: .utf8)!)
}

class MMArray<T: Identifiable>: Collection, CustomStringConvertible {
    var items: [T?]

    init() {
        items = [nil]
    }

    var description: String {
        "MMArray with \(items.count) items"
    }

    var count: Int {
        items.count
    }

    func index(after i: Int) -> Int {
        i + 1
    }

    var startIndex: Int {
        get {
            1
        }
    }

    var endIndex: Int {
        get {
            items.count
        }
    }

    subscript(index: Int) -> T? {
        get {
            if index > 0 && index < items.count {
                return items[index]
            }

            return nil
        }

        set {
            guard index > 0 else {
                print("Invalid index!")
                exit(1)
            }

            while index >= items.count {
                items.append(nil)
            }

            items[index] = newValue
        }
    }

    func add(_ item: T) {
        var intid = item.id as! Int

        if intid <= 0 {
            intid = items.count
        }

        self[intid] = item
    }

    func test() {
        print("\n===== Test MMArray =====\n")

        print("\n===== END Test MMArray =====\n")
    }
}
