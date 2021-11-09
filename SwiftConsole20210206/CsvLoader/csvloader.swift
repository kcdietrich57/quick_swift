//
//  csvloader.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 8/17/21.
//

// TODO problems here
// GD IRA Schwab;10/31/21;806295.26;11754.44;9;12;
// I;10/22/21;CASH;;;-705.90;
// ISHARES CORE MSCI EMERGING ETF IV;0;

import Foundation
import CoreImage

class StatementLogProcessor {
    let model: MMModel

    init(model: MMModel) {
        self.model = model
    }

    func processStmtInfo(parts: [Substring], idx: inout Int) -> (MMStatement?, numTx: Int, numSec: Int) {
        guard parts.count >= idx + 6 else {
            return (nil, 0, 0)
        }

        let acctName = String(parts[idx])
        let date = MMDate(dateString: String(parts[idx + 1]))!
        let bal = MMAmount(String(parts[idx + 2]))!
        let cashbal = MMAmount(String(parts[idx + 3]))!
        let ntran = Int(String(parts[idx + 4]))!
        let nsec = Int(String(parts[idx + 5]))!

        guard let acct = model.getAccount(name: acctName) else {
            print("Can't find account: '\(acctName)'")
            return (nil, 0, 0)
        }

        guard let stmt = acct.getStatement(date: date) else {
            print("Can't find statement in '\(acctName)': '\(date.description)' '\(bal.description)'")
            return (nil, 0, 0)
        }

        //assert(bal == stmt.balance)
        assert(cashbal == stmt.cashBalance)

        idx += 6

        return (stmt, ntran, nsec)
    }

    func processTransaction(parts: [Substring], idx: inout Int) -> TxInfo? {
        guard parts.count > idx else {
            return nil
        }

        var txinfo: TxInfo? = nil

        let txtype = String(parts[idx])

        switch txtype {
        case "T":
            guard parts.count > idx + 3 else {
                return nil
            }

            var ss: [String] = []
            for ii in 0...3 {
                ss.append(String(parts[idx + ii]))
            }

            let txdate = MMDate(dateString: ss[1])
            let txcknum = Int(ss[2])
            let txamount = MMAmount(ss[3])

            txinfo = TxInfo(date: txdate!, checkNumber: txcknum!, amount: txamount!, action: "Cash")

            idx += 4

        case "I":
            guard parts.count > idx + 5 else {
                return nil
            }

            var ss: [String] = []
            for ii in 0...5 {
                ss.append(String(parts[idx + ii]))
            }

            let txdate = MMDate(dateString: ss[1])!
            let txactionStr = ss[2]
            let txsym = ss[3]
            let txqty = MMAmount(ss[4])
            let txamount = MMAmount(ss[5]) ?? MMAmount.zero


            txinfo = TxInfo(date: txdate, checkNumber: 0, amount: txamount, action: txactionStr,
                            symbol: txsym, shares: txqty)

            idx += 6

        default:
            print("bad log line: txtype='\(txtype)'")
            return nil
        }

        return txinfo!
    }

    func processSecurity(parts: [Substring], idx: inout Int) -> TxSecInfo? {
        guard parts.count > idx + 1 else {
            return nil
        }

        var ss: [String] = []
        for ii in 0...1 {
            ss.append(String(parts[idx + ii]))
        }

        let secname = ss[0]
        guard let sec = model.getSecurity(name: secname) else {
            print("Can't find security '\(secname)'")
            return nil
        }

        let secinfo = TxSecInfo(sec)

        let numtx = Int(ss[1])!

        idx += 2

        for _ in 0..<numtx {
            guard parts.count > idx + 1 else {
                return nil
            }

            var ss: [String] = []
            for ii in 0...1 {
                ss.append(String(parts[idx + ii]))
            }

            let txidx = Int(ss[0])!
            let txbal = MMAmount(ss[1])!

            secinfo.txinfo.append((txidx, txbal))

            idx += 2
        }

        return secinfo
    }

