//
//  rawmodel.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 3/22/21.
//

import Foundation

// This contains raw line-by-line info from QIF export file
// It is quite generic, holding attributes for all objects (account, transaction, etc)
// Processes the lines and presents properties that are present and default values if not
class RawItemInfo: Identifiable {
    static let types = [
        "Tag", // NB We ignore tags
        "Cat",
        "Security",
        "Prices",
        "Account",
        "Transaction"
    ]

    // NB These collapse into Transaction type
    static let txTypes = [
        "Oth A",
        "Invst",
        "Bank",
        "Cash",
        "CCard",
        "Oth L",
    ]

    static func mapTransactionType(rawType: String) -> String {
        if txTypes.contains(rawType) {
            return "Transaction"
        }

        return rawType
    }

//    static func decomposeLine(_ line: String) -> (Character, String) {
//        if line.isEmpty {
//            return (" ", "")
//        }
//
//        return (line.first!, String(line.dropFirst()))
//    }

    static func decomposeLine(_ line: Substring) -> (Character, String) {
        if line.isEmpty {
            return (" ", "")
        }

        return (line.first!, String(line.dropFirst()))
    }

    public private(set) var id: Int
    let objType: ObjectType
    let account: String?
    let startLine: Int
    let lines: ArraySlice<Substring>

    // (non-investment) Number Payee $splitamt
    // (investment) Naction Pline1 $xferamt
    // Address Splitcat Esplitmemo
    // Date Ysecurity Iprice Quant TUamount Cleared Memo Ocommission Lxferacct

    // NB don't care
    var cleared: Character? {
        (someValue(key: "C") ?? " ").first
    }

    var splitCategory: String {
        someValue(key: "S") ?? ""
    }

    var splitAmount: MMAmount? {
        if let s = someValue(key: "$") {
            return MMAmount(s)
        }

        return nil
    }

    var splitMemo: String {
        someValue(key: "E") ?? ""
    }

    typealias SplitTuple = (splitCat: String, splitMemo: String, splitAmount: String)

    private var _splits: [SplitTuple]? = nil

    var splits: [SplitTuple]? {
        guard _splits != nil else {
            return _splits
        }

        _splits = []

        let splitKeys: Array<Character> = ["S", "E", "$"]

        let splitLines = allValues(keys: splitKeys)

        var linenum = 0
        while linenum < splitLines.count {
            var tup: SplitTuple = ("", "", "")

            for key in splitKeys {
                guard linenum < splitLines.count else {
                    break
                }

                let line = splitLines[linenum]

                if line.0 == key {
                    switch key {
                    case "S":
                        tup.splitCat = line.1
                        linenum += 1
                    case "E":
                        tup.splitMemo = line.1
                        linenum += 1
                    case "$":
                        tup.splitAmount = line.1
                        linenum += 1
                    default:
                        print("Error getting splits!")
                        exit(1)
                    }
                }
            }

            _splits!.append(tup)
        }

        return _splits
    }

    var amount: MMAmount {
        MMAmount(someValue(key: "T") ?? "0") ?? MMAmount.zero
    }

    var category: String {
        someValue(key: "L") ?? ""
    }

    var memo: String {
        someValue(key: "M") ?? ""
    }

    var transferAmount: MMAmount? {
        // This also uses "$" in investment transactions
        splitAmount
    }

    var name: String {
        someValue(key: "N") ?? ""
    }

    var action: String? {
        someValue(key: "N")
    }

    var checkNumber: Int? {
        if let s = someValue(key: "N") {
            return Int(s)
        }

        return nil
    }

    var description: String {
        someValue(key: "D") ?? ""
    }

    var accountType: String {
        someValue(key: "T") ?? ""
    }

    // TODO
    var closeDate: MMDate? {
        MMDate(dateString: someValue(key: "C") ?? "")
    }

    var creditLimit: MMAmount {
        MMAmount(someValue(key: "L") ?? "0") ?? MMAmount.zero
    }

