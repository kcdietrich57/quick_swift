//
//  transaction.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 3/22/21.
//

import Foundation
import CloudKit

struct MMTransactionItem {
    weak var parent: MMTransaction?

    var category: MMCategory?
    var transferAccount: MMAccount?
    var transferTransaction: MMTransaction?
    var amount: MMAmount
    var memo: String
}

class MMTransaction: MMModelObject, Identifiable, CustomStringConvertible {
    // (non-investment) Number Payee $splitamt
    // (investment) Naction Pline1 $xferamt
    // Address Splitcat Esplitmemo
    // Date Ysecurity Iprice Quant TUamount Cleared Memo Ocommission Lxferacct

    var action: QifTransactionAction
    let account: MMAccount
    var date: MMDate
    var payee: String { self.name }
    var checkNumber: Int?
    var statement: MMStatement?

    // NB For now at least, we can only have a single security transaction
    var security: MMSecurity?
    var price: MMAmount?
    var quantity: MMAmount?
    var commission: MMAmount?

    // NB Multiple cash operations may be combined here
    var items: [MMTransactionItem] = []

    var amount: MMAmount {
        var total = MMAmount.zero

        for item in self.items {
            total = total.add(item.amount)
        }

        return total
    }

    var memo: String {
        switch self.items.count {
        case 0:
            return ""
        case 1:
            return self.items[0].memo
        default:
            return "[Splits]"
        }
    }

    var category: MMCategory? {
        switch self.items.count {
        case 0:
            return nil
        case 1:
            return self.items[0].category
        default:
            // TODO what to do with multiple categories?
            return nil
        }
    }

    var transferAccount: MMAccount? {
        switch self.items.count {
        case 0:
            return nil
        case 1:
            return self.items[0].transferAccount
        default:
            // TODO what to do with multiple categories?
            return nil
        }
    }

    var transferAmount: MMAmount? {
        switch self.items.count {
        case 0:
            return nil
        case 1:
            let item = self.items.first!
            if item.transferAccount != nil {
                return item.amount
            }
            return nil
        default:
            // TODO what to do with multiple categories?
            return nil
        }
    }

    var transferTransaction: MMTransaction? {
        switch self.items.count {
        case 0:
            return nil
        case 1:
            return self.items.first?.transferTransaction
        default:
            // TODO what to do with multiple categories?
            return nil
        }
    }


    // P-line1 A-address C-cleared

    // DTPL

    var description: String {
        let acctname = self.account.name
        let catstr = categoryOrTransferString(category: category, xferacct: transferAccount)

        var splitstr = ""
        for (n, item) in items.enumerated() {
            let catstr = categoryOrTransferString(category: item.category, xferacct: item.transferAccount)

            splitstr += "\n  [\(n + 1)]: \(item.amount.asString()) \(item.memo) \(catstr)"
        }

        var astring = "-"

        if checkNumber != nil {
            astring = "\(checkNumber!)"
        } else if action != .None {
            astring = "\(action)"
        }

        return "Tx[\(id)]: \(date.asString()) \(astring) \(acctname)  \(payee)  \(amount.asString()) \(catstr)\(splitstr)"
    }

    init(model: MMModel, //
         id: Int, //
         acct: MMAccount, //
         date: MMDate, //
         action: QifTransactionAction?, //
         //txtype: MMTranType, //
         chknum: Int?, //
         payee: String, //

         security: MMSecurity?, //
         amount: MMAmount?, //
         quantity: MMAmount?, //
         price: MMAmount?, //
         commission: MMAmount?) {
        self.account = acct

        self.date = date
        self.action = action ?? .Other
        self.checkNumber = chknum

        self.security = security
        self.quantity = quantity
        self.price = price
        self.commission = commission

        self.statement = nil

        super.init(model: model, id: id, name: payee, desc: "")
    }

    convenience init(model: MMModel, id: Int, acct: MMAccount, payee: String) {
        self.init(model: model, id: id, acct: acct, date: MMDate.today, action: .Other, chknum: nil, payee: payee, security: nil, amount: MMAmount.zero, quantity: nil, price: nil, commission: nil)

        self.items.append(MMTransactionItem(parent: self, category: nil, transferAccount: nil, transferTransaction: nil, amount: MMAmount.zero, memo: ""))
    }

    convenience init(rawItem: RawItemInfo, rawItemId: Int? = nil) {
        //let s = rawItem.format()

        guard let model = MMModel.currModel else {
            print("No model!")
            exit(1)
        }

        guard let txacct = model.getAccount(name: rawItem.account!) else {
            print("Can't find account '\(String(describing: rawItem.account))")
            exit(1)
        }

        self.init(model: model, id: rawItemId ?? 0, acct: txacct, payee: rawItem.payee)

        //account = txacct
        date = rawItem.date
        self.action = QifLoader.transactionAction(for: rawItem.action ?? "")

        checkNumber = rawItem.checkNumber

        // TODO some of these are mutually exclusive
        for splitInfo in rawItem.splits ?? [] {
            var item = MMTransactionItem(
                parent: self,
                transferAccount: nil,
                amount: MMAmount(splitInfo.splitAmount) ?? MMAmount.zero,
                memo: splitInfo.splitMemo)

            item.amount = MMAmount(splitInfo.splitAmount) ?? MMAmount.zero
            item.memo = splitInfo.splitMemo

            if splitInfo.splitCat.first == "[" && splitInfo.splitCat.last == "]" {
                item.transferAccount = model.getAccount(name: String(splitInfo.splitCat.dropFirst().dropLast()))
            }
            else {
                item.category = model.getCategory(fullname: splitInfo.splitCat)
            }

            addItem(item)
        }

        var xacct: MMAccount? = nil
        var xamount: MMAmount? = nil
        var cat: MMCategory? = nil

        if rawItem.category.first == "[" && rawItem.category.last == "]" {
            xacct = model.getAccount(name: String(rawItem.category.dropFirst().dropLast()))
            xamount = amount
        }
        else {
            // TODO do we ever have category and transferAccount?
            cat = model.getCategory(fullname: rawItem.category)

            xacct = model.getAccount(name: rawItem.transferAccountName)
            xamount = rawItem.transferAmount
        }

        if xamount != nil && xamount != amount {
            print("Partial transfer not handled!")
            exit(1)
        }

        self.items.append(MMTransactionItem(parent: self, category: cat, transferAccount: xacct, transferTransaction: nil, amount: rawItem.amount, memo: rawItem.memo))

        security = model.getSecurity(symbol: rawItem.securitySymbol)
        quantity = rawItem.quantity
        price = rawItem.price
        commission = rawItem.commission
    }

    func addItem(category: MMCategory?, //
                  transferAccount: MMAccount?, //
                  transferTransaction: MMTransaction?, //
                  amount: MMAmount, //
                  memo: String) {
        addItem(MMTransactionItem( //
            parent: self, category: category, //
            transferAccount: transferAccount, transferTransaction: transferTransaction, //
            amount: amount, memo: memo))
    }

    func addItem(_ split: MMTransactionItem) {
        items.append(split)
    }

    func getUnconnectedTransfer() -> (MMAccount?, MMAmount?) {
        if transferAccount != nil && transferTransaction == nil {
            return (transferAccount, transferAmount)
        }

        for item in self.items {
            if item.transferAccount != nil && transferTransaction == nil {
                return (item.transferAccount, item.amount)
            }
        }

        return (nil, nil)
    }

    func connectTransfer(with other: MMTransaction) {
        // TODO implement;
        //self.transferTransaction = other
        //other.transferTransaction = self
    }
}