    func processLogLines(lines: [Substring]) {
        guard lines.count > 1 else {
            return
        }

        guard let version = Int(String(lines.first!)) else {
            exit(1)
        }
        guard version >= 4 else {
            exit(1)
        }

    foo:
        for line in lines[1...] {
            guard !line.isEmpty else {
                continue
            }

            // TeslaLoan;10/21/21;-25676.54;-25676.54;1;0;T;10/11/21;0;986.26
            let parts = line.split(separator: ";", omittingEmptySubsequences: false)
            var pp: [String] = []
            for p in parts {
                pp.append(String(p))
            }
            var idx = 0

            let (newstmt, ntran, nsec) = processStmtInfo(parts: parts, idx: &idx)
            guard let newstmt = newstmt else {
                continue
            }

            for txnum in 0..<ntran {
                guard let txinfo = processTransaction(parts: parts, idx: &idx) else {
                    print("malformed log line: tx=\(txnum) '\(String(line))'")
                    let _ = processTransaction(parts: parts, idx: &idx)
                    continue foo
                }

                newstmt.addTransactionInfo(txinfo)
            }

            for secnum in 0..<nsec {
                guard let secinfo = processSecurity(parts: parts, idx: &idx) else {
                    print("malformed log line: sec=\(secnum)  '\(String(line))'")
                    let _ = processSecurity(parts: parts, idx: &idx)
                    continue foo
                }

                newstmt.addSecurityInfo(secinfo)
            }
        }
    }
}

class TxSecInfo {
    var security: MMSecurity?
    var txinfo: [(Int, MMAmount)]

    init(_ sec: MMSecurity) {
        self.security = sec
        self.txinfo = []
    }
}

struct TxInfo {
    var date: MMDate
    var cknum: Int
    var amount: MMAmount
    var action: String
    var symbol: String?
    var shares: MMAmount?

    init(date: MMDate, checkNumber: Int, amount: MMAmount, action: String? = nil,
        symbol: String? = nil, shares: MMAmount? = nil, price: MMAmount? = nil) {
        self.date = date
        self.cknum = checkNumber
        self.amount = amount
        self.action = action ?? "Cash"
        self.symbol = symbol
        self.shares = shares
    }
}

class CsvTransactionInfo {
    // The field names that may occur in the CSV file input
    enum TransactionInfoField: String {
        case Scheduled = "Scheduled"
        case Split =  "Split"
        case Date =  "Date"
        case Account =  "Account"
        case TxType =  "Type"
        case Action =  "Action"
        case Payee =  "Payee"
        case CheckNum =  "Check #"
        case Amount =  "Amount"
        case Category =  "Category"
        case Description =  "Description/Category"
        case Memo =  "Memo/Notes"
        case Reference =  "Reference"
        case Security =  "Security"
        case Symbol =  "Symbol"
        case Transfer =  "Transfer"
        case Commission =  "Comm/Fee"
        case SharesOut =  "Shares Out"
        case SharesIn =  "Shares In"
        case Shares =  "Shares"
        case Outflow =  "Outflow"
        case Inflow = "Inflow"
    }

    let fieldNames: [String]
    var fieldPos: [TransactionInfoField : Int] = [:]

    // Map account name to its tuples
    var tuples: [String : [[String]]] = [:]

    init(fieldNames: [String], tuples: [String : [[String]]]) {
        self.fieldNames = fieldNames
        self.tuples = tuples

        for (ii, fieldName) in fieldNames.enumerated() {
            guard let f = TransactionInfoField(rawValue: fieldName) else {
                print("Can't find field '\(fieldName)'")
                continue
            }

            fieldPos[f] = ii
        }
    }

    func addField(field: TransactionInfoField, pos: Int) {
        fieldPos[field] = pos
    }

    func addTuple(acctname: String, tuple: [String]) {
        var acctTuples = self.tuples[acctname]

        if acctTuples == nil {
            acctTuples = []
            self.tuples[acctname] = acctTuples
        }

        acctTuples!.append(tuple)
    }

    func getValue(tuple: [String], field: TransactionInfoField) -> String {
        guard let pos = self.fieldPos[field] else {
            print("Can't determine field position for \(field)")
            return ""
        }

        return (pos < tuple.count) ? tuple[pos] : ""
    }
}

class CsvLoader {
    private static let acctTypeMap: [String : MMAccount.AccountType] = [
        "BNK": .Banking, "ASS": .Asset, //
        "INV": .Investment, "RET": .Retirement, //
        "CCD": .CreditCard, "LOAN": .Loan
    ]

    // Info kept during the current load - only one load at a time
    private var model: MMModel?
    private var beginLoad: Date?
    private var qifdir: URL?

    private var csvfilename: String?
    private var csvdata: String?
    private var csvlines: [Substring]?
    private var rawinfo: CsvTransactionInfo?

    var elapsed: String {
        String(format: "%5.1f", -(beginLoad?.timeIntervalSinceNow ?? 0.0))
    }

    init() {
        model = nil
        csvdata = nil
        rawinfo = nil
        csvlines = nil
        beginLoad = nil
        csvfilename = nil

        let home = FileManager.default.homeDirectoryForCurrentUser
        qifdir = URL(fileURLWithPath: "qif", isDirectory: true, relativeTo: home)
    }

