//
//  statement.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 3/22/21.
//

import Foundation

class MMStatement: MMModelObject, Identifiable, CustomStringConvertible {
    var isReconciled: Bool
    weak var account: MMAccount?
    var date: MMDate
    var cashBalance: MMAmount

    var txinfo: [TxInfo]
    var secinfo: [TxSecInfo]

    var securityBalance: MMAmount {
        // TODO implement security
        MMAmount("0.00")!
    }

    var balance: MMAmount {
        cashBalance + securityBalance
    }

    var transactions: [MMTransaction]

    var description: String {
        "Stmt[\(date)]: bal=\(balance) cash=\(cashBalance) tx=\(transactions.count) txinfo=\(txinfo.count)"
    }

    init(id: Int, account: MMAccount) {
        self.account = account

        self.date = MMDate.today
        self.cashBalance = MMAmount.zero
        self.isReconciled = false

        self.transactions = []
        self.txinfo = []
        self.secinfo = []

        let model = MMModel.currModel!

        super.init(model: model, id: id, name: "", desc: nil)
    }

    convenience init(rawItem: RawItemInfo,
                     rawItemId: Int,
                     account: MMAccount) {
        self.init(id: rawItemId, account: account)

        self.date = rawItem.date
        self.cashBalance = rawItem.statementBalance
    }

    convenience init(account: MMAccount, date: MMDate, cashBalance: MMAmount) {
        self.init(id: -1, account: account)

        self.date = date
        self.cashBalance = cashBalance
    }

    func addTransactionInfo(_ txinfo: TxInfo) {
        self.txinfo.append(txinfo)
    }

    func addSecurityInfo(_ secinfo: TxSecInfo) {
        self.secinfo.append(secinfo)
    }
}
