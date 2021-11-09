//
//  model.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 3/22/21.
//

import Foundation

func categoryOrTransferString(category: MMCategory?, xferacct: MMAccount?) -> String {
    var ret = "Uncatagorized"

    if let cat = category {
        ret = cat.fullname
    }
    else if let xfer = xferacct {
        ret = "[\(xfer.name)]"
    }

    return ret
}

enum MMResourceType {
    case Tag
    case Category
    case Security
    case Price
    case Account
    case Transaction
}

class MMModel: Identifiable {
    static var theModel: MMModel? = nil
    static var modelsById: [Int:MMModel] = [:]
    static var models: [String:MMModel] = [:]

    static func setModel(name: String) {
        theModel = models[name]
    }

    static var currModel: MMModel? {
        get {
            theModel
        }
        set {
            theModel = newValue
        }
    }

    public private(set) var id: Int
    public private(set) var name: String
    public private(set) var dataFolderURL: URL

    var tags: MMArray<MMTag>
    var categories: MMArray<MMCategory>
    var securities: MMArray<MMSecurity>
    var accounts: MMArray<MMAccount>
    var transactions: MMArray<MMTransaction>
    //var statements: MMArray<MMStatement>

    var categoryByName: [String: MMCategory] = [:]
    var securityBySymbol: [String: MMSecurity] = [:]
    var securityByName: [String: MMSecurity] = [:]
    var transactionsByAccount: [String: [MMTransaction]] = [:]

    init(name: String, dataFolderURL: URL) {
        guard MMModel.models[name] == nil else {
            print("Model '\(name)' already exists!")
            exit(1)
        }

        self.id = MMModel.models.count
        self.name = name
        self.dataFolderURL = dataFolderURL

        tags = MMArray<MMTag>()
        categories = MMArray<MMCategory>()
        securities = MMArray<MMSecurity>()
        accounts = MMArray<MMAccount>()
        transactions = MMArray<MMTransaction>()
        //statements = MMArray<MMStatement>()

        categoryByName = [:]
        securityBySymbol = [:]
        securityByName = [:]
        transactionsByAccount = [:]
        
        MMModel.models[name] = self
        MMModel.modelsById[id] = self
    }

    func importQIF() -> Void {
        let loader = QifLoader(model: self)

        loader.loadModel()
    }

    func add(_ acct: MMAccount) -> MMAccount {
        if let existing = getAccount(name: acct.name) {
            return existing
        }

        //acct.setId(accounts.count)

        accounts.add(acct)

        return acct
    }

    func add(_ tag: inout MMTag) -> MMTag {
        if let existing = getTag(name: tag.name) {
            return existing
        }

        tag.id = tags.count

        tags.add(tag)

        return tag
    }

    func add(_ sec: MMSecurity) -> MMSecurity {
        if let existing = securityBySymbol[sec.symbol] {
            for name in sec.names {
                if !existing.names.contains(name) {
                    existing.addName(name: name)
                }
            }

            return existing
        }

        securities.add(sec)
        securityBySymbol[sec.symbol] = sec
        for name in sec.names {
            securityByName[name] = sec
        }

        return sec
    }

    func add(_ tx: MMTransaction) {
        transactions.add(tx)

        let acctname = tx.account.name

        if transactionsByAccount[acctname] == nil {
            transactionsByAccount[acctname] = []
        }

        tx.account.add(tx)
        transactionsByAccount[acctname]!.append(tx)
    }

    func getAccount(name: String) -> MMAccount? {
        for acct in accounts {
            if acct?.name == name {
                return acct
            }
        }

        return nil
    }

    func findOrCreateAccount(type: MMAccount.AccountType, name: String, desc: String?) -> MMAccount {
        if let existing = getAccount(name: name) {
            return existing
        }

        let acct = MMAccount(model: self, id: accounts.count, name: name, desc: desc, type: type)

        accounts.add(acct)

        return acct
    }

    func getTag(name: String) -> MMTag? {
        let matches = tags.filter(){ $0?.name == name }

        return matches.isEmpty ? nil : matches.first!
    }

    func createTag(from rawtag: RawItemInfo) -> MMTag {
        let parts = rawtag.name.split(separator: ":")

        if let tag = getTag(name: String(parts.last!)) {
            return tag
        }

        var newtag = MMTag(id: tags.count, name: rawtag.name)

        return add(&newtag)
    }