    func loadCsv(filename: String) {
        guard let qifdir = self.qifdir else {
            print("ERROR: No qif dir to load from!")
            return
        }

        print("\nLoading CSV '\(filename)' from '\(qifdir.path)'")

        self.model = MMModel.currModel
        guard self.model != nil else {
            print("No model!")
            exit(1)
        }

        createSecurities()

        self.csvfilename = filename
        self.beginLoad = Date()
        self.csvdata = nil
        self.rawinfo = nil
        self.csvlines = nil

        loadRawCvsInfo()

        createCategories()
        createAccounts()
        createTransactions()
        createStatements()
    }

    // TODO loading from a file would probably be preferrable
    private func createSecurities() {
        guard let model = self.model else {
            return
        }

        var predefinedSecurityMap: [String:String] = [:]

        func defineSecurity(name: String, symbol: String) {
            predefinedSecurityMap[name] = symbol

            let _ = model.findOrCreateSecurity(symbol: symbol, name: name)
        }

        defineSecurity(name: "WELLS FARGO HSA FDIC INSURED NOT COVERED BY SIPC", symbol: "QPISQ")
        defineSecurity(name: "ISHARES CORE S&P 500 ETF IV", symbol: "IVV")
        defineSecurity(name: "ISHARES CORE MSCI EMERGING ETF IV", symbol: "IEMG")
        defineSecurity(name: "SPDR PORTFOLIO S&P 400 MID CP ETF IV", symbol: "SPMD")
        defineSecurity(name: "VANGUARD FTSE DEVELOPED MATS ETF IV", symbol: "VEA")
        defineSecurity(name: "VANGUARD INTRMDIAT TRM TRSRY ETF", symbol: "VGIT")
        defineSecurity(name: "VANGUARD INTERMEDIATE TERM COR ETF", symbol: "VCIT")
        defineSecurity(name: "VANGUARD REAL ESTATE ETF IV", symbol: "VNQ")
        defineSecurity(name: "VANGUARD TOTAL BOND MARKET ETF", symbol: "BND")
        defineSecurity(name: "WSDMTREE EMRG MKTS SMALLCAP DVD ETF", symbol: "DGS")
        defineSecurity(name: "DFA INTERNATIONAL SMALL COMPANY I", symbol: "DFISX")
        defineSecurity(name: "DFA US MICRO CAP I", symbol: "DFSCX")
        defineSecurity(name: "DFA US SMALL CAP VALUE I", symbol: "DFSVX")

        defineSecurity(name: "Invest Money Market", symbol: "INVMM")
        defineSecurity(name: "Scudder Dreman High Return A", symbol: "KDHAX")
        defineSecurity(name: "Scudder Dreman High Return A (KDHAX)", symbol: "KDHAX")
        defineSecurity(name: "Massachusetts Invs Trust A", symbol: "MITTX")
        defineSecurity(name: "Putnam Cap Apprec A", symbol: "PCAPX")
        defineSecurity(name: "Franklin Small Cap Growth A", symbol: "FRSGX")
        defineSecurity(name: "Putnam Europe Growth A", symbol: "PEUGX")
        defineSecurity(name: "United Income", symbol: "UNCMX")

        defineSecurity(name: "Ascential Software", symbol: "ASCL")
        defineSecurity(name: "Smith Barney Cash", symbol: "SBMM")
        defineSecurity(name: "Centex", symbol: "CNTX")
        defineSecurity(name: "Innovex", symbol: "INVX")
        defineSecurity(name: "Olde Money Mk", symbol: "OLDEMM")
        defineSecurity(name: "International Business Machine", symbol: "IBM")
        defineSecurity(name: "IBM Award", symbol: "IBM")
        defineSecurity(name: "MMDA1", symbol: "MMDA1")
        defineSecurity(name: "ET Money Market GD", symbol: "ETMMGD")
        defineSecurity(name: "ET Money Market TD", symbol: "ETMMTD")
        defineSecurity(name: "ETrade MM #2014986", symbol: "ETMM2014986")
        defineSecurity(name: "EXTENDED INSURANCE SWEEP DEPOSIT ACCOUNT 3.50% 03/01/2043", symbol: "#2145605")
        defineSecurity(name: "E*TRADE SAVINGS BANK RSDA 3.00% 07/01/2046", symbol: "#2021396")
        defineSecurity(name: "ETRDZ MM", symbol: "ETRDZ")
        defineSecurity(name: "E TRADE BK EXTNDED INS SWEEP DEP ACCT 6.00% 07/01/2008", symbol: "ETMMBR")
        defineSecurity(name: "CPC Bond", symbol: "CPC Bond")
        defineSecurity(name: "First National Realty", symbol: "FNR")
        defineSecurity(name: "SiteBas", symbol: "SITE")
        defineSecurity(name: "UTS", symbol: "UTS")
        defineSecurity(name: "CCCFran", symbol: "CCCFran")
        defineSecurity(name: "US Transportation", symbol: "USTS")
        defineSecurity(name: "Total Bond Market  1", symbol: "TBOND1")
        defineSecurity(name: "Large-Cap Value Index", symbol: "LCVIDX")
        defineSecurity(name: "Stable Value", symbol: "STABLE")
        defineSecurity(name: "Stable Value Fund", symbol: "STABLE")
        defineSecurity(name: "Vanguard LT TREASURY ADM", symbol: "VUSUX")
        defineSecurity(name: "TARGETRETIREMENT2030", symbol: "TR2030")
        defineSecurity(name: "TARGETRETIREMENT2020", symbol: "TR2020")
        defineSecurity(name: "TARGETRETIREMENT2025", symbol: "TR2025")
        defineSecurity(name: "CSI Guaranteed", symbol: "CSIG")
        defineSecurity(name: "CSI Equity", symbol: "CSIEQ")
        defineSecurity(name: "Fidelity Retire Mmkt", symbol: "FIDRETMM")
        defineSecurity(name: "Magellan (Fidelity)", symbol: "FMAGX")
    }

