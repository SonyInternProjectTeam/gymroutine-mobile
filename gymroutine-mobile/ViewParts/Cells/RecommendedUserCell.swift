//
//  UserCell.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2025/02/25.
//

import SwiftUI

struct RecommendedUserCell: View {
    
    var recommendeduser: RecommendedUser
    
    var body: some View {
        NavigationLink {
            ProfileView(viewModel: ProfileViewModel(user: recommendeduser.user), router: nil)
        } label: {
            VStack {
                HStack {
                    ProfileIcon(profileUrl: recommendeduser.user.profilePhoto, size: .medium1)
                    VStack {
                        if recommendeduser.user.birthday != nil || !recommendeduser.user.gender.isEmpty {
                            Text(getAgeAndGenderText())
                                .font(.caption)
                                .fontWeight(.thin)
                        }
                        Text(recommendeduser.user.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .frame(width: 56, height: 56)
                    .foregroundStyle(.black)
                }
//                今回はProfileViewでフォローを行う
//                followButton(viewModel:ProfileViewModel(user: recommendeduser.user))
//                    .frame(width: 130, height: 28)
            }
            .frame(width: 156,height: 86)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    private func getAgeAndGenderText() -> String {
        var result = ""
        
        // 생일이 있으면 나이 계산
        if let birthday = recommendeduser.user.birthday {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
            if let age = ageComponents.year {
                result += "\(age)歳 "
            }
        }
        
        // 성별 추가
        if !recommendeduser.user.gender.isEmpty {
            result += recommendeduser.user.gender
        }
        
        return result.trimmingCharacters(in: .whitespaces)
    }
}


struct UserListView:View {
    
    var user: User
    
    var body: some View {
        HStack {
            ProfilePhoto(photourl: user.profilePhoto)
            VStack {
                Text(user.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                if user.birthday != nil || !user.gender.isEmpty {
                    Text(getAgeAndGenderText())
                        .font(.caption)
                        .fontWeight(.thin)
                }
            }
            Spacer()
        }
        .background(Color.white)
    }
    
    private func getAgeAndGenderText() -> String {
        var result = ""
        
        // 생일이 있으면 나이 계산
        if let birthday = user.birthday {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
            if let age = ageComponents.year {
                result += "\(age)歳 "
            }
        }
        
        // 성별 추가
        if !user.gender.isEmpty {
            result += user.gender
        }
        
        return result.trimmingCharacters(in: .whitespaces)
    }
}


@ViewBuilder
private func followButton(viewModel: ProfileViewModel) -> some View {
    Button(action: {
        viewModel.follow()
    }) {
        Text("フォロー")
            .foregroundColor(.black)
            .font(.caption)
            .fontWeight(.semibold)
    }
    .buttonStyle(PrimaryButtonStyle())
}

@ViewBuilder
private func ProfilePhoto(photourl: String) -> some View {
    Group {
        if !photourl.isEmpty {
            AsyncImage(url: URL(string: photourl)) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
        } else {
            Image(systemName: "person.circle")
                .resizable()
                .foregroundColor(.gray)
        }
    }
    .frame(width: 56, height: 56)
    .clipShape(Circle())
    
}
