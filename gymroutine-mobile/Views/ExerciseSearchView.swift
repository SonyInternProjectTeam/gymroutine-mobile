//
//  ExerciseSearchView.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/11/26.
//

import SwiftUI

struct ExerciseSearchView: View {
    @Binding var text: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20){
                CategoryView
                ExeriseTabView
            }
            .padding([.top, .horizontal], 24)
            .background(.gray.opacity(0.2))
            
                .searchable(text: $text , placement: .automatic, prompt: "エクササイズを検索")
                .onSubmit(of: .search) {
                    print("search")
                }
//            要変更
//                .navigationTitle("エクササイズ検索")
//                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var CategoryView: some View {
        VStack (alignment: .center, spacing:40){
            VStack(alignment: .leading, spacing: 12) {
                Text("カテゴリ")
                    .fontWeight(.bold)
                    .hAlign(.leading)
                    .font(.title2)
                    .fontWeight(.bold)
                HStack (spacing:20){
                    ExersiceCategoryToggle(title: "腕")
                    ExersiceCategoryToggle(title: "腹筋")
                    ExersiceCategoryToggle(title: "足")
                }
            }
        }
    }
    
    private var ExeriseTabView: some View {
        VStack (alignment: .center, spacing:40){
            VStack(alignment: .leading, spacing: 12) {
                Text("おすすめ")
                    .fontWeight(.bold)
                    .hAlign(.leading)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            ScrollView {
                ForEach(1..<4) {_ in
                    HStack(alignment: .center, spacing: 13) {
                        ExersiceSelectButton()
                        ExersiceSelectButton()
                    }
                }
            }
        }
    }
}



#Preview {
    @Previewable @State var text = ""
    ExerciseSearchView(text: $text)
}