    private func createStatements() {
        guard let model = self.model else {
            return
        }

        let stmtProcessor = StatementProcessor(model: model)

        let stmturls = getStatementFiles()

        for stmturl in stmturls {
            guard stmturl.isFileURL //
                    && stmturl.lastPathComponent.hasSuffix(".qif") //
                    && !stmturl.lastPathComponent.contains("esppibm") //
                    //&& !stmturl.lastPathComponent.contains("etradeTDIRA") //
            else {
                continue
            }

            let stmtdat = loadFile(at: stmturl)
            let stmtlines = stmtdat.split(separator: "\n")

            stmtProcessor.processStatementLines(lines: stmtlines)
        }

        let logProcessor = StatementLogProcessor(model: model)

        guard let logurl = getStatementLogFile() else {
            return
        }
        guard logurl.isFileURL else {
            return
        }

        let logdat = loadFile(at: logurl)
        let loglines = logdat.split(separator: "\n")

        logProcessor.processLogLines(lines: loglines)
    }

    //=======================================================

    private func createTransactions() {
        guard let model = self.model else {
            return
        }
        guard let rawinfo = self.rawinfo else {
            return
        }

        for acctName in rawinfo.tuples.keys {
            guard let acct = model.getAccount(name: acctName) else {
                continue
            }
            guard let acctTuples = rawinfo.tuples[acctName] else {
                continue
            }

            print("\n======= Processing account \(acct.name) - \(acctTuples.count) tuples =======")

            var curtx: MMTransaction? = nil     // The tx being constructed
            var curtxIsSplit = false
            var txToAdd: MMTransaction? = nil

            for tuple in acctTuples {
                let _ = rawinfo.getValue(tuple: tuple, field: .TxType)

                let datestr = rawinfo.getValue(tuple: tuple, field: .Date)
                guard let date = MMDate(dateString: datestr) else {
                    print("Invalid date string: '\(datestr)'")
                    exit(1)
                }

                let _ = rawinfo.getValue(tuple: tuple, field: .Action)
                //let action = MMTransaction.
                let payee = rawinfo.getValue(tuple: tuple, field: .Payee)
                let memo = rawinfo.getValue(tuple: tuple, field: .Memo)
                let cknumstr = rawinfo.getValue(tuple: tuple, field: .CheckNum)
                let cknum: Int? = ((cknumstr.isEmpty) ? nil : Int(cknumstr))

                let amountstr = rawinfo.getValue(tuple: tuple, field: .Amount)
                let amount = MMAmount(amountstr) ?? MMAmount.zero
                let catstr = rawinfo.getValue(tuple: tuple, field: .Category)

                var category: MMCategory? = nil

                var xacctname = rawinfo.getValue(tuple: tuple, field: .Transfer)
                var xacct: MMAccount? = nil

                if catstr.starts(with: "[") || catstr.starts(with: "Transfer:[") {
                    guard catstr.last == "]" else {
                        print("Badly formed category/transfer: '\(catstr)'")
                        exit(1)
                    }

                    let astart = catstr.index(after: catstr.firstIndex(of: "[")!)
                    let astop = catstr.index(before: catstr.endIndex)
                    let xacctname2 = String(catstr[astart..<astop])

                    if !xacctname.isEmpty && xacctname != xacctname2 {
                        print("Conflicting transfer accounts: '\(xacctname)' vs '\(xacctname2)'")
                    }

                    xacctname = xacctname2
                } else {
                    category = model.getCategory(fullname: catstr)
                }

                if !xacctname.isEmpty {
                    xacct = model.getAccount(name: xacctname)
                }

                // Action, amount, tx?
                let security = rawinfo.getValue(tuple: tuple, field: .Security)
                let qtystr = rawinfo.getValue(tuple: tuple, field: .Shares)
                let qty = MMAmount(qtystr)
                let commstr = rawinfo.getValue(tuple: tuple, field: .Commission)
                let comm = MMAmount(commstr)

                var price: MMAmount? = nil
                let desc = rawinfo.getValue(tuple: tuple, field: .Description)
                if desc.contains(" shares @ ") {
                    let words = desc.split(separator: " ")
                    guard words.count >= 4 else {
                        print("Malformed security tx description: '\(desc)'")
                        exit(1)
                    }

                    if let q = MMAmount(String(words.first!)) {
                        if qty != nil && qty != q {
                            print("Quantity mismatch: '\(qty!)' vs '\(q)'")
                        }
                    }
                    if let p = MMAmount(String(words[3])) {
                        price = p
                    }
                }

                txToAdd = nil
                let split = rawinfo.getValue(tuple: tuple, field: .Split)

                if split == "S" {
                    if !curtxIsSplit {
                        txToAdd = curtx
                        curtx = nil
                    } else if let tmptx = curtx {
                        if acct.id != tmptx.account.id //
                            || date != tmptx.date //
                            //|| txtype != tmptx.type //
                            //|| action != tmptx.action //
                            || payee != tmptx.payee {
                            txToAdd = curtx
                            curtx = nil
                        }
                    }
                } else if curtx != nil {
                    txToAdd = curtx!
                    curtx = nil
                }

                if let tx = txToAdd {
                    model.add(tx)
                    txToAdd = nil
                }

                if curtx == nil {
                    curtx = MMTransaction(model: model, //
                                          id: model.transactions.count, //
                                          acct: acct, //
                                          date: date, //
                                          action: nil, // TODO fix QIF action type
                                          chknum: cknum, //
                                          payee: payee, //
                                          security: model.getSecurity(symbol: security), //
                                          amount: amount, //
                                          quantity: qty, //
                                          price: price, //
                                          commission: comm)
                    curtxIsSplit = split == "S"
                }

                curtx!.addItem(category: category, //
                               transferAccount: xacct, transferTransaction: nil, //
                               amount: amount, memo: memo)
            }

            if let tx = curtx {
                model.add(tx)
            }
        }
    }

