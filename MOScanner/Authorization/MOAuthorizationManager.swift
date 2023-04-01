//
//  MOAuthorizeManager.swift
//  07_QRScan
//
//  Created by MikiMo on 2019/7/23.
//  Copyright © 2019 moxiaoyan. All rights reserved.
//

import UIKit

enum MOAuthorizeType {
    case camera // 相机
    case photo  // 相册
}

enum MOAuthorizeStatus {
    case unauthorized   // 未授权
    case authorized     // 已授权
    case restricted     // 受限
    case denied         // 拒绝
}

protocol MOAuthrizationProtocol {
    
    /// query authorize status (查询授权状态)
    /// - Returns: current authorize status
    func status() -> MOAuthorizeStatus

    /// request authorize (请求授权)
    /// - Parameter completeHandler: result callback
    func requestAuthorization(completeHandler: @escaping (_ status: MOAuthorizeStatus) -> Void);
}

struct MOAuthorizationManager {
    
    // MARK: - Public Methods
    
    /// check authorization
    /// 1. authorized: directly callback result (已授权：直接返回结果)
    /// 2. unauthorized: request authorization (未授权：申请权限后，返回结果)
    /// 3. rejected: present alert (已拒绝：弹窗提示)
    /// - Parameters:
    ///   - type: authorization type
    ///   - completionHandler: result callback
    static func checkAuthorization(type: MOAuthorizeType,
                            completionHandler: @escaping (_ status: MOAuthorizeStatus) -> Void) {
        authorizationFactory(type: type).requestAuthorization(completeHandler: completionHandler)
    }
    
    // MARK: - Private Methods
    
    /// authorization factory (工厂方法：返回不同类型的授权工具)
    /// Return different authorization tools based on type
    /// - Parameter type: authorization type
    /// - Returns: authorization tool
    static private func authorizationFactory(type: MOAuthorizeType) -> MOAuthrizationProtocol {
        switch type {
        case .camera: return MOAuthorizationCamera()
        case .photo: return MOAuthorizationPhoto()
        }
    }
}

func getTopVC() -> UIViewController? {
    guard let keyWindow = UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .compactMap({$0 as? UIWindowScene})
        .first?.windows
        .filter({$0.isKeyWindow}).first else {
        return nil
    }
    if var topController = keyWindow.rootViewController {
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
    return nil
}
