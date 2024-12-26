//
//  SuccessView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/29.
//

import Foundation
import SwiftUI

struct SuccessView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        NavigationView { 
            VStack {
                Text("Login Successful!")
                    .font(.largeTitle)
                    .padding()
                
                Text("Hello, \(userManager.currentUser?.name ?? "Guest")")
                Text("You have successfully logged in!")
                    .font(.title)
                    .padding()

                // TrainSelectionView NavigationLink
                NavigationLink(destination: TrainSelectionView()) {
                    Text("Go to Train Selection")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Success Page")
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    SuccessView()
}