    private func createCategories() {
        guard let model = self.model else {
            return
        }
        guard let rawinfo = self.rawinfo else {
            return
        }

        for acctTuples in rawinfo.tuples.values {
            for tuple in acctTuples {
                let catname = rawinfo.getValue(tuple: tuple, field: .Category)

                if !catname.isEmpty && !catname.starts(with: "Transfer") {
                    let _ = model.findOrCreateCategory(fullname: catname)
                }
            }
        }
    }

    private func createAccounts() {
        guard let model = self.model else {
            return
        }
        guard let rawinfo = self.rawinfo else {
            return
        }

        for acctName in rawinfo.tuples.keys {
            guard let acctTuples = rawinfo.tuples[acctName] else {
                continue
            }

            for tuple in acctTuples {
                let memo = rawinfo.getValue(tuple: tuple, field: .Memo)

                if let accttype = CsvLoader.acctTypeMap[memo] {
                    let noninv = Set<MMAccount.AccountType>([.Banking, .Loan, .CreditCard, .Asset])

                    if noninv.contains(accttype) {
                        let desc = rawinfo.getValue(tuple: tuple, field: .Description)
                    
                        let _ = model.findOrCreateAccount(type: accttype, name: acctName, desc: desc)
                    }

                    break
                }
            }
        }
    }

