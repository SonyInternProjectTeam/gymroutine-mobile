//
//  HomeView.swift
//  gymroutine-mobile
//
//  Created by SATTSAT on 2024/12/26
//
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: MainViewModel
    @EnvironmentObject var userManager: UserManager
    
    @State private var isShowTodayworkouts = true
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            
            header
            
            VStack(spacing: 24) {
                
                calendarBox
                
                todaysWorkoutsBox
                
                userInfoBox
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
        .contentMargins(.top, 16)
        .contentMargins(.bottom, 80)
        .overlay(alignment: .bottom) {
            buttonBox
                .clipped()
                .shadow(radius: 4)
                .padding()
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    //仮表示
                    ForEach(0..<20) {_ in
                        Circle()
                            .fill(.main)
                            .frame(width: 80, height: 80)
                    }
                }
            }
            .contentMargins(.horizontal, 16)
            
            Label("現在2人が筋トレしています！", systemImage: "flame")
                .fontWeight(.semibold)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .hAlign(.leading)
                .background(.red.opacity(0.3))
        }
    }
    
    private var calendarBox: some View {
        VStack {
            Text("簡易カレンダーView")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background()
        .clipShape(.rect(cornerRadius: 8))
    }
    
    private var todaysWorkoutsBox: some View {
        VStack {
            Button {
                withAnimation() {
                    isShowTodayworkouts.toggle()
                }
            } label: {
                HStack {
                    Text("今日のワークアウト")
                        .font(.title2.bold())
                    
                    Image(systemName: isShowTodayworkouts ? "chevron.up" : "chevron.down")
                        .fontWeight(.semibold)
                }
                .hAlign(.leading)
            }
            .foregroundStyle(.primary)
            
            if isShowTodayworkouts {
                //仮表示
                ForEach(0..<2) {_ in
                    WorkoutCell()
                }
            }
        }
    }
    
    private var userInfoBox: some View {
        VStack {
            if let user = userManager.currentUser {
                Text("\(user.name)の情報")
                    .font(.title2.bold())
                    .hAlign(.leading)
                
                //仮情報
                HStack {
                    VStack(spacing: 16) {
                        Text("累計トレーニング日数")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .hAlign(.leading)
                        
                        HStack(alignment: .bottom) {
                            Text("128")
                                .font(.largeTitle.bold())
                            
                            Text("日")
                        }
                        .hAlign(.trailing)
                    }
                    .padding()
                    .hAlign(.center)
                    .frame(height: 108)
                    .background()
                    .clipShape(.rect(cornerRadius: 8))
                    
                    VStack {
                        Text("現在の体重")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .hAlign(.leading)
                        
                        HStack(alignment: .bottom) {
                            Text("64")
                                .font(.largeTitle.bold())
                            
                            Text("kg")
                        }
                        .hAlign(.trailing)
                    }
                    .padding()
                    .hAlign(.center)
                    .frame(height: 108)
                    .background()
                    .clipShape(.rect(cornerRadius: 8))
                }
            } else {
                Text("ユーザー情報が読み込めません")
            }
        }
    }
    
    private var buttonBox: some View {
        HStack {
            Button {
                
            } label: {
                Label("ルーティーン追加", systemImage: "plus")
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Button {
                
            } label: {
                Label("今すぐ始める", systemImage: "play")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

#Preview {
    HomeView(viewModel: MainViewModel(router: Router()))
        .environmentObject(UserManager.shared)
}