    // TODO
    var statementDate: MMDate? {
        nil // MMDate(dateString: someValue(key: "D") ?? "")
    }

    // TODO
    var statementFrequency: Int {
        Int(someValue(key: "F") ?? "0") ?? 0
    }

    // TODO
    var statementDay: Int {
        Int(someValue(key: "D") ?? "0") ?? 0
    }

    // TODO
    var statementBalance: MMAmount {
        MMAmount(someValue(key: "B") ?? "0") ?? MMAmount.zero
    }

    var date: MMDate {
        MMDate(dateString: someValue(key: "D")!)!
    }

    var payee: String {
        someValue(key: "P") ?? ""
    }

    var transferAccountName: String {
        let c = category
        if c.first == "[" && c.last == "]" {
            return String(c.dropFirst().dropLast())
        }

        return ""
    }

    var securityName: String? {
        someValue(key: "Y")
    }

    var price: MMAmount? {
        if let s = someValue(key: "I") {
            return MMAmount(s)
        }

        return nil
    }

    var quantity: MMAmount? {
        if let s = someValue(key: "Q") {
            return MMAmount(s)
        }

        return nil
    }

    var commission: MMAmount? {
        if let s = someValue(key: "O") {
            return MMAmount(s)
        }

        return nil
    }

    var securitySymbol: String {
        someValue(key: "S") ?? ""
    }

    var securityType: String {
        someValue(key: "T") ?? ""
    }

    var securityGoal: String {
        someValue(key: "G") ?? ""
    }

    func someValue(key: Character) -> String? {
        return linemap[key]
//        for line in lines {
//            if line.first == key {
//                return String(line.dropFirst())
//            }
//        }
//
//        return nil
    }

    func allValues(keys: [Character]) -> [(key: Character, value: String)] {
        var ret = Array<(Character, String)>()

        for line in lines {
            if keys.contains(line.first!) {
                let k = line.first!
                let v = String(line.dropFirst())

                ret.append((key: k, value: v))
            }
        }

        return ret //.count > 0 ? ret : nil
    }

    var linemap: [Character:String] = [:]

    init(id: Int, objType: ObjectType, account: String?, startLine: Int, lines: ArraySlice<String.SubSequence>) {
        self.id = id
        self.objType = RawItemInfo.mapTransactionType(rawType: objType)
        self.account = account
        self.startLine = startLine

        var excludedLineTypes: [Character] = []

        if self.objType == "Cat" {
            excludedLineTypes.append("B")
        }

        if self.objType == "Transaction" {
            excludedLineTypes.append("C")

            var tval: String? = nil
            var uval: String? = nil

            for line in lines {
                let (t, v) = RawItemInfo.decomposeLine(line)

                switch (t, v) {
                case ("T", let v):
                    tval = v
                case ("U", let v):
                    uval = v
                default:
                    break
                }
            }

            if tval != nil && tval == uval {
                excludedLineTypes.append("U")
            }
        }

        if excludedLineTypes.count > 0 {
            self.lines = lines.filter { line in
                !excludedLineTypes.contains(RawItemInfo.decomposeLine(line).0)
            }
        } else {
            self.lines = lines
        }

        for line in self.lines {
            let (key, value) = RawItemInfo.decomposeLine(line)

            if (key != " ") {
                linemap[key] = value
            }
        }
    }

    func format(indent: Int = 0) -> String {
        let indentStr = String(repeating: " ", count: indent)
        let indentStr2 = String(repeating: indentStr, count: 2)

        let nameOrAccount = (objType != "Account" && account != nil) ? "\(account!)" : name

        var ret = "\(indentStr)\(objType)[\(self.id)]: \(nameOrAccount)"

        for line in lines {
            let typechar = line[line.startIndex]
            let value = line.dropFirst().trimmingCharacters(in: .whitespaces)

            if typechar != "N" && value.count > 0 {
                ret += "\n\(indentStr2)\(typechar): \(value)"
            }
        }

        return ret
    }
}

