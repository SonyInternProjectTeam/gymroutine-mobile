//
//  TabBarView.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2024/12/31.
//

import SwiftUI

struct ProgressTabBar<T: Hashable & Equatable>: View {

    let items: [T]
    let currentItem: T
    @Namespace var namespace

    var body: some View {
        HStack(alignment: .bottom) {
            ForEach(items, id: \.self) { item in
                CustomTabBarItem(item: item,
                                 currentItem: currentItem,
                                 namespace: namespace)
            }
        }
    }

    struct CustomTabBarItem: View {

        let item: T
        let currentItem: T
        let namespace: Namespace.ID

        var body: some View {
            Group {
                if currentItem == item {
                    ZStack {
                        Color(.systemGray4)

                        Color.main
                            .matchedGeometryEffect(id: "line",
                                                   in: namespace,
                                                   properties: .frame)
                    }
                } else {
                    Color(.systemGray4)
                }
            }
            .frame(height: 2)
            .animation(.spring(), value: currentItem)
        }
    }
}
