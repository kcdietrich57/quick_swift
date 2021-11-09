//
//  account.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 3/22/21.
//

import Foundation

class MMAccount: MMModelObject, Identifiable, CustomStringConvertible {

    enum AccountType: String {
        case Banking = "Banking"
        case CreditCard = "CreditCard"
        case Loan = "Loan"
        case Asset = "Asset"
        case Investment = "Investment"
        case Retirement = "Retirement"
    }

    // QIF(main): Name Type Desc creditLimit
    // QIF(main?): /stmtdate $stmtbal
    // QIF(stmt): Closedate statFreq Gstmtday
    // CSV: Name Type(from 1st tx)

    var type: AccountType
    var closeDate: MMDate?
    var statementFrequency: Int?
    var statementDay: Int?

    // TODO trash these
    var accountType: String
    var statementDate: MMDate?
    var statementBalance: MMAmount?
    var creditLimit: MMAmount?

    var transactions: [MMTransaction]
    var cashBalance: [MMAmount]
    // TODO var positions: [MMPosition]
    var statements: [MMStatement]

    var description: String {
        "Account[\(id)]: \(accountType)-\(name) '\(desc)'"
    }

    init(model: MMModel, id: Int, name: String, desc: String?, type: AccountType) {
        self.accountType = ""
        self.type = type
        self.creditLimit = nil
        self.statementDate = nil
        self.statementBalance = nil
        self.closeDate = nil
        self.statementFrequency = nil
        self.statementDay = nil

        transactions = []
        cashBalance = []
        statements = []

        super.init(model: model, id: id, name: name, desc: desc)
    }

    convenience init(model: MMModel, rawItem: RawItemInfo, rawItemId: Int) {
        self.init(model: model, id: rawItemId, name: rawItem.name, desc: rawItem.description, type: .Banking)

        self.accountType = rawItem.accountType
        self.creditLimit = rawItem.creditLimit
        self.statementDate = rawItem.statementDate
        self.statementBalance = rawItem.statementBalance
        self.closeDate = rawItem.closeDate
        self.statementFrequency = rawItem.statementFrequency
        self.statementDay = rawItem.statementDay
    }

    // TODO temporary for development/testing
    convenience init(model: MMModel, name: String) {
        self.init(model: model, id: 0, name: name, desc: "", type: .Banking)
    }

    func add(_ stmt: MMStatement) {
        self.statements.append(stmt)
    }

    func getStatement(date: MMDate) -> MMStatement? {
        for stmt in statements {
            if stmt.date == date {
                return stmt
            }
        }

        return nil
    }

    func getStatement(date: MMDate, balance: MMAmount) -> MMStatement? {
        for stmt in statements {
            if stmt.date == date && stmt.balance == balance {
                return stmt
            }
        }

        return nil
    }

    func add(_ tx: MMTransaction) {
        //print("Adding tx: \(tx.date.description) - \(self.transactions.count) tx in acct")
        var insidx = 0

        // Sort tx by date and reconcile status/date
        for cmpidx in (0..<self.transactions.count).reversed() {
            let cmptx = self.transactions[cmpidx]

            if cmptx.date <= tx.date {
                if cmptx.date == tx.date {
                    if let txstmt = tx.statement {
                        if let cmptxstmt = cmptx.statement {
                            if cmptxstmt.date > txstmt.date {
                                continue
                            }
                        } else {
                            continue
                        }
                    }
                }

                insidx = cmpidx + 1

                break
            }

        }

        self.transactions.insert(tx, at: insidx)
        self.cashBalance.insert(tx.amount, at: insidx)

        updateBalances(startingAt: insidx)

//        for (ii, idx) in (self.transactions.startIndex..<self.transactions.endIndex).reversed().enumerated() {
//            let itx = self.transactions[idx]
//
//            if itx.date <= tx.date {
//                if itx.date == tx.date {
//                    if let txstmt = tx.statement {
//                        if let itxstmt = itx.statement {
//                            if itxstmt.date > txstmt.date {
//                                continue
//                            }
//                        } else {
//                            continue
//                        }
//                    }
//                }
//
//                let nidx = self.transactions.index(after: idx)
//                let iii = self.transactions.count - ii
//
//                let bal = (iii > 0) ? self.cashBalance[iii - 1] : MMAmount.zero
//
//                self.transactions.insert(tx, at: nidx)
//                self.cashBalance.insert(bal.add(tx.amount), at: iii)
//
//                updateBalances(startingAt: iii)
//
//                return
//            }
//        }
    }

    func updateBalances(startingAt: Int) {
        var bal = (startingAt > 0) ? self.cashBalance[startingAt - 1] : MMAmount.zero

        while self.cashBalance.count < self.transactions.count {
            self.cashBalance.append(MMAmount.zero)
        }

//        for ii in max(0, startingAt - 3)..<startingAt {
//            print("\(ii): \(self.transactions[ii].amount.description) \(self.cashBalance[ii].description)")
//        }

        for ii in startingAt..<self.transactions.count {
            bal = bal.add(self.transactions[ii].amount)
            self.cashBalance[ii] = bal
        }

//            print("\(ii): \(self.transactions[ii].amount.description) \(self.cashBalance[ii].description)")
//        }
    }

    func findUnconnectedTransfer(date: MMDate, amount: MMAmount) -> MMTransaction? {
        for tx in transactions {
            if tx.date.isNear(to: date, days: 5) {

            }
        }

        return nil
    }
}