    func getCategory(fullname: String) -> MMCategory? {
        return categoryByName[fullname]
    }

    func findOrCreateCategory(fullname: String, desc: String? = nil) -> MMCategory {
        if let existing = getCategory(fullname: fullname) {
            if let desc = desc {
                if !desc.isEmpty && !existing.desc.isEmpty && existing.desc != desc {
                    print("WARNING: Can't replace category desc '\(existing.desc)' with '\(desc)'")
                }
            }

            return existing
        }

        let (pname, cname) = MMCategory.getParentName(name: fullname)

        var parent: MMCategory? = nil

        if let pname = pname {
            parent = findOrCreateCategory(fullname: pname)
        }

        let cat = MMCategory(model: self, id: categories.count, name: cname, desc: desc, parent: parent)

        //print("adding category '\(fullname)'")

        categories.add(cat)
        categoryByName[fullname] = cat

        return cat
    }

    func getSecurity(symbol: String) -> MMSecurity? {
        securityBySymbol[symbol]
    }

    func getSecurity(name: String) -> MMSecurity? {
        securityByName[name]
    }

    func findOrCreateSecurity(symbol: String, name: String) -> MMSecurity {
        if let s = getSecurity(symbol: symbol) {
            if !s.names.contains(name) {
                s.addName(name: name)
                securityByName[name] = s
            }

            return s
        }

        if let s = getSecurity(name: name) {
            print("Found security name '\(name)' under different symbols: \(s.symbol) vs \(symbol)")
            exit(1)
        }

        guard let sec = MMSecurity(modelid: self.id, id: self.securities.count, symbol: symbol, names: name, investmentType: .Income, goal: .Income) else {
            print("Failed to create security")
            exit(1)
        }

        let _ = add(sec)

        return sec
    }

    func getUnconnectedTransfers() -> [MMTransaction] {
        let txns: [MMTransaction] = []

        // TODO implement

        return txns
    }

    func processTransfers() {
        guard let model = MMModel.theModel else {
            return
        }

        for acct in accounts {
            for tx in model.transactionsByAccount[acct?.name ?? ""] ?? [] {
                while true {
                    let (xacct, xamt) = tx.getUnconnectedTransfer()
                    if xacct == nil {
                        break
                    }

                    if xacct === tx.account {
                        tx.connectTransfer(with: tx)
                    } else {
                        guard let xtx = xacct!.findUnconnectedTransfer(date: tx.date, amount: xamt!) else {
                            print("no transfer found for tx\n\(tx.description)")
                            exit(1)
                        }

                        tx.connectTransfer(with: xtx)
                    }
                }
            }
        }
    }

    func describe() {
        let fmgr = FileManager.default
        let home = fmgr.homeDirectoryForCurrentUser
        let outUrl = URL(fileURLWithPath: "qif/ingest.txt", relativeTo: home)
        let outPath = outUrl.path

        print("Creating file '\(outPath)'")
        fmgr.createFile(atPath: outPath,
                        contents: Data("".utf8),
                        attributes: nil)

        guard let fout: FileHandle = FileHandle(forWritingAtPath: outPath) else {
            print("Can't open \(outPath) for writing")
            exit(1)
        }

        printit("\nTags:\n================\n", to: fout)
        for tag in tags {
            if tag != nil {
                printit(tag!.description, to: fout)
            }
        }

        printit("\nCategories:\n================\n", to: fout)
        for cat in categories {
            if cat != nil {
                printit(cat!.description, to: fout)
            }
        }

        printit("\nAccounts:\n================\n", to: fout)
        for acct in accounts {
            if acct != nil {
                printit(acct!.description, to: fout)
            }
        }

        for acct in accounts {
            if acct != nil {
                printit("\nTransactions for \(acct!.name):\n================\n", to: fout)

                for tx in transactionsByAccount[acct!.name] ?? [] {
                    printit(tx.description, to: fout)
                }
            }
        }
    }
}

class MMModelObject { //}: PMMModelObject {
    let modelid: Int
    let id: Int
    let name: String
    let desc: String

    init(model: MMModel, id: Int, name: String, desc: String?) {
        self.modelid = model.id
        self.id = id
        self.name = name
        self.desc = desc ?? ""
    }
}
