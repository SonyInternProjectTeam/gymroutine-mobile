//
//  ProfileIcon.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2025/04/27.
//

import SwiftUI

struct ProfileIcon: View {

    let profileUrl: String
    let size: SizeType

    enum SizeType {
        case large  // ProfileView
        case medium // FollowersList, FollowingList, HomeView etc...
        case small  // StoryView

        var dimension: CGFloat {
            switch self {
            case .large: return 112
            case .medium: return 64
            case .small: return 32
            }
        }

        var borderColor: Color {
            switch self {
            case .large: return .white
            case .medium, .small: return Color.gray.opacity(0.5)
            }
        }

        var lineWidth: CGFloat {
            switch self {
            case .large: return 4
            case .medium, .small: return 1
            }
        }
    }

    var body: some View {
        Group {
            if let url = URL(string: profileUrl), !profileUrl.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color(.init(gray: 0.8, alpha: 1.0))
                        .blinking(duration: 0.75)
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.gray, Color(UIColor.systemGray5))
            }
        }
        .scaledToFill()
        .clipShape(Circle())
        .overlay {
            Circle()
                .strokeBorder(size.borderColor, lineWidth: size.lineWidth)
        }
        .frame(width: size.dimension, height: size.dimension)
    }
}

#Preview {
    HStack {
        VStack {
            ProfileIcon(profileUrl: "https://firebasestorage.googleapis.com:443/v0/b/gymroutine-b7b6c.appspot.com/o/profile_photos%2FAhGAfsGPU8cwvsONT2duSFcQGdJ2.jpg?alt=media&token=ff276c63-7f22-46d4-86bb-7afaab1ab933", size: .small)

            ProfileIcon(profileUrl: "https://firebasestorage.googleapis.com:443/v0/b/gymroutine-b7b6c.appspot.com/o/profile_photos%2FAhGAfsGPU8cwvsONT2duSFcQGdJ2.jpg?alt=media&token=ff276c63-7f22-46d4-86bb-7afaab1ab933", size: .medium)

            ProfileIcon(profileUrl: "https://firebasestorage.googleapis.com:443/v0/b/gymroutine-b7b6c.appspot.com/o/profile_photos%2FAhGAfsGPU8cwvsONT2duSFcQGdJ2.jpg?alt=media&token=ff276c63-7f22-46d4-86bb-7afaab1ab933", size: .large)
        }
        VStack {
            ProfileIcon(profileUrl: "", size: .small)

            ProfileIcon(profileUrl: "", size: .medium)

            ProfileIcon(profileUrl: "", size: .large)
        }
    }
    .hAlign(.center)
    .vAlign(.center)
    .background(.mainBackground)
}
