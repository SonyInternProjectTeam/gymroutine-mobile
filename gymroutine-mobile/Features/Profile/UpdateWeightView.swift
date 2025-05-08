import SwiftUI

struct UpdateWeightView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var userManager = UserManager.shared
    private let analyticsService = AnalyticsService.shared
    
    @State private var weightInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @FocusState var isFocused: Bool
    
    // Inject UserService or use shared instance
    private let userService = UserService.shared
    
    // Formatter for decimal input
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }()
    
    var body: some View {
        NavigationView { // Use NavigationView for title and buttons
            VStack(alignment: .leading, spacing: 24) {
                
                Text("体重を入力しましょう")
                    .font(.title.bold())
                
                Group {
                    if let currentWeight = userManager.currentUser?.currentWeight {
                        Text("現在の体重: \(String(format: "%.1f", currentWeight)) kg")
                    } else {
                        Text("現在の体重: -- kg")
                    }
                }
                .foregroundStyle(.secondary)
                
                TextField("新しい体重 (kg)", text: $weightInput)
                    .focused($isFocused)
                    .keyboardType(.decimalPad)
                    .font(.title2.bold())
                    .padding(12)
                    .background(Color(UIColor.systemGray6))
                    .multilineTextAlignment(.center)
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
            }
            .padding()
            .vAlign(.top)
            .navigationTitle("体重更新")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveWeight()
                    }
                    .disabled(isLoading || !isValidWeight(weightInput))
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .onAppear(perform: onAppear)
        }
    }
    
    private func onAppear() {
        if let weight = userManager.currentUser?.currentWeight {
            weightInput = String(format: "%.1f", weight)
        }

        analyticsService.logScreenView(screenName: "UpdateWeight")
        
        isFocused = true
    }
    
    private func isValidWeight(_ input: String) -> Bool {
        guard let weight = Double(input), weight > 0, weight < 500 else {
             return false
        }
        return true
    }
    
    private func saveWeight() {
        guard let userId = userManager.currentUser?.uid, let newWeight = Double(weightInput) else {
            errorMessage = "無効な体重です。"
            return
        }
        
        if !isValidWeight(weightInput) {
            errorMessage = "有効な体重を入力してください (例: 70.5)"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await userService.updateWeight(userId: userId, newWeight: newWeight)
            
            await MainActor.run {
                isLoading = false
                switch result {
                case .success:
                    print("Weight updated successfully!")
                    presentationMode.wrappedValue.dismiss() // Close the sheet
                case .failure(let error):
                    print("Failed to update weight: \(error.localizedDescription)")
                    errorMessage = "更新に失敗しました。もう一度お試しください。"
                }
            }
        }
    }
}

struct UpdateWeightView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock UserManager for preview
        let userManager = UserManager.shared
        userManager.currentUser = User(uid: "previewUser", email: "preview@test.com", name: "Preview User", currentWeight: 75.2)
        
        return UpdateWeightView()
            .environmentObject(userManager)
    }
} 
