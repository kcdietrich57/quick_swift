//
//  QifLoader.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 3/10/21.
//

import Foundation

typealias ObjectType = String

// Map a QIF string to the corresponding resource
func mapQifType(rawType: String) -> MMResourceType {
    switch rawType {
    case "Tag":
        return .Tag
    case "Cat":
        return .Category
    case "Security":
        return .Security
    case "Prices":
        return .Price
    case "Account":
        return .Account
    case "Oth A", "Invst", "Bank", "Cash", "CCard", "Oth L":
        return .Transaction
    default:
        print("Unknown object type '\(rawType)")
        exit(1)
    }
}

enum QifTransactionAction {
    case Txfr, OXfr, EFT, Dep, ATM, Cash, XIn, Withdraw, WithdrawX,
         Div, ReinvDiv, Interest, IntInc, ReinvInt, ReinvSh, ReinvLg,
         Buy, BuyX,
         Sell, SellX,
         XOut,
         ShrsIn, ShrsOut, StockSplit, ContribX,
         Grant, Vest, Expire, Exersize, ExersizeX,
         Reminder, Schedule,
         Ins, Cks, AW, SC,
         Other, None
}

class QifLoader {
    static func transactionAction(for name: String) -> QifTransactionAction {
        switch name {
        case "": return .None

        case "TXFR": return .Txfr
        case "EFT": return .EFT
        case "DEP": return .Dep
        case "Cash": return .Cash
        case "ATM": return .ATM
        case "WithdrwX": return .WithdrawX

        case "XIn": return .XIn
        case "XOut": return .XOut

        case "IntInc": return .IntInc
        case "DIV": return .Div
        case "Div": return .Div
        case "ReinvDiv": return .ReinvDiv
        case "ReinvLg": return .ReinvLg
        case "ReinvSh": return .ReinvSh

        case "Buy": return .Buy
        case "BuyX": return .BuyX
        case "Sell": return .Sell
        case "SellX": return .SellX
        case "ShrsIn": return .ShrsIn
        case "ShrsOut": return .ShrsOut

        case "Int": return .Interest
        case "OXfr": return .OXfr
        case "StkSplit": return .StockSplit
        case "ReinvInt": return .ReinvInt
        case "ContribX": return .ContribX

        case "Reminder": return .Reminder
        case "Sched": return .Schedule

        case "Grant": return .Grant
        case "Vest": return .Vest
        case "Expire": return .Expire
        case "Exercise": return .Exersize
        case "ExercisX": return .ExersizeX

        //        case "Ins": return .Ins
        //        case "ins": return .Ins
        //        case "cks": return .Cks
        //        case "AW": return .AW
        //        case "SC": return .SC
        case "Ins","ins","cks","AW","SC": return .Other

        default:
            if let _ = Int(name) {
                return .Other
            }

            print("don't know action '\(name)'")
            exit(1)
        }
    }

    let model: MMModel

    init(model: MMModel) {
        self.model = model
    }

    func loadModel() {
        let qifDataFile = URL(fileURLWithPath: "DIETRICH.QIF", relativeTo: model.dataFolderURL)
        let fileLines = loadQifLines(fileUrl: qifDataFile)

        let loader = QifRawLoader(rawLines: fileLines)
        loader.loadAll()

        for rawTag in loader.typedItems["Tag"]! {
            let tag = MMTag(rawItem: rawTag, rawItemId: model.tags.count)
            model.tags.add(tag)
        }

        for rawCat in loader.typedItems["Cat"]! {
            let _ = model.findOrCreateCategory(fullname: rawCat.name)
        }

        for rawSec in loader.typedItems["Security"]! {
            var sec = model.getSecurity(symbol: rawSec.securitySymbol) ??
                MMSecurity(modelid: model.id, rawItem: rawSec, rawItemId: model.securities.count)

            sec = model.add(sec!)
        }

        for rawAcct in loader.typedItems["Account"]! {
            var acct = MMAccount(model: model, rawItem: rawAcct, rawItemId: model.accounts.count)
            acct = model.add(acct)
        }

        for rawTx in loader.typedItems["Transaction"]! {
            let tx = MMTransaction(rawItem: rawTx, rawItemId: model.transactions.count)

            model.add(tx)
        }

        print("  Loaded \(model.tags.count) tags")
        print("  Loaded \(model.categories.count) categories")
        print("  Loaded \(model.accounts.count) accounts")
    }

    func loadQifLines(fileUrl: URL) -> [String.SubSequence] {
        let fmgr = FileManager.default

        guard let fileData = fmgr.contents(atPath: fileUrl.path) else {
            print("Can't open file '\(fileUrl.path)'")
            exit(1)
        }

        print("File \(fileUrl.path) size is \(fileData.count)")

        let fileString = try! String(contentsOfFile: fileUrl.path, encoding: String.Encoding.ascii)

        let fileLines = fileString.split(separator: "\r\n")

        print("File \(fileUrl.path) has \(fileLines.count) lines")

        return fileLines
    }
}