    private func loadRawCvsInfo() {
        loadCsvData()
        splitCsvLines()

        guard let lines = self.csvlines else {
            return
        }

        var fieldNames: [String] = []
        var tuples: [String : [[String]]] = [:]
        var acctidx: Int = -1
        var tuplecount = 0

        for linex in lines {
            if fieldNames.isEmpty && !linex.contains("\"Account\"") {
                continue
            }

            tuplecount += 1
            if tuplecount % 1000 == 0 {
                if tuplecount >= 10000 {
                    //break
                }
            }

            var line = String(linex)
            massageLine(line: &line) // sub newlines for commas

            let rawFields: [Substring] = line.split(separator: "\n")

            var fields: [String] = []

            for idx in rawFields.startIndex..<rawFields.endIndex {
                var field = String(rawFields[idx])

                // This handles quoted strings in a simple way
                // No embedded quotes, minimal syntax check
                if field.first == "\"" && field.last == "\"" {
                    field.removeFirst()
                    field.removeLast()
                }

                fields.append(field)
            }

            if fieldNames.isEmpty {
                fieldNames = fields

                let idx = fields.firstIndex(of: "Account")
                guard idx != nil else {
                    print("There is no Account field when expected: \(fields)")
                    exit(1)
                }

                acctidx = idx!

            } else if acctidx < fields.count {
                let acctname = fields[acctidx]
                if tuples[acctname] == nil {
                    tuples[acctname] = []
                }

                tuples[acctname]!.append(fields)
            }
        }

        self.rawinfo = CsvTransactionInfo(fieldNames: fieldNames, tuples: tuples)
    }

    private func massageLine(line: inout String) {
        var inquote = false

        for ii in 0..<line.count {
            let idx = line.index(line.startIndex, offsetBy: ii)
            let ch = line[idx]

            if inquote && ch == "\"" {
                inquote = false
            } else if !inquote {
                if ch == "," {
                    line.replaceSubrange(idx...idx, with: "\n")
                } else if ch == "\"" {
                    inquote = true
                }
            }
        }
    }

    private func loadFile(at url: URL) -> String {
        do {
            print("\(elapsed): Loading '\(url)'...")
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("error: \(error)")
            exit(1)
        }
    }

    private func loadDataFile(filepath: String?) -> String {
        guard let filepath = filepath else {
            return ""
        }

        guard let url = URL(string: filepath, relativeTo: self.qifdir) else {
            print("Can't open '\(filepath)")
            exit(1)
        }

        return loadFile(at: url)
    }

    private func loadCsvData() {
        self.csvdata = loadDataFile(filepath: self.csvfilename)
    }

    private func getStatementFiles() -> [URL] {
        guard let stmtdir = URL(string: "statements", relativeTo: self.qifdir) else {
            exit(1)
        }

        do {
            return try FileManager.default.contentsOfDirectory(at: stmtdir, includingPropertiesForKeys: nil)
        } catch {
            exit(1)
        }
    }

    private func getStatementLogFile() -> URL? {
        guard let qifdir = self.qifdir else {
            exit(1)
        }

        return URL(string: "statementLog.csv.dat", relativeTo: qifdir)
    }

    private func splitCsvLines() {
        print("\(elapsed): Splitting csv lines...")
        self.csvlines = self.csvdata!.split(separator: "\n")
    }

    private func fieldString(fieldRange r: Range<Int>) -> String {
        guard let data = self.csvdata else {
            return ""
        }

        let idx1 = data.index(data.startIndex, offsetBy: r.startIndex)
        let idx2 = data.index(data.startIndex, offsetBy: r.endIndex)

        return String(data[idx1...idx2])
    }

    // TODO higher performance parsing of csv file?
//    private func processLines(data: String) {
//        guard let data = self.csvdata else {
//            return
//        }
//
//        var tupleIdxs: [[Range<Int>]] = []
//        var tuple: [Range<Int>] = []
//        var worktuple: [String] = []
//
//        var fieldNames: [String] = []
//
//        var linestart = 0
//        var lastcomma = -1
//        var rawfieldstart = 0
//        var fieldstart = 0
//        var instring = false
//        var isFieldNames = false
//        var lastch: Character = " "
//        var lastidx = data.count - 1
//        var fieldComplete = false
//
//        var linecount = 0
//
//        // NB all fields are quoted or empty, e.g. ("foo","bar",,,"baz",,)
//        for (idx, ch) in data.enumerated() {
//            if tupleIdxs.count > 2 || linecount > 9 {
//                break
//            }
//
//            if instring {
//                if ch == "\"" {
//                    print("Saw closing quote")
//                    instring = false
//                    // NB we know the field started with the opening quote and ends here
//                    fieldComplete = true
//                    let r = fieldstart..<idx
//
//                    if fieldNames.isEmpty {
//                        let text = fieldString(fieldRange: r)
//                        if text == "Account" {
//                            isFieldNames = true
//                        }
//                        print("Checking text: '\(text)' fieldnames: \(isFieldNames)")
//
//                        worktuple.append(text)
//                    }
//
//                    lastch = ch
//                }
//            }
//
//            // End field and/or line/file
//            else if ch == "," || ch == "\n" {
//                tuple.append(fieldstart..<idx)
//
//                rawfieldstart = idx + 1
//                fieldstart = 0
//                fieldComplete = false
//
//                if ch == "," {
//                    lastcomma = idx
//
//                    // Add empty field after trailing comma at end of file
//                    if idx == lastidx {
//                        print("Adding empty field at end of last tuple")
//                        tuple.append(0..<0)
//                    }
//                }
//                else { // ch == "\n"
//                    linecount += 1
//
//                    print("End line: fieldnames=\(isFieldNames)")
//                    if isFieldNames {
//                        for r in tuple {
//                            fieldNames.append(fieldString(fieldRange: r))
//                        }
//
//                        print("Setting field names to \(fieldNames)")
//                    }
//
//                    if !tuple.isEmpty && !fieldNames.isEmpty {
//                        print("Adding tuple: \(tuple)")
//                        tupleIdxs.append(tuple)
//                    }
//
//                    tuple = []
//
//                    linestart = idx + 1
//                    fieldstart = linestart
//                    instring = false
//                    isFieldNames = false
//                    lastch = ","
//                }
//            }
//
//            // Start a string - NB must be start of field value
//            else if ch == "\"" {
//                if idx != rawfieldstart {
//                    print("Quote embedded in field!")
//                    exit(1)
//                }
//
//                print("Saw opening quote")
//                instring = true
//                fieldstart = idx + 1
//                lastch = ch
//            }
//
//            else {
//                // carry on
//            }
//        }
//
//        print("\(elapsed): Processing lines")
//    }
}

