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
    static var bannerWindow: UIWindow?
    
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
    
    // ローディングViewの非表示
    static func hideLoading() {
        loadingWindow = nil
    }
    
    static func showBanner(type: BannerType, message: String) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        
        let newWindow = TransparentTouchWindow(windowScene: windowScene)
        let vc = UIHostingController(rootView: BannerView(type: type, message: message))
        
        vc.view.backgroundColor = .clear
        newWindow.rootViewController = vc
        newWindow.windowLevel = UIWindow.Level.alert + 1
        UIApplication.bannerWindow = newWindow
        newWindow.makeKeyAndVisible()
    }
}

// View表示部分以外のタッチを有効可するカスタムUIWindow
final class TransparentTouchWindow: UIWindow {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event),
              let rootView = rootViewController?.view else {
                  return nil
              }
        
        if #available(iOS 18, *) {
            for subView in rootView.subviews.reversed() {
                let pointInSubView = subView.convert(point, from: rootView)
                if subView.hitTest(pointInSubView, with: event) == subView {
                    return hitView
                }
            }
            
            return nil
        } else {
            return hitView == rootView ? nil : hitView
        }
    }
}

