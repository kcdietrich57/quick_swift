//
//  main.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 2/6/21.
//

import Foundation

// TODO move this somewhere else
func crString(_ cr: ComparisonResult) -> String {
    switch cr {
    case .orderedSame: return "Same"
    case .orderedAscending: return "Ascending"
    case .orderedDescending: return "Descending"
    }
}

extension ComparisonResult {
    var displayString: String {
        crString(self)
    }
}

func testStuff() {
    //swiftInfo()

    #if swift(<5.0)
    print("Really old swift (<5)")
    #elseif swift(>=5.5)
    print("Modern swift (5.5+)")
    #elseif swift(>=5.4)
    print("Modern swift (5.4)")
    #elseif swift(>=5.3)
    print("Modern swift (5.3)")
    #elseif swift(>=5.2)
    print("Modern swift (5.2)")
    #elseif swift(>=5.1)
    print("Modern swift (5.1)")
    #else
    print("Modern swift (5)")
    #endif

    for s in [
        "1,234.567", "1,234.001",
        "-1,234.56", "1,234,567.89",
        "123.4", "123.456,7"
        //"bogus"
    ] {
        let v = MMAmount(s)
        print("amount for '\(s)': \(String(describing: v))")
    }

    let nf = NumberFormatter()
    print("\(String(describing: nf.number(from: "1,234.56")))")

    MMAmount.test()
    MMDate.test()

    print("Test compete.")
}

func loadQif() {
    let fmgr = FileManager.default
    let homeDir = fmgr.homeDirectoryForCurrentUser

    let dataUrl = URL(fileURLWithPath: "qif/data", relativeTo: homeDir)

    let modelName = "MyModel"
    let model = MMModel(name: modelName, dataFolderURL: dataUrl)

    MMModel.setModel(name: modelName)

    model.importQIF()
    model.processTransfers()
    model.describe()
}

func loadCsv() {
    // Set data location
    let home = FileManager.default.homeDirectoryForCurrentUser
    let qifdir = URL(fileURLWithPath: "qif", isDirectory: true, relativeTo: home)

    // Create/set the model
    let model = MMModel(name: "mymodel", dataFolderURL: qifdir)
    MMModel.setModel(name: "mymodel")

    // Populate the current model with data
    let loader = CsvLoader()
    loader.loadCsv(filename: "DIETRICH.csv")

    // Summarize model contents
    print("Created \(model.accounts.count) accounts")

    print("Created \(model.categories.count) categories")

    var numstat = 0
    model.accounts.forEach {
        numstat += $0?.statements.count ?? 0
    }
    print("Created \(numstat) statements")

//    for (ii, cat) in model.categoryByName.values.sorted().enumerated() {
//        let indent = String(repeating: "..", count: cat.nesting)
//        print("\(ii): \(indent)[\(cat.id)] \(cat.fullname)")
//    }

//    for (ii, acct) in model.accounts.enumerated() {
//        if let acct = acct {
//            if acct.cashBalance.last == MMAmount.zero {
//                continue
//            }
//
//            let txcount = acct.transactions.count
//            let statcount = acct.statements.count
//            print("\(ii): \(acct.name)[\(acct.id)] type=\(acct.type.rawValue) numtx=\(txcount) numstat=\(statcount)")
//
//            for idx in max(0, txcount - 4)..<txcount {
//                let tx = acct.transactions[idx]
//                let bal = acct.cashBalance[idx]
//
//                print("  \(idx + 1): \(tx.date) \(tx.payee) \(tx.amount) \(bal)")
//            }
//        }
//    }
}

//var d = Decimal(10)
//var e = 2
//var r = pow(d, e)
//print("\(d) ** \(e) = \(r)")
//exit(0)

loadCsv()

exit(1)

testStuff()

loadQif()