class StatementProcessor {
    struct StatementPosInfo {
        let s: String
        let q: MMAmount
        let v: MMAmount
        let p: MMAmount
    }

    var model: MMModel

    var inAccountSection: Bool = false
    var inStatementsSection: Bool = false
    var inStatement: Bool = false
    var curAccount: MMAccount? = nil
    var curStatement: MMStatement? = nil

    var acctName: String? = nil
    var statFrequency: Int? = nil
    var statDay: Int? = nil
    var useLastDay = false
    var closeDate: MMDate? = nil

    var statDate: MMDate? = nil
    var statBal: MMAmount? = nil
    var statCashBal: MMAmount? = nil

    var statPositions: [StatementPosInfo] = []

    init(model: MMModel) {
        self.model = model
    }

    func reset() {
        inAccountSection = false
        inStatementsSection = false
        inStatement = false
        curAccount = nil
        curStatement = nil

        statFrequency = nil
        statDay = nil
        useLastDay = false
    }

    func processStatementLines(lines: [Substring]) {
        reset()

        for line in lines {
            if line.isEmpty {
                continue
            }

            let lineType = line.first!
            var val = String(line)
            val.removeFirst()

            if line == "!Account" {
                endAccountSection()
                endStatementsSection()

                startAccountSection()

            } else if line == "!Statements" {
                endStatementsSection()

                startStatementsSection()

            } else if inAccountSection {
                processAccountLine(lineType: lineType, val: val)

            } else if inStatement {
                // NB we are (possibly) in a multi-line statement definition
                processStatementLine(lineType: lineType, val: val)

            } else if inStatementsSection {
                processStatementsLine(lineType: lineType, val: val)
           }
        }

        endStatementsSection()
        endAccountSection()
    }

    func setAccount() {
        guard let aname = acctName else {
            return
        }

        var acct = model.getAccount(name: aname)
        if acct == nil {
            print("reference to nonexistant account '\(aname)'")

            acct = MMAccount(model: model, name: aname)
            let _ = model.add(acct!)
        }

        acct!.statementFrequency = statFrequency
        acct!.statementDay = statDay
        acct!.closeDate = closeDate

        self.curAccount = acct
    }

    func addStatement() {
        guard let stmt = curStatement else {
            return
        }
        guard let acct = curAccount else {
            print("no account")
            exit(1)
        }

        acct.add(stmt)
    }

    func startAccountSection() {
        assert(!inAccountSection)
        assert(!inStatement)
        assert(!inStatementsSection)

        inAccountSection = true

        closeDate = nil
        statFrequency = nil
        statDay = nil
        useLastDay = false
    }

    func endAccountSection() {
        // TODO dont think so endStatementsSection()

        setAccount()

        inAccountSection = false
    }

    func clearAccountInfo() {
        curAccount = nil
    }

    func createStatement() {
        curStatement = MMStatement(account: curAccount!, date: statDate!, cashBalance: statCashBal!)
    }

    func startStatementsSection() {
        guard !inStatementsSection else {
            print("Malformed statements section")
            exit(1)
        }
        guard !inAccountSection else {
            print("Missing account section terminator")
            exit(1)
        }
        if curAccount == nil {
            print("No account for statements")
            exit(1)
        }

        inStatementsSection = true
    }

