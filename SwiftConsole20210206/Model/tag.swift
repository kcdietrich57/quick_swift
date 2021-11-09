//
//  tag.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 8/15/21.
//

import Foundation

struct MMTag: Identifiable, CustomStringConvertible {
    var id: Int
    var name: String

    var description: String {
        "Tag[\(id)]: \(name)"
    }

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

    init(rawItem: RawItemInfo, rawItemId: Int) {
        self.init(id: rawItemId, name: rawItem.name)
    }
}
