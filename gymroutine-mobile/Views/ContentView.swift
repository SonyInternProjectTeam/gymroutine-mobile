//
//  ContentView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/27.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("main page")
                    .font(.largeTitle)
                    .padding()
                
                NavigationLink(destination: LoginView()) {
                    Text("login")
                        .font(.title)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
