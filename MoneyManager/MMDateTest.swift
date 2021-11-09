//
//  MMDateTest.swift
//  MoneyManager
//
//  Created by Gregory Dietrich on 3/22/21.
//

import XCTest
@testable import SwiftConsole20210206

class MMDateTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let d = MMDate(ymd: 20210322)
        XCTAssertNotNil(d)
    }

    func testDate() throws {
        print("\n===== Test MMDate =====\n")

        let d = MMDate(ymd: 20210318)!
        let reldays210318 = 7381

        // Test that we can format/parse as/from Quicken date string
        let qstr = d.asQifString()
        var d2 = MMDate(dateString: qstr)
        XCTAssert(d == d2, "parsing qstr \(d.asString()) \(d2?.asString() ?? "n/a")")

        var d1 = MMDate(dateString: "3/18'21")
        XCTAssert(d1 == d, "init(String) \(d.asString()) \(d1?.asString() ?? "n/a"))")

        // Test that we can convert to/from relative days
        d1 = MMDate(days: reldays210318)
        XCTAssert(d1 == d, "init(relDays(\(reldays210318)))")

        // Test that we can convert to/from ymd
        d1 = MMDate(year: 2021, month: 3, day: 18)
        XCTAssert(d1 == d, "init(Int:Int:Int)")
        d1 = MMDate(ymd: 20210318)
        XCTAssert(d1 == d, "init(ymd)")

        XCTAssert(d.year == 2021, "property year")
        XCTAssert(d.month == 3, "property month \(d.month)")
        XCTAssert(d.day == 18, "property day")
        XCTAssert(d.rawDate == 20210318, "property rawdate")
        XCTAssert(d.relDays == reldays210318, "property reldays \(reldays210318) \(d.relDays)")

        // +/- distance near
        d1 = d + 2
        XCTAssert(d < d1!, "plus n")
        XCTAssert(d.distance(to: d1!) == 2, "distance d/d1 \(d.distance(to: d1!))")
        XCTAssert(d1!.distance(to: d) == 2, "distance d1/d \(d1!.distance(to: d))")
        d1 = d - -2
        XCTAssert(d < d1!, "minus -n")
        XCTAssert(d.distance(to: d1!) == 2, "distance d/d1 \(d.distance(to: d1!))")
        XCTAssert(d1!.distance(to: d) == 2, "distance d1/d \(d1!.distance(to: d))")

        d1 = d - 2
        XCTAssert(d > d1!, "minus n")
        XCTAssert(d > d1!, "advance \(d.asString()) > \(d1?.asString() ?? "n/a")")
        XCTAssert(d.distance(to: d1!) == 2, "distance \(d.distance(to: d1!))")
        d1 = d + -2
        XCTAssert(d > d1!, "plus -n")
        XCTAssert(d.distance(to: d1!) == 2, "distance d/d1 \(d.distance(to: d1!))")
        XCTAssert(d1!.distance(to: d) == 2, "distance d1/d \(d1!.distance(to: d))")

        XCTAssert(d.isNear(to: d1!, days: 3), "nearto/3 distance: \(d.distance(to: d1!))")
        XCTAssert(d.isNear(to: d1!, days: 2), "nearto/2 distance: \(d.distance(to: d1!))")
        XCTAssert(!d.isNear(to: d1!, days: 1), "nearto/1 distance: \(d.distance(to: d1!))")

        // isNear
        XCTAssert(d.isNear(to: d1!, days: 2), "nearto 2 d/d1 \(d.distance(to: d1!))")
        XCTAssert(!d.isNear(to: d1!, days: 1), "nearto 1 d/d1 \(d.distance(to: d1!))")
        XCTAssert(d1!.isNear(to: d, days: 2), "nearto 2 d1/d \(d1!.distance(to: d))")
        XCTAssert(!d1!.isNear(to: d, days: 1), "nearto 1 d1/d \(d1!.distance(to: d))")

        d1 = MMDate(ymd: 20210401)
        XCTAssert(d.isNear(to: d1!, days: 20))
        XCTAssert(!d.isNear(to: d1!, days: 10))

        d1 = MMDate(ymd: 20210301)
        XCTAssert(d.isNear(to: d1!, days: 20))
        XCTAssert(!d.isNear(to: d1!, days: 10))

        // Date that our dates are relative to
        d2 = MMDate(days: 0)
        XCTAssert(d2?.rawDate == 20010101)

        // Edge case - +/ at start/end of month
        d1 = MMDate(ymd: 20200131)

        d2 = d1! + 1
        XCTAssert(d2?.month == 2 && d2?.day == 1, "+ Expected 2/1: \(d2?.asString() ?? "n/a")")
        d2 = d2! - 1
        XCTAssert(d1 == d2, "- expected 1/31 \(d2?.asString() ?? "n/a")")

        // Edge case +/- at start/end of year
        d1 = MMDate(ymd: 20201231)

        d2 = d1! + 1
        XCTAssert(d2?.year == 2021 && d2?.month == 1 && d2?.day == 1,
                    "Expected 1/1/2021: \(d2?.asString() ?? "n/a")")
        d2 = d2! - 1
        XCTAssert(d1 == d2, "- expected 12/31/2020 \(d1?.asString() ?? "n/a")")

        print("\n===== END Test MMDate =====\n")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