class QifRawLoader: Sequence, IteratorProtocol {
    let lines: [Substring]
    var rawItems: [RawItemInfo] = []
    var typedItems: [ObjectType : [RawItemInfo]] = [:]

    var currLine: Int = 0
    var currItemType: String? = nil
    var currAccount: String? = nil

    var itemIdCursor: Int = 0

    var currObjType = ""

    init(rawLines: [Substring]) {
        self.lines = rawLines
    }

    func loadAll() {
        while next() != nil {
            // Force processing of each input line
        }
    }

    func reset() {
        self.itemIdCursor = 0
    }

    func next() -> RawItemInfo? {
        loadNextObject()

        guard rawItems.indices.contains(itemIdCursor) else {
            return nil
        }

        // TODO defer
        itemIdCursor += 1
        return rawItems[itemIdCursor - 1]
    }

    func extractType(from line: Substring) -> String {
        let colon = line.firstIndex(of: ":")!
        return line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
    }

    func loadNextObject() {
        // =======================================================================
        // QIF main data file structure:
        // =======================================================================
        //
        // !Type:Tag [ Nname ]* ^
        //
        // !Type:Category [ Nname[:name] Ddescription [T] I/E RtaxCode Bbudget ^ ]*
        //
        // !Option:AutoSwitch !Type:Account [ Nname Ttype Ddescription Llimit ^ ]* !Clear:AutoSwitch
        //
        // !Type:Security [ Nname Ssymbol Ttype Ggoal ^ ]
        //
        // !Option:AutoSwitch [
        //----!Account Nname Ttype ^ !Type:type [
        //------ Ddate Uamount Tamount Ccleared Payee LcategoryTransfer Mmemo
        //------ Ntxtype YsecurityName IsharePrice Qquantity Ocommission
        //------ [ SsplitCategoryTransfer $splitAmount EsplitMemo ]*
        //------ ^
        //----]*
        //--]*
        //
        // [ !Type:Prices "symbol",price,"date" ^ ]*
        //
        // =======================================================================
        // QIF statement file structure:
        // =======================================================================
        // !Account Nname Ffrequency Gstmtday CcloseDate
        //
        // !Statements
        // [ Mdate [ balance ] ]
        // - or -
        // [
        // Mdate
        // Ccashbal
        // [ Ssymbol;qvp;quantity;value;price ]
        // ]
        //
        // =======================================================================

        var objectStart = currLine
        var objName: Substring? = nil

        while currLine < lines.count && itemIdCursor >= rawItems.count {
            let line = lines[currLine]

            if line.starts(with: "!") {
                if line.starts(with: "!Type:") {
                    let objType = extractType(from: line)

                    if currObjType != objType {
                        currObjType = objType
                    }

                    objectStart = currLine + 1

                    if RawItemInfo.mapTransactionType(rawType: currObjType) != "Transaction" {
                        currAccount = nil
                    }
                }
                else if line.starts(with: "!Account") {
                    currObjType = "Account"
                    //currAccount = String(extractType(from: line))

                    objectStart = currLine + 1
                    currAccount = nil
                }
                else {
                    // printit("*** directive \(line) ***", to: fout)
                }
            }
            else if line == "^" {
                var exists = false

                if currObjType == "Account",
                   let name = objName,
                   let accts = typedItems[currObjType] {
                    for a in accts {
                        if a.name == name {
                            exists = true
                            break
                        }
                    }
                }

                if !exists {
                    let rawItem = RawItemInfo(id: rawItems.count + 1,
                                              objType: currObjType,
                                              account: currAccount,
                                              startLine: objectStart,
                                              lines: lines[objectStart..<currLine])
                    rawItems.append(rawItem)

                    if typedItems[rawItem.objType] == nil {
                        typedItems[rawItem.objType] = []
                    }

                    typedItems[rawItem.objType]!.append(rawItem)
                }

                if currObjType == "Account", let name = objName {
                    currAccount = String(name)
                }

                objectStart = currLine + 1
            } else if line.starts(with: "N") {
                objName = line.dropFirst()
            }

            currLine += 1
        }
    }
}
