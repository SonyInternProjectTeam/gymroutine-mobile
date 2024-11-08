//
//  MainPageView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/07.
//

// TODO : bottom nav

import SwiftUI

struct MainPageView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("You have successfully logged in!")
                    .font(.title)
                    .padding()

                NavigationLink(destination: TrainSelectionView()) {
                    Text("Workout start")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                Spacer()
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    MainPageView()
}
