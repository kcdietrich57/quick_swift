//
//  TUtil.swift
//  SwiftConsole20210206
//
//  Created by Gregory Dietrich on 3/30/21.
//

import Foundation

class UTest {
    static func assert(_ expr: Bool, _ msg: String? = nil) {
        //print(msg ?? "-")
        guard expr else {
            print("  assert failed! \(msg ?? "")")
            exit(1)
        }
    }
}
