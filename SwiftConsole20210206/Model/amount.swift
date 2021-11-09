//
//  amount.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 3/22/21.
//

import Foundation

struct MMAmount: CustomStringConvertible, Comparable {
    static func + (lhs: MMAmount, rhs: MMAmount) -> MMAmount {
        let sum: Decimal = lhs.decimalValue + rhs.decimalValue
        let precision: Int = max(lhs.decimalPosition, rhs.decimalPosition)

        return MMAmount(decimalValue: sum, decimalPosition: precision)
    }

    static func - (lhs: MMAmount, rhs: MMAmount) -> MMAmount {
        let diff: Decimal = lhs.decimalValue - rhs.decimalValue

        return MMAmount(decimalValue: diff)
    }

    // TODO what is the proper precision?
    static func * (lhs: MMAmount, rhs: MMAmount) -> MMAmount {
        let res: Decimal = lhs.decimalValue * rhs.decimalValue

        return MMAmount(decimalValue: res)
    }

    // TODO what is the proper precision?
    static func / (lhs: MMAmount, rhs: MMAmount) -> MMAmount {
        let res: Decimal = lhs.decimalValue / rhs.decimalValue

        return MMAmount(decimalValue: res)
    }

    static func < (lhs: MMAmount, rhs: MMAmount) -> Bool {
        lhs.decimalValue < rhs.decimalValue
    }

    static func == (lhs: MMAmount, rhs: MMAmount) -> Bool {
        lhs.decimalValue == rhs.decimalValue
    }

    static let zero = MMAmount("0.00")!
    static let one = MMAmount("1.00")!

    static func parse(_ str: String) -> (dval: Decimal, ival: Int, dpos: Int)? {
        let s = str.trimmingCharacters(in: .whitespaces)
        guard s.filter({ !"0123456789.,-".contains($0) }).count == 0 else {
            print("Invalid amount '\(s)'")
            exit(1)
            //return nil
        }

        let ss = s.filter{ $0 != "," }

        guard let decimal = Decimal(string: ss) else {
            if !ss.isEmpty {
                print("Failed to parse decimal '\(ss)'")
            }
            
            return nil
        }

        var d = 0
        var m = 0

        if let dp = ss.lastIndex(of: ".") {
            d = ss[dp...].count - 1
            m = Int(ss.filter{ $0 != "." })!

            //let multiplier = Int(truncating: NSDecimalNumber(decimal: pow(10, d - 1)))

            //m *= multiplier
        }

        return (decimal, Int(m), d)
    }

    static func formatAmount(decimalValue: Decimal, decimalPosition: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.groupingSeparator = ","
        numberFormatter.groupingSize = 3
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.decimalSeparator = "."
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = decimalPosition
        numberFormatter.maximumFractionDigits = decimalPosition

        return numberFormatter.string(from: decimalValue as NSNumber)!
     }

    let decimalValue: Decimal
    let rawAmount: Int
    let decimalPosition: Int
    private var text: String

    var description: String {
        return MMAmount.formatAmount(decimalValue: self.decimalValue, //
                                     decimalPosition:  self.decimalPosition)
    }

    init(decimalValue: Decimal = Decimal.zero, rawAmount: Int = 0, decimalPosition: Int = 2) {
        self.rawAmount = rawAmount
        self.decimalPosition = decimalPosition

        self.decimalValue = decimalValue
        self.text = MMAmount.formatAmount(decimalValue: decimalValue, //
                                          decimalPosition: decimalPosition)
    }

    init?(_ amountStr: String) {
        guard let (dval, d, m) = MMAmount.parse(amountStr) else {
            return nil
        }

        self.init(decimalValue: dval, rawAmount: d, decimalPosition: m)

       // print("\(amountStr) -> m=\(m) d=\(d) D=\(decimalValue)")
    }

    func asString() -> String {
        return self.text
    }

    static func calcDecimal(rawValue: Int, decimalPosition: Int) -> Decimal {
        var multiplier = pow(Decimal(10), decimalPosition)
        multiplier = Decimal(1) / multiplier
        return Decimal(rawValue) * multiplier
    }

    init(rawValue: Int, decimalPosition: Int) {
        let dv = MMAmount.calcDecimal(rawValue: rawValue, decimalPosition: decimalPosition)
        self.init(decimalValue: dv, rawAmount: rawValue, decimalPosition: decimalPosition)
    }

    func normalize(decimalPosition: Int) -> MMAmount {
        if self.decimalPosition == decimalPosition {
            return self
        }

        let dv = MMAmount.calcDecimal(rawValue: self.rawAmount, decimalPosition: decimalPosition)

        return MMAmount(decimalValue: dv, rawAmount: self.rawAmount, decimalPosition: decimalPosition)
    }

    func add(_ other: MMAmount) -> MMAmount {
        let dec = max(self.decimalPosition, other.decimalPosition)
        let lhs = normalize(decimalPosition: dec)
        let rhs = other.normalize(decimalPosition: dec)

        let ret = MMAmount(rawValue: lhs.rawAmount + rhs.rawAmount, decimalPosition: dec)
        return ret
    }

    static func test() {
        print("\n===== Test MMAmount =====\n")

        for valstr in ["0", "1", "1.2", "1.23", "1.20", "12.345", "1.005", "1,234.5678", "-123.4567"] {
            let a = MMAmount(valstr)

            let s = a?.asString() ?? "n/a"

            UTest.assert(valstr == "\(s)", "string value for '\(valstr)'")
        }

        var d1: MMAmount = MMAmount("1.234")!
        var d2: MMAmount = MMAmount("1.111")!

        var d3: MMAmount = d1 - d2
        UTest.assert(d3 == MMAmount("0.123"), "sub decimals '\(d3)'")

        d3 = d1 + d2
        UTest.assert(d3 == MMAmount("2.345"), "add decimals '\(d3)'")

        d1 = MMAmount("1.000")!
        print("1.000 -> '\(d1.asString())'")

        d1 = MMAmount("0.500")!
        d2 = MMAmount(".5")!

        d3 = d1 + d2
        print(".500+.5 -> '\(d3.asString())'")

        d3 = d2 + d1
        print(".5+.500 -> '\(d3.asString())'")

        print("\n===== END Test MMAmount =====\n")
    }
}
