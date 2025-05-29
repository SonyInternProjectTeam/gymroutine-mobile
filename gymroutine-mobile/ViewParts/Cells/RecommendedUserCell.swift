//
//  UserCell.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2025/02/25.
//

import SwiftUI

struct RecommendedUserCell: View {

    var user: User

    var body: some View {
        NavigationLink {
            ProfileView(user: user)
        } label: {
            VStack(spacing: 12) {
                ProfileIcon(profileUrl: user.profilePhoto, size: .medium1)

                VStack {
                    Text(user.name)
                        .lineLimit(1)
                        .font(.headline)
                        .fontWeight(.bold)

                    Group {
                        if user.birthday != nil || !user.gender.isEmpty {
                            Text(getAgeAndGenderText())

                        } else {
                            Text("-")
                        }
                    }
                    .lineLimit(1)
                    .font(.caption)
                    .fontWeight(.thin)
                    .padding(.horizontal, 4)
                }
                .foregroundStyle(.black)
            }
            .frame(width: 140)
            .padding(.top, 24)
            .padding(.bottom, 12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
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

#Preview {
    RecommendedUserCell(user: User(uid: "previewUser1", email: "preview@example.com", name: "Preview User", birthday: Date(), gender: "男性"))
}
