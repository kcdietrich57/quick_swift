//
//  mmdate.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 3/22/21.
//

import Foundation

struct MMDate: CustomStringConvertible, Comparable, Strideable {
   static let secsPerDay: Double = 24 * 60 * 60
    static let fiveHours: TimeInterval = 12 * 60 * 60

    static func ymd(y: Int, m: Int, d: Int) -> Int {
        y * 10000 + m * 100 + d
    }

    static var today: MMDate {
        let now = Date()

        let dc = Calendar.current.dateComponents([.year,.month,.day], from: now)
        let reldays = toDays(ymd: ymd(y: dc.year!, m: dc.month!, d: dc.day!))!

        return MMDate(days: reldays)!
    }

    static func monthDays(year: Int, month: Int) -> Int {
        if [1, 3, 5, 7, 8, 10, 12].contains(month) {
            return 31
        }

        if [4, 6, 9, 11].contains(month) {
            return 30
        }

        let leap = (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0))
        return leap ? 29 : 28
    }

    static func toDays(ymd: Int) -> Int? {
        let year = ymd / 10000
        let month = (ymd / 100) % 100
        let day = ymd % 100

        guard year > 0 && //
                month > 0 && month < 13 && //
                day > 0 && day <= monthDays(year: year, month: month) else {
            return nil
        }

        let now = Date()

        var dc = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: now)

        dc.year = year
        dc.month = month
        dc.day = day
        dc.hour = 5
        dc.minute = 0
        dc.second = 0
        dc.nanosecond = 0
        dc.timeZone = TimeZone(secondsFromGMT: 0)

        let newdate = Calendar.current.date(from: dc) ?? now

        let relsec = newdate.timeIntervalSinceReferenceDate
        var reldays = relsec / secsPerDay
        if reldays < 0 {
            reldays -= 1
        }

        return Int(reldays)
    }

    static func toYMD(days: Int) -> Int {
        let secs = TimeInterval(Double(days) * secsPerDay + fiveHours)
        let d = Date(timeIntervalSinceReferenceDate: secs)
        //print("Created \(d) from \(days) days -> \(secs) secs")
        let dc = Calendar.current.dateComponents([.year,.month,.day], from: d)
        //print("Components: y=\(dc.year!) m=\(dc.month!) d=\(dc.day!)")

        return (dc.year! * 10000) + (dc.month! * 100) + dc.day!
    }

    static func - (lhs: MMDate, rhs: MMDate) -> Int {
        return lhs.relDays - rhs.relDays
    }

    static func - (lhs: MMDate, rhs: Int) -> MMDate {
        return MMDate(days: lhs.relDays - rhs)!
    }

    static func + (lhs: MMDate, rhs: Int) -> MMDate {
        return MMDate(days: lhs.relDays + rhs)!
    }

    static func == (lhs: MMDate, rhs: MMDate) -> Bool {
        return lhs - rhs == 0
    }

    static func < (lhs: MMDate, rhs: MMDate) -> Bool {
        return lhs - rhs < 0
    }

    static func parse(_ s: String) -> Int? {
        if s == "" {
            return nil
        }

        let century = (s.contains("'") ? "20" : "19")
        let ss = s.replacingOccurrences(of: "'", with: "/")
        let parts = ss.split(separator: "/")

        let mmstr: String = String(parts[0]).trimmingCharacters(in: .whitespaces)
        var ddstr: String = ""
        var yystr: String = ""

        if parts.count < 3 {
            ddstr = "31"
            yystr = String(parts[1]).trimmingCharacters(in: .whitespaces)
        } else {
            ddstr =  String(parts[1]).trimmingCharacters(in: .whitespaces)
            yystr = String(parts[2]).trimmingCharacters(in: .whitespaces)
        }

        let mm = Int(mmstr)!

        var yy = Int(yystr)!
        if yy < 30 || century == "20" {
            yy += 2000
        } else if yy < 100 {
            yy += 1900
        }

//        if yystr.count == 2 {
//            yystr = century + yystr
//        }

        let dd = min(Int(ddstr)!, monthDays(year: yy, month: mm))

        return yy * 10000 + mm * 100 + dd
    }

    // Encoded as YYYYMMDD, MM is 1-12 DD is 1-31
    var rawDate: Int
    var relDays: Int

    var description: String {
        return "\(month)/\(day)/\(year)"
    }

    var year: Int {
        rawDate / 10000
    }

    var month: Int {
        (rawDate / 100) % 100
    }

    var day: Int {
        rawDate % 100
    }

    var daysInMonth: Int {
        Self.monthDays(year: self.year, month: self.month)
    }

    var endOfMonth: MMDate {
        MMDate(year: self.year, month: self.month, day: self.daysInMonth)!
    }

    init?(ymd: Int?) {
        guard let ymd = ymd else {
            return nil
        }

        guard let days = Self.toDays(ymd: ymd) else {
            return nil
        }

        relDays = days
        rawDate = MMDate.toYMD(days: relDays)
    }

    init?(days: Int) {
        rawDate = Self.toYMD(days: days)
        relDays = days
        //print("init for \(relDays) days -> raw \(rawDate)")
    }

    init?(year: Int, month: Int, day: Int) {
        self.init(ymd: year * 10000 + month * 100 + day)
    }

    init?(dateString: String) {
        self.init(ymd: Self.parse(dateString))
    }

    func asString() -> String {
        return description
    }

    func asQifString() -> String {
        let shortyear = (year < 2000) ? (year - 1900) : (year - 2000)
        let yearsep = (year < 2000) ? "/" : "'"

        return "\(month)/\(day)\(yearsep)\(shortyear)"
    }

    func isNear(to other: MMDate, days: Int) -> Bool {
        let diff = abs(self.distance(to: other))

        let ret = diff <= days

        //print("near? \(ret) \(self.asString()) vs \(other.asString()): \(diff) compare \(days)")
        return ret
    }

    func advanced(by n: Int) -> MMDate {
        MMDate(days: self.relDays + n)!
    }

    func add(days: Int) -> MMDate {
        MMDate(days: self.relDays + days)!
    }

    func add(months: Int) -> MMDate {
        var m = self.month + months
        var y = self.year

        while m > 12 {
            y += 1
            m -= 12
        }

        let d = min(self.day, MMDate.monthDays(year: y, month: m))

        return MMDate(year: y, month: m, day: d)!
    }

    func distance(to other: MMDate) -> Int {
        return other - self
    }

    func nextMonth(day: Int = 99) -> MMDate {
        let newyear = year + ((month == 12) ? 1 : 0)
        let newmonth = (month % 12) + 1
        let lastday = Self.monthDays(year: newyear, month: newmonth)
        let newday = max(day, lastday)

        return MMDate(year: newyear, month: newmonth, day: newday)!
    }

    func lastMonth(day: Int = 99) -> MMDate {
        let newyear = year - ((month == 1) ? 1 : 0)
        let newmonth = (month == 1) ? 12 : (month - 1)
        let lastday = Self.monthDays(year: newyear, month: newmonth)
        let newday = max(day, lastday)

        return MMDate(year: newyear, month: newmonth, day: newday)!
    }

    static func test() {
        print("\n===== Test MMDate =====\n")

        var xd = MMDate(ymd: 20211301)
        UTest.assert(xd == nil, "bad month should be nil, is instead \(String(describing: xd))")
        xd = MMDate(ymd: 20210100)
        UTest.assert(xd == nil, "bad day (0) should be nil, is instead \(String(describing: xd))")
        xd = MMDate(ymd: 20210132)
        UTest.assert(xd == nil, "bad day (32) should be nil, is instead \(String(describing: xd))")

        var d = MMDate(ymd: 20210318)!
        let reldays210318 = 7381

        // Test that we can format/parse as/from Quicken date string
        let qstr = d.asQifString()
        var d2 = MMDate(dateString: qstr)
        UTest.assert(d == d2, "parsing qstr \(d.asString()) \(d2?.asString() ?? "n/a")")

        var d1 = MMDate(dateString: "3/18'21")
        UTest.assert(d1 == d, "init(String) \(d.asString()) \(d1?.asString() ?? "n/a"))")

        // Test that we can convert to/from relative days
        d1 = MMDate(days: reldays210318)
        UTest.assert(d1 == d, "init(relDays(\(reldays210318)))")

        // Test that we can convert to/from ymd
        d1 = MMDate(year: 2021, month: 3, day: 18)
        UTest.assert(d1 == d, "init(Int:Int:Int)")
        d1 = MMDate(ymd: 20210318)
        UTest.assert(d1 == d, "init(ymd)")

        UTest.assert(d.year == 2021, "property year")
        UTest.assert(d.month == 3, "property month \(d.month)")
        UTest.assert(d.day == 18, "property day")
        UTest.assert(d.rawDate == 20210318, "property rawdate")
        UTest.assert(d.relDays == reldays210318, "property reldays \(reldays210318) \(d.relDays)")

        // +/- distance near
        d1 = d + 2
        UTest.assert(d < d1!, "plus n")
        UTest.assert(d.distance(to: d1!) == 2, "1 distance d/d1 \(d.distance(to: d1!))")
        UTest.assert(d1!.distance(to: d) == -2, "2 distance d1/d \(d1!.distance(to: d))")

        d1 = d - -2
        UTest.assert(d < d1!, "minus -n")
        UTest.assert(d.distance(to: d1!) == 2, "3 distance d/d1 \(d.distance(to: d1!))")
        UTest.assert(d1!.distance(to: d) == -2, "4 distance d1/d \(d1!.distance(to: d))")

        d1 = d - 2
        UTest.assert(d > d1!, "minus n")
        UTest.assert(d > d1!, "advance \(d.asString()) > \(d1?.asString() ?? "n/a")")
        UTest.assert(d.distance(to: d1!) == -2, "5 distance \(d.distance(to: d1!))")
        UTest.assert(d1!.distance(to: d) == 2, "6 distance \(d1!.distance(to: d))")

        d1 = d + -2
        UTest.assert(d > d1!, "plus -n")
        UTest.assert(d.distance(to: d1!) == -2, "7 distance d/d1 \(d.distance(to: d1!))")
        UTest.assert(d1!.distance(to: d) == 2, "8 distance d1/d \(d1!.distance(to: d))")

        UTest.assert(d.isNear(to: d1!, days: 3), "1 nearto/3 distance: \(d.distance(to: d1!))")
        UTest.assert(d.isNear(to: d1!, days: 2), "2 nearto/2 distance: \(d.distance(to: d1!))")
        UTest.assert(!d.isNear(to: d1!, days: 1), "3 nearto/1 distance: \(d.distance(to: d1!))")

        // isNear
        UTest.assert(d.isNear(to: d1!, days: 2), "4 nearto 2 d/d1 \(d.distance(to: d1!))")
        UTest.assert(!d.isNear(to: d1!, days: 1), "5 nearto 1 d/d1 \(d.distance(to: d1!))")
        UTest.assert(d1!.isNear(to: d, days: 2), "6 nearto 2 d1/d \(d1!.distance(to: d))")
        UTest.assert(!d1!.isNear(to: d, days: 1), "7 nearto 1 d1/d \(d1!.distance(to: d))")

        d1 = MMDate(ymd: 20210401)
        UTest.assert(d.isNear(to: d1!, days: 20))
        UTest.assert(!d.isNear(to: d1!, days: 10))

        d1 = MMDate(ymd: 20210301)
        UTest.assert(d.isNear(to: d1!, days: 20))
        UTest.assert(!d.isNear(to: d1!, days: 10))

        // Date that our dates are relative to
        d2 = MMDate(days: 0)
        UTest.assert(d2?.rawDate == 20010101)

        // Edge case - +/ at start/end of month
        d1 = MMDate(ymd: 20200131)

        d2 = d1! + 1
        UTest.assert(d2?.month == 2 && d2?.day == 1, "+ Expected 2/1: \(d2?.asString() ?? "n/a")")
        d2 = d2! - 1
        UTest.assert(d1 == d2, "- expected 1/31 \(d2?.asString() ?? "n/a")")

        // Edge case +/- at start/end of year
        d1 = MMDate(ymd: 20201231)

        d2 = d1! + 1
        UTest.assert(d2?.year == 2021 && d2?.month == 1 && d2?.day == 1,
                    "Expected 1/1/2021: \(d2?.asString() ?? "n/a")")
        d2 = d2! - 1
        UTest.assert(d1 == d2, "- expected 12/31/2020 \(d1?.asString() ?? "n/a")")

        print("\n===== Test MMDate Strideable =====\n")

        let bday1 = MMDate(ymd: 19560602)!
        let bday2 = MMDate(ymd: 19571118)!

        UTest.assert(bday1 < bday2, "expected bday1 < bday2")
        let dist1 = bday1.distance(to: bday2)
        let dist2 = bday2.distance(to: bday1)

        d = MMDate(ymd: 19960228)!
        var eom = d.endOfMonth
        print("EOM for \(d) is \(eom)")
        UTest.assert(d < eom, "bad eom \(d) != \(d.endOfMonth)")

        d = MMDate(ymd: 19000228)!
        eom = d.endOfMonth
        print("EOM for \(d) is \(eom)")
        UTest.assert(d == eom, "bad eom \(d) >= \(d.endOfMonth)")

        d = MMDate(ymd: 20000228)!
        eom = d.endOfMonth
        print("EOM for \(d) is \(eom)")
        UTest.assert(d < eom, "bad eom \(d) != \(d.endOfMonth)")

        d = MMDate(ymd: 20000229)!
        eom = d.endOfMonth
        print("EOM for \(d) is \(eom)")
        UTest.assert(d == eom, "bad eom \(d) != \(d.endOfMonth)")

        print("distance is +- \(abs(dist1)) days")

        UTest.assert(bday1.advanced(by: dist1) == bday2, "bad date arithmetic1 TD+dist1")
        UTest.assert(bday2.advanced(by: dist2) == bday1, "bad date arithmetic2 GD+dist2")

        for dd in stride(from: bday1, through: bday2, by: 30) {
            print("  \(dd)")
        }

        print("\n===== END Test MMDate =====\n")
    }
}
