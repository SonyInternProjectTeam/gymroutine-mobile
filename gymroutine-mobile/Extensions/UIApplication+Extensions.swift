//
//  UIApplication+Extensions
//  gymroutine-mobile
//
//  Created by SATTSAT on 2025/03/20
//
//

import Foundation
import UIKit
import SwiftUI

extension UIApplication {
    
    static var loadingWindow: UIWindow?
    
    //ローディングViewの表示
    static func showLoading(message: String? = nil) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        
        let newWindow = UIWindow(windowScene: windowScene)
        let vc = UIHostingController(rootView: LoadingView(message: message))
        
        vc.view.backgroundColor = .clear
        newWindow.rootViewController = vc
        newWindow.windowLevel = UIWindow.Level.alert + 1
        UIApplication.loadingWindow = newWindow
        newWindow.makeKeyAndVisible()
    }
    
    static func hideLoading() {
        loadingWindow = nil
    }
}
