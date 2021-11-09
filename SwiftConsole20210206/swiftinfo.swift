//
//  swiftinfo.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 3/22/21.
//

import Foundation

func convert(from arg: Int) -> Int {
    arg + 1
}

func convert(from arg: Int) -> String {
    "\(arg)"
}

func foo(n: Int) -> Int {
    // omit "return" for simple expression
    n * 2
}

func foo(n: Int) -> String {
    "AS STRING ***\(n * 2)***"
}

func foo(times3 n: Int) -> Int {
    n * 3
}

func foo(times4 n: Int) -> Int {
    n * 4
}

func swiftInfo() {

    var diameter: Double = 1
    let PI = 3.1415_9
    let million = 1_000_000

    func circumference(diameter d: Double) -> Double {
        d * PI
    }

    print("circumference for \(diameter) is \(circumference(diameter: diameter))")

    diameter = 1.5
    // illegal PI = 1.2

    print("circumference for \(diameter) is \(circumference(diameter: diameter))")

    print("")
    print("Max Int: \(Int.max)")
    print("Min/Max Int8: \(Int8.min) \(Int8.max)")
    print("Max Int16: \(Int16.max)")
    print("Min/Max Int32: \(Int32.min) \(Int32.max)")
    print("Max Int64: \(Int64.max)")

    print("")
    print("Min/Max UInt: \(UInt.min) \(UInt.max)")
    print("Max UInt8: \(UInt8.max)")
    print("Max UInt16: \(UInt16.max)")
    print("Max UInt32: \(UInt32.max)")
    print("Max UInt64: \(UInt64.max)")

    //print("")
    //print("Min/Max Float: \(Float.min) \(Float.max)")
    //print("Min/Max Double: \(Float.min) \(Float.max)")

    let lit_decimal = 100
    let lit_binary = 0b10001100111
    let lit_octal = 0o76543210

    typealias MyIdentifier = Int32

    print("\nMax MyIdentifier is \(MyIdentifier.max)")

    // ============================

    var opt_int: Int? = 100
    print("\nopt_int is \(String(describing: opt_int))")
    if opt_int != nil {
        print("Non-optional opt_int was \(opt_int!)")
    }

    opt_int = nil
    print("\nopt_int is \(String(describing: opt_int))")
    if let n = opt_int {
        print("opt_int is not nil: \(n)")
    } else {
        print("opt_int was nil")
    }

    var impl_int: Int! // Optional value, but doesn't need explicit unwrap
    var myint: Int

    impl_int = 5

    // print("myint before initialization: \(myint)")
    opt_int = 123

    myint = opt_int! // Optional needs explicit unwrap
    myint = impl_int // Optional, implicitly unwrapped
    myint = lit_decimal // Non-optional

    print("impl_int is \(String(describing: impl_int))")

    // ============================

    var tuple = (100, "One Hundred")
    print("\ntuple: \(tuple) parts='\(tuple.0)' '\(tuple.1)'")

    var (num, desc) = tuple
    print("num=\(num) desc=\(desc)")

    typealias TupleWithNames = (num:Int, desc:String)

    var tuple2: TupleWithNames = (num: 100, desc: "One Hundred")
    print("t.num=\(tuple2.num) t.desc=\(tuple2.desc)")

    // ============================

    let intVal: Int = 100
    let floatVal: Float = 1.23
    let stringVal: String = "Goodbye, cruel world."
    let arrayVal: [Int] = [1, 3, 4,]
    let dictVal: [String: Int] = ["one": 1, "two": 2]

    print("\n\nHello, World!\n")

    print("intval is \(intVal)")
    print("floatval is \(floatVal)")
    print("stringval is '\(stringVal)'")
    print("arrayval is \(arrayVal)")
    print("dictval is \(dictVal)")

    // ============================

    enum MyError: Error {
        case BadError
        case ReallyBadError
    }

    func error_prone(should_throw:  Bool) throws-> String  {
        if should_throw {
            throw MyError.BadError
        }

        return "Successful!"
    }

    print("\nCalling error_prone:")

    do {
        try print("func normal result: \(error_prone(should_throw: false))")
        try print("func error result: \(error_prone(should_throw: true))")
    } catch {
        print("Error was caught")
    }

    // ============================

    func with_asserts(intarg: Int, strarg: String?) throws {
        // debug build only
        assert(intarg >= 0, "First argument must be non-negative integer")
        // always checked unless compiled with -Ounchecked
        precondition(intarg >= 0, "First argument must be non-negative integer")

        if strarg != nil {
            // do something
        } else {
            assertionFailure("Second argument must not be nil")
        }
    }

    //try with_asserts(intarg: -1, strarg: "foobar")

    // ============================

    assert(9 % 4 == 1, "4 * 2 + 1")
    assert(-9 % 4 == -1, "4 * -1 + (-1)")
    assert(-9 % -4 == -1, "sign ignored: 4 * -1 + (-1)")

    // ============================
    typealias MyTuple = (Int, String, Double)

    assert((1,2,3,4,5,6) == (1,2,3,4,5,6), "standard lib handles up to 7 members")
    // compile error assert((1,2,3,4,5,6,7) == (1,2,3,4,5,6,7))

    func compareTuple(t1: MyTuple, t2: MyTuple) {
        var comp = "equals"

        if (t1 > t2) {
            comp = "is greater than"
        } else if (t1 < t2) {
            comp = "is less than"
        }

        print("\(t1) \(comp) \(t2)")
    }

    let tOne = (1, "one", 1.0)
    let tTwo = (2, "two", 2.0)
    let tUns = (1, "one", 1.0)

    compareTuple(t1: tOne, t2: tUns)
    compareTuple(t1: tUns, t2: tTwo)
    compareTuple(t1: tTwo, t2: tOne)

    // ============================

    var possibleNil: Int?
    var notNil = possibleNil ?? 99
    print("\(String(describing: possibleNil)) -> \(notNil)")
    possibleNil = 10
    notNil = possibleNil ?? 99
    print("\(String(describing: possibleNil)) -> \(notNil)")

    // ============================

    func foobar(a1: Int, args: String..., a2: inout Int) {
        print("a1: \(a1)")
        for (n, arg) in args.enumerated() {
            print("  arg[\(n)]: \(arg)")
        }
        print("a2: \(a2)")

        a2 = 11
    }

    var myvar: Int = 5
    foobar(a1: 5, args: "one", "two", "three", a2: &myvar)
    print("New myvar = \(myvar)")

    let intval: Int = convert(from: 5)
    let strval: String = convert(from: 5)

    print("intval \(intval) strval \(strval)")

    var mathOp: (Int, Int) -> Int = {
        (lhs, rhs) in lhs + rhs
    }

    mathOp = { $0 + $1 }

    print("mathop: \(mathOp(1, 2))")

    func apply(_ lhs: Int, _ rhs: Int, op: (Int,Int)->Int) -> Int {
        op(lhs, rhs)
    }

    print("apply = \(apply(1, 2, op: +))")

    print("apply = \(apply(1, 2) { $0 + $1 })")

    // ============================

    for n in 1...3 { print("1...3 n=\(n)")}
    for n in 1..<3 { print("1..<3 n=\(n)")}
    for n: UInt in 3... { print("3... n=\(n)"); if n > 4 { break }}
    // TODO How do I use ...3?

    // NB The closing quote here establishes the left margin
    // contents are undented back that amount
    var s = """
    this is
      a multiline string
    """
    print(s)

    s = """
      this is also
          a multiline string
          \""" "\"" ""\" \"\"\" containing quotes
      """
    print(s)

    s = #"This string contains special characters \n without escapes"#
    print(s)

    let st = "foo"
    let ch: Character = "c"

    print("s is char: \(st is Character); ch is char: \(ch is Character)")
    print("s is str: \(st is String); ch is str: \(ch is String)")

    let chars: [Character] = [ "a", "b", "c" ]
    s = String(chars)
    print("String from chars: \(s)")
    s.append("x")
    print("String append char: \(s)")
    s.append("yzzy")
    print("String append string: \(s)")

    print("Can interpolated strings contain unescaped quotes? \("yes")")

    s = "foo"
    let s2 = "bar"

    print("concatinating strings: \(s + s2) \(s.append(s2))")

    print("Length of string 'foobar': \("foobar".count)")

    let compositeChar = "\u{E9}\u{20DD}"
    print("Length of composite '\(compositeChar)': \(compositeChar.count)")

    s = "abc\(compositeChar)xyz"
    var x = s.startIndex
    print("First char: \(s[x])")

    for ix in s.indices {
        print("\(s[ix])", separator: ";", terminator: ",")
    }
    print("")

    print("Scalars: ")
    for scalar in  s.unicodeScalars {
        print("\(scalar)", terminator: " ")
    }
    print("")

    var x1 = s.firstIndex(of: "c") ?? s.startIndex
    var x2 = s.firstIndex(of: "y") ?? s.endIndex

    let ss = s[x1..<x2]
    let ss_string = String(ss)
    print("Is string - substring:\(ss is String) string:\(ss_string is String)")
    //print("Is StringProtocol - substring:\(ss is StringProtocol) string:\(ss_string is StringProtocol)")
    print("Substring: x..<x: \(ss) x...x: \(s[x1...x2]) ...x: \(s[...x1]) x...: \(s[x2...])")

    print("prefix? \(s.hasPrefix("abc")) suffix? \(s.hasSuffix("xyz"))")

    var ix = s.firstIndex(of: "r") ?? s.endIndex
    s.insert(contentsOf: "-plugh-", at: ix)
    print("String insert \(s)")

    //s.utf8 s.utf16

    // ============================

    var someints = [Int]()
    someints = []
    var moreints: [Int] = []
    print("Empty? \(someints.isEmpty)")

    var floats = Array(repeating: 1.23, count: 5)
    print("Repeating empty? \(floats.isEmpty) count:\(floats.count) contents:\(floats)")
    floats += [4.56, 7.89]
    print("concat count:\(floats.count) contents:\(floats)")
    floats.append(PI)
    print("append count:\(floats.count) contents:\(floats)")
    floats.insert(2.14, at: 2)
    print("insert count:\(floats.count) contents:\(floats)")
    var rr = floats.remove(at: 4)
    print("remove \(rr) count:\(floats.count) contents:\(floats)")
    rr = floats.removeLast()
    print("removeLast \(rr) count:\(floats.count) contents:\(floats)")

    // ============================
    var set1 = Set<Int>()
    set1 = [1,2,3]
    set1.insert(5)

    print("set(\(set1.count)): \(set1)")

    print("contains 8, 3: \(set1.contains(8)) \(set1.contains(3))")
    var sr = set1.remove(8)
    print("remove 8: \(String(describing: sr))")
    sr = set1.remove(3)
    print("remove 3: \(String(describing: sr))")

    for e in set1 { print("\(e)", terminator: ",")}; print("")
    for e in set1.sorted() { print("\(e)", terminator: ",")}; print("")

    // ============================
    var dict = [1: "one", 2: "two"]

    print("dict keys: \(dict.keys) values: \(dict.values)")
    for (k,v) in dict {
        print("  (\(k): \(v))")
    }
    var old = dict.updateValue("uns", forKey: 1)
    print("Updated \(String(describing: old)) to \(String(describing: dict[1]))")
    old = dict.updateValue("three", forKey: 3)
    print("Updated \(String(describing: old)) to \(String(describing: dict[3]))")

    dict[2] = nil
    print("Remove 2 via subscript: \(dict)")
    old = dict.removeValue(forKey: 1)
    print("removeValue 3: old=\(String(describing: old)) \(dict)")

    // ============================

    var counter = 3
    repeat {
        print("boo")
        counter -= 1
    } while counter > 0

    for n in [-2, 0, 4, 5, 6, 99, 100] {
        print("n=\(n): ", terminator: " ")
        switch n {
        case ..<0:
            print("negative")
        case ...5:
            print("up to 5")
        case 0..<100:
            print("more than 5, less than 100")
        default:
            print("something else")
        }
    }

    let points = [(99,1), (100,2), (1,1), (0,0), (1,0), (0, 1000)]
    for p in points {
        print("\(p): ", terminator: "")

        switch p {
        case (0,0):
            print("zeros")
        case (let x, let y) where x == y:
            print("x,y both equal \(x)")
            fallthrough  // No reason, following condition is not checked
        case (_,0):
            print("y is zero")
        case (0, let y):
            print("x is zero, y is \(y)")
        case (..<100, _):
            print("x less than 100")
        default:
            print("something else")
        }
    }

    // ============================
    func doit(_ n: Int, _ m: Int) -> String? {
        guard n * m < 7 else {
            return nil
        }

        return "\(n * m)"
    }

    outer:
    for n in 1...5 {
        for m in 1...5 {
            if let s = doit(n, m) {
                print("\(n) * \(m) = \(s)")
            } else {
                continue outer
            }
        }
    }

    // ============================
    var flag = false
    if #available(iOS 14, *) {
        flag = true
    }
    print("iOS14: \(flag)")

    flag = false
    if #available(macOS 11.2, *) {
        flag = true
    }
    print("macOS11.2: \(flag)")

    flag = false
    if #available(macOS 11.2.3, *) {
        flag = true
    }
    print("macOS11.2.3: \(flag)")

    // ============================

    print("foox2 \(foo(n: 5))") // Uses ->String version; Why is this not ambiguous
    // foo(n: 5) This is ambiguous
    let ii: Int = foo(n: 5)
    let sss: String = foo(n: 5)

    print("foox3 \(foo(times3: 5))")
    print("foox4 \(foo(times4: 5))")

    func getPair() -> (n: Int, String) {
        return (5, "five")
    }

    let pair = getPair()
    print("pair: \(pair), pair.n: \(pair.n), pair.1: \(pair.1)")

    func optParam(_ n: Int, m: String = "one") -> (Int, String) {
        return (n, m)
    }
    print("\(optParam(1)) \(optParam(2, m: "two"))")

    #if swift(>=5.4)
        print("swift is less than 5.4")
    #else
    #if swift(>=5.3)
        print("swift >= 5.3")
    #else
        print("swift is less than 5.3")
    #endif
    #endif

    #if swift(<5.4)
    func variadic(id: Int, numbers: Int..., name: String) {
        print("id: \(id) name: \(name)")
        for (ii, number) in numbers.enumerated() {
            print("  number \(ii): \(number)")
        }
    }

    variadic(id: 1, numbers: 3, 5, 7, name: "bob")

    #else
    func variadic(id: Int, numbers: Int..., name: String, children: String..., age: Int) {
        print("id: \(id) age: \(age)")
        for (ii, number) in numbers.enumerated() {
            print("  number \(ii): \(number)")
        }
        for (ii, child) in children.enumerated() {
            print("  child \(ii): \(child)")
        }
    }

    variadic(id: 1, numbers: 3, 5, 7, name: "bob", children: "tom", "sally", age: 53)
    #endif

    func setZero(_ changeme: inout Int) -> Int{
        let old = changeme
        changeme = 0
        return old
    }

    var nonz = 1
    print("Set nonz to zero, old: \(setZero(&nonz))")

    func dosomething() {
        print("something")
    }
    func dosomethingelse() {
        print("something else")
    }

    var fn: ()->Void = dosomething
    fn()
    fn = dosomethingelse
    fn()


    // ============================
    // ============================
    // ============================
    // ============================
    // ============================
    // ============================
    // ============================

}
