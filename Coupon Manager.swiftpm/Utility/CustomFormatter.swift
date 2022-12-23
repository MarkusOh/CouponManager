//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2022/12/23.
//

import Foundation

extension NumberFormatter {
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.currencyCode = "KRW"
        formatter.zeroSymbol  = ""
        return formatter
    }()
}