    func endStatementsSection() {
        endStatement()
        clearStatementInfo()

        inStatementsSection = false
    }

    func endStatement() {
        guard inStatement else {
            return
        }

        createStatement()
        addStatement()

        clearStatementInfo()
    }

    func nextStatDate(date: MMDate) -> MMDate {
        if useLastDay {
            return date.endOfMonth.advanced(by: 1).endOfMonth
        }

        switch statFrequency {
        case 90:
            return date.add(months: 3)

        default:
            return date.add(months: 1)
        }
    }

    func clearStatementInfo() {
        curStatement = nil
        statDate = nil
        statBal = nil
        statCashBal = nil
        statPositions = []

        inStatement = false
    }

    //=======================================================

    func processAccountLine(lineType: Character, val: String) {
        switch lineType {
        case "^":
            endAccountSection()

        case "N":
            acctName = String(val)

        case "F":
            statFrequency = Int(val)

        case "G":
            statDay = Int(val)

        case "C":
            closeDate = MMDate(dateString: val)

        default:
            print("invalid field in account:  '\(lineType)' '\(val)'")
            exit(1)
        }
    }

    //=======================================================

    func processStatementLine(lineType: Character, val: String) {
        switch lineType {
        case "^":
            endStatement()

        case "M":
            processStatementsLine(lineType: lineType, val: val)

        case "C":
            statCashBal = MMAmount(val)

        case "S":
            let valparts = val.split(separator: ";", omittingEmptySubsequences: false)

            guard valparts.count > 3 else {
                print("malformed security line: '\(lineType)' '\(val)'")
                exit(1)
            }

            func getQvpStrings(parts: [Substring]) -> (String, String, String) {
                if parts.count < 5 {
                    return (String(parts[1]), String(parts[2]), String(parts[3]))
                }

                var qvp = String(parts[1])
                var m: [Character : String] = [:]

                m[qvp.first!] = String(parts[2])
                qvp.removeFirst()
                m[qvp.first!] = String(parts[3])
                qvp.removeFirst()
                m[qvp.first!] = String(parts[4])

                return (m["q"] ?? "x", m["v"] ?? "x", m["p"] ?? "x")
            }

            func parseVals(q: String, v: String, p: String, pfd: MMAmount) -> (MMAmount, MMAmount, MMAmount) {
                var qty: MMAmount? = nil
                var sval: MMAmount? = nil
                var price: MMAmount? = nil

                if p == "x" {
                    price = pfd
                } else {
                    price = MMAmount(p)!
                }

                if v == "x" {
                    qty =  MMAmount(q)!
                    sval = price! * qty!
                } else {
                    sval = MMAmount(v)
                    qty = sval! / price!
                }

                return (qty!, sval!, price!)
            }

            // TODO implement security
            let sym = String(valparts[0])
            let sec = model.getSecurity(symbol: sym)
            let priceForDate = sec?.price(on: self.statDate!) ?? MMAmount.one

            let (qtystr, svalstr, pricestr) = getQvpStrings(parts: valparts)

            let (qty, sval, price) = parseVals(q: qtystr, v: svalstr, p: pricestr, pfd: priceForDate)

            statPositions.append(StatementPosInfo(s: sym, q: qty, v: sval, p: price))

        default:
            print("invalid field in statement: '\(lineType)' '\(val)'")
            exit(1)
        }
    }

    func processStatementsLine(lineType: Character, val: String) {
        switch lineType {
        case "^":
            // TODO create statement

            clearStatementInfo()

            inStatementsSection = false

        case "M":
            endStatement()

            let parts = val.split(separator: " ")
            guard parts.count > 1 else {
                print("malformed statement line")
                exit(1)
            }

            // TODO this may be just MM/YYYY format
            let dstr = String(parts[0])
            if dstr.firstIndex(of: "/") != nil
                && dstr.firstIndex(of: "/") == dstr.lastIndex(of: "/") {
                useLastDay = true
            }

            statDate = MMDate(dateString: dstr)


            if parts.count == 2 {
                // NB this could be a oneliner for one stmt, or multiline
                let vstr = String(parts[1])
                // TODO ibm espp has x for value (?)
                statBal = (vstr == "x") ? MMAmount.one : MMAmount(vstr)
                statCashBal = statBal

                inStatement = true

            } else {
                for ii in 1..<parts.count {
                    statBal = MMAmount(String(parts[ii]))
                    statCashBal = statBal

                    let nextdate = nextStatDate(date: statDate!)

                    inStatement = true
                    endStatement()

                    statDate = nextdate
                }
            }

        default:
            print("invalid field in statement: '\(lineType)' '\(val)'")
            exit(1)
        }
    }
}
