//
//  category.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 8/15/21.
//

import Foundation

//protocol PMMModelObject: Equatable {
//    static func == (o1: Self, o2: Self) -> Bool
//
//    var modelid: Int { get }
//    var id: Int { get }
//    var name: String { get }
//    var desc: String { get }
//
//    mutating func setId(_ id: Int) -> Void
//}
//
//extension PMMModelObject {
//    static func ==(lhs: Self, rhs: Self) -> Bool {
//        return lhs.modelid == rhs.modelid && lhs.id == rhs.id
//    }
//}

//protocol PMMCategory: PMMModelObject {
//    var fullname: String { get }
//    var children: [Self] { get }
//    var parent: Self? { get }
//}

class MMCategory: MMModelObject, Identifiable, Comparable, CustomStringConvertible {
    static func == (lhs: MMCategory, rhs: MMCategory) -> Bool {
        lhs.compare(to: rhs) == .orderedSame
    }

    static func < (lhs: MMCategory, rhs: MMCategory) -> Bool {
        lhs.compare(to: rhs)  == .orderedAscending
    }

    // Name Desc Taxrelated Incomecat Expensecat Budget Rtaxsched

    var nesting: Int {
        (parent?.nesting ?? -1) + 1
    }

    private(set) weak var parent: MMCategory?
    private(set) var children: [MMCategory] = []

    static func getParentName(name: String) -> (String?, String) {
        guard let colon = name.lastIndex(of: ":") else {
            return (nil, name)
        }

        let pname = String(name.prefix(upTo: colon))
        var cname = String(name.suffix(from: colon))
        cname.removeFirst()

        return (pname, cname)
    }

    var catpath: [String] {
        if let parent = parent {
            var path = parent.catpath
            path.append(name)
            return path
        }

        return [name]
    }

    var fullname: String {
        if let parent = parent {
            return "\(parent.fullname):\(name)"
        }

        return name
    }

    // This is a comment about the description property
    var description: String {
        "MMCategory[\(id)]: \(fullname) '\(desc)'"
    }

    init(model: MMModel, id: Int, name: String,  desc: String? = nil, parent: MMCategory? = nil) {
        self.parent = parent

        super.init(model: model, id: id, name: name, desc: desc)

        parent?.addChild(self)
    }

    private func addChild(_ child: MMCategory) {
        // TODO children should be a set
        if !self.children.contains(child) {
            self.children.append(child)
        }
    }

    func compare(to other: MMCategory) -> ComparisonResult {
        for (n1, n2) in zip(catpath, other.catpath) {
            let r = n1.compare(n2)

            if r != .orderedSame {
                return r
            }
        }

        switch nesting - other.nesting {
        case let n where n < 0: return .orderedAscending
        case let n where n > 0: return .orderedDescending
        default: return .orderedSame
        }
    }
}

func testCategory() {
    //    let foobarbaz = model.findOrCreateCategory(fullname: "Foo:Bar:Baz")
    //    let foobar = foobarbaz.parent!
    //    let foo = foobar.parent!
    //    print("Nesting: Foo:\(foo.nesting) FooBar:\(foobar.nesting) FooBarBaz:\(foobarbaz.nesting)")
    //
    //    for (ii, cat) in model.categoryByName.values.sorted().enumerated() {
    //        let indent = String(repeating: "  ", count: cat.nesting)
    //        print("\(ii): \(indent)[\(cat.id)] \(cat.fullname)")
    //    }
    //
    //    print("\(foo.compare(to: foobar))")

    let model = MMModel(name: "TestModel", dataFolderURL: URL(fileURLWithPath: "/tmp/foo"))

    let tax_fed = model.findOrCreateCategory(fullname: "Tax:Fed", desc: "(IRS) Federal taxes")
    print("Desc: '\(tax_fed.parent!.desc)'")
    let tax = model.findOrCreateCategory(fullname: "Tax", desc: "General taxes")
    print("Desc: '\(tax_fed.parent!.desc)'")

    let foo_fed = model.findOrCreateCategory(fullname: "Foo:Fed")

    let c1 = model.findOrCreateCategory(fullname: "Cccc:Fed")
    let c2 = model.findOrCreateCategory(fullname: "C:Fed")
    let c3 = model.findOrCreateCategory(fullname: "Caaa:Aaa")

    print("Cat tax: \(tax.name) (\(tax.fullname))")
    print("Cat tax:fed: \(tax_fed.name) (\(tax_fed.fullname))")

    print("Path tax:fed: \(tax_fed.catpath)")

    print("Compare t/t: \(tax_fed.compare(to: tax_fed).displayString)")
    print("Compare t/f: \(tax_fed.compare(to: foo_fed).displayString))")

    print("Compare \(c1.fullname)/\(c2.fullname): \(c1.compare(to: c2)).displayString)")
    print("Compare \(c1.fullname)/\(c3.fullname): \(c1.compare(to: c3)).displayString)")
    print("Compare \(c2.fullname)/\(c3.fullname): \(c2.compare(to: c3)).displayString)")
}

//class Category: ModelObject, Comparable {
//    static func == (lhs: Category, rhs: Category) -> Bool {
//        lhs.compare(to: rhs) == .orderedSame
//    }
//
//    static func < (lhs: Category, rhs: Category) -> Bool {
//        lhs.compare(to: rhs)  == .orderedAscending
//    }
//
//    static func getParentName(name: String) -> (String?, String) {
//        guard let colon = name.lastIndex(of: ":") else {
//            return (nil, name)
//        }
//
//        let pname = String(name.prefix(upTo: colon))
//        var cname = String(name.suffix(from: colon))
//        cname.removeFirst()
//
//        return (pname, cname)
//    }
//
//    private (set) weak var parent: Category?
//    private (set) var children: [Category] = []
//
//    init(id: Int, modelid: Int, name: String, desc: String? = nil, parent: Category? = nil) {
//        self.parent = parent
//
//        super.init(id: id, modelid: modelid, type: .category, name: name, desc: desc)
//    }
//
//    convenience init(modelid: Int, name: String, desc: String? = nil, parent: Category? = nil) {
//        self.init(id: -1, modelid: modelid, name: name, desc: desc, parent: parent)
//    }
//
//    var fullname: String {
//        if let parent = parent {
//            return "\(parent.fullname):\(name)"
//        }
//
//        return name
//    }
//
//    var catpath: [String] {
//        if let parent = parent {
//            var path = parent.catpath
//            path.append(name)
//            return path
//        }
//
//        return [name]
//    }
//
//    override func compare(to other: ModelObject) -> ComparisonResult {
//        guard let other = other as? Category else {
//            return .orderedSame
//        }
//
//        for (n1, n2) in zip(catpath, other.catpath) {
//            let r = n1.compare(n2)
//
//            if r != .orderedSame {
//                return r
//            }
//        }
//
//        return .orderedSame
//    }
//}
