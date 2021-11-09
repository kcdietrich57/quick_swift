//
//  security.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 3/22/21.
//

import Foundation

enum MMInvestmentType {
    case Stock, ESPP, EmpStockOption, Income, MutualFund, MoneyMarket, Bond, Other

    static func mapType(name: String) -> MMInvestmentType {
        switch name {
        case "Stock":
            return .Stock
        default:
            return .Other
        }
    }
}

enum MMInvestmentGoal {
    case Growth, Income, LowRisk, Other

    static func mapGoal(name: String) -> MMInvestmentGoal {
        switch name {
        case "Growth":
            return .Growth
        case "Income":
            return .Income
        case "Low Risk":
            return .LowRisk
        default:
            return .Other
        }
    }
}

protocol PMMSecurity { //}: PMMModelObject {
    var symbol: String { get }
    var names: [String] { get }
    var investmentType: MMInvestmentType { get }
    var goal: MMInvestmentGoal { get }
}

//extension PMMSecurity {
//    var name: String { names.first }
//}

class MMSecurity: PMMSecurity, Identifiable, CustomStringConvertible {
    // Name Sym Type Goal
    public private(set) var modelid: Int
    public private(set) var id: Int
    public private(set) var symbol: String
    public private(set) var names: [String]
    public private(set) var investmentType: MMInvestmentType
    public private(set) var goal: MMInvestmentGoal
    public private(set) var desc: String

    func setId(_ id: Int) {
        self.id = id
    }

    var description: String {
        var aka = ""
        if names.count > 1 {
            aka = "\n  aka: ["

            for (n, name) in names[1...].enumerated() {
                if n > 0 {
                    aka += ", "
                }

                aka += "\"\(name)\""
            }

            aka += "]"
        }

        let ret = """
            Security[\(id)]: \(symbol) "\(names[0])"\(aka)
              type:\(investmentType) goal:\(goal)
            """

        return ret
    }

    var name: String {
        names[0]
    }

    init?(modelid: Int,
         id: Int,
         symbol: String,
         names: String...,
         investmentType: MMInvestmentType,
         goal: MMInvestmentGoal) {
        guard let model = MMModel.modelsById[modelid] else {
            return nil
        }
        guard model.getSecurity(symbol: symbol) == nil else {
            return nil
        }

        self.modelid = modelid
        self.id = id

        self.symbol = symbol
        self.names = names
        self.investmentType = .Other
        self.goal = .Other
        self.desc = ""

        let _ = model.add(self)
    }

    convenience init?(modelid: Int, rawItem: RawItemInfo, rawItemId: Int) {
        self.init(modelid: modelid,
                  id: rawItemId,
                  symbol: rawItem.securitySymbol,
                  names: rawItem.name,
                  investmentType: MMInvestmentType.mapType(name: rawItem.securityType),
                  goal: MMInvestmentGoal.mapGoal(name: rawItem.securityGoal))

        // TODO create dummy symbol for security that doesn't have one
        if symbol == "" {
            let model = MMModel.currModel

            for n in 1... {
                let sym = "DUMMY\(n)"
                if model?.getSecurity(symbol: sym) == nil {
                    symbol = sym
                    break
                }
            }
        }
    }

    func addName(name: String) {
        guard !names.contains(name) else {
            return
        }

        names.append(name)
    }

    func price(on date: MMDate) -> MMAmount {
        // TODO implement security
        return MMAmount.one
    }
}
