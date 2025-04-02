//
//  Array+Extensions.swift
//  gymroutine-mobile
//
//  Created by SATTSAT on 2025/02/05
//
//

extension Array {
    //配列を分割する・例：[1,2,3,4,5,6](sizeが2だった場合) -> [[1,2],[3,4],[5.6]]
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
