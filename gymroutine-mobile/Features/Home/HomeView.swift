//
//  HomeView.swift
//  gymroutine-mobile
//
//  Created by SATTSAT on 2024/12/26
//
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var userManager: UserManager
    
    @State private var isShowTodayworkouts = true
    @State private var createWorkoutFlg = false
    
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
        .fullScreenCover(isPresented: $createWorkoutFlg) {
            CreateWorkoutView()
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // 현재 사용자 프로필 이미지 및 이름 표시
                    if let currentUser = userManager.currentUser {
                        VStack(spacing: 4) {
                            if let url = URL(string: currentUser.profilePhoto), !currentUser.profilePhoto.isEmpty {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 80, height: 80)
                                }
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                            }
                            Text(currentUser.name)
                                .font(.caption)
                                .lineLimit(1)
                                .frame(width: 80)
                        }
                    }
                    // 팔로우 중인 사용자들 표시
                    ForEach(viewModel.followingUsers, id: \.uid) { user in
                        VStack(spacing: 4) {
                            if let url = URL(string: user.profilePhoto), !user.profilePhoto.isEmpty {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 80, height: 80)
                                }
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                            }
                            Text(user.name)
                                .font(.caption)
                                .lineLimit(1)
                                .frame(width: 80)
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 16)
            
            Label("現在\(viewModel.followingUsers.count)人が筋トレしています！", systemImage: "flame")
                .fontWeight(.semibold)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .hAlign(.leading)
                .background(Color.red.opacity(0.3))
        }
    }
    
    private var calendarBox: some View {
        VStack {
            Text("簡易カレンダーView")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var todaysWorkoutsBox: some View {
        VStack {
            Button {
                withAnimation {
                    isShowTodayworkouts.toggle()
                }
            } label: {
                HStack {
                    Text("今日のワークアウト")
                        .font(.title2.bold())
                    
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                        .rotationEffect(.degrees(isShowTodayworkouts ? 90 : 0))
                }
                .hAlign(.leading)
            }
            .foregroundStyle(.primary)
            
            if isShowTodayworkouts {
                if viewModel.todaysWorkouts.isEmpty {
                    Text("今日のワークアウトはありません")
                        .padding()
                } else {
                    ForEach(viewModel.todaysWorkouts, id: \.id) { workout in
                        WorkoutCell(
                            workoutName: workout.name,
                            exerciseImageName: workout.exercises.first?.name,
                            count: workout.exercises.count
                        )
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var userInfoBox: some View {
        VStack {
            if let user = userManager.currentUser {
                Text("\(user.name)の情報")
                    .font(.title2.bold())
                    .hAlign(.leading)
                
                // 임시 정보
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
                    .frame(height: 108)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
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
                    .frame(height: 108)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                Text("ユーザー情報が読み込めません")
            }
        }
    }
    
    private var buttonBox: some View {
        HStack {
            Button {
                createWorkoutFlg.toggle()
            } label: {
                Label("ルーティーン追加", systemImage: "plus")
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Button {
                // 추가 액션 구현
            } label: {
                Label("今すぐ始める", systemImage: "play")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
        .environmentObject(UserManager.shared)
}
