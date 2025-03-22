//
//  SnsView.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2024/12/30.
//

import SwiftUI

struct SnsView: View {
    @State private var showSearchOverlay: Bool = false

    // 테스트용 추천 사용자 데이터 (실제 데이터로 대체 가능)
    let testUsers: [User] = [
        User(uid: "5CKiKZmOzlhkEECu4VBDZGltkrn2",
             email: "wkk03240324@gmail.com",
             name: "Kakeru Koizumi",
             profilePhoto: "",
             visibility: 2,
             isActive: false,
             birthday: Date(timeIntervalSince1970: 1017570720),
             gender: "男",
             createdAt: Date(timeIntervalSince1970: 1735656838)
        ),
        User(uid: "7KSQ7Wlqr9OFa9j1CXdtBqbGkLU2",
             email: "kazusukechin@gmail.com",
             name: "Kazu",
             profilePhoto: "",
             visibility: 2,
             isActive: false,
             birthday: Date(timeIntervalSince1970: 1704182340),
             gender: "",
             createdAt: Date(timeIntervalSince1970: 1703839169)
        ),
        User(uid: "AIvdESvweDaVwEednWjk6oekzJQ2",
             email: "test4@test.com",
             name: "Test4",
             profilePhoto: "https://firebasestorage.googleapis.com:443/v0/b/gymroutine-b7b6c.appspot.com/o/profile_photos%2FAIvdESvweDaVwEednWjk6oekzJQ2.jpg?alt=media&token=c750172f-c5a5-4f4f-ba05-f18c04278158",
             visibility: 2,
             isActive: false,
             birthday: Date(timeIntervalSince1970: 1733775060),
             gender: "男性",
             createdAt: Date(timeIntervalSince1970: 1733071896)
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 메인 콘텐츠 (추천 사용자 영역 등)
                VStack(alignment: .leading) {
                    // 상단 검색 버튼 (누르면 오버레이 활성화)
                    Button(action: {
                        showSearchOverlay = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("ユーザーを検索")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // 추천 사용자 영역
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "person.2")
                            Text("おすすめ")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding(.leading, 16)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(testUsers, id: \.name) { user in
                                    UserProfileView(user: user)
                                }
                            }
                            .padding(.leading, 16)
                        }
                    }
                    .padding(.top)
                    
                    Spacer()
                }
                
                // 검색 오버레이: 오버레이가 활성화되면 SnsView의 콘텐츠를 완전히 가림
                if showSearchOverlay {
                    SearchUserView(showOverlay: $showSearchOverlay)
                        .background(Color(.systemBackground)) // 불투명 배경
                        .ignoresSafeArea(edges: .all)        // 전체 영역 덮음
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
    }
}

#Preview {
    SnsView()
}
