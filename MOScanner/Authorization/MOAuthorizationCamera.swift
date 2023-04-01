//
//  MOAuthorizationCamera.swift
//  07_QRScan
//
//  Created by MikiMo on 2019/7/26.
//  Copyright © 2019 moxiaoyan. All rights reserved.
//

import UIKit
import AVFoundation

struct MOAuthorizationCamera: MOAuthrizationProtocol {
    func requestAuthorization(completeHandler: @escaping (_ status: MOAuthorizeStatus) -> Void) {
        /// 1. authorized: directly callback result (已授权：直接返回结果)
        if self.status() == .authorized {
            completeHandler(self.status())
            return
        }
        /// 2. unauthorized: request authorization (未授权：申请权限后，返回结果)
        if (self.status() == .unauthorized) {
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                completeHandler(self.status())
            }
            return
        }
        /// 3. rejected: present alert (已拒绝：弹窗提示)
        let alert = UIAlertController(title: "Camera access limited",
                                      message: "Jump to `Settings` to allow access to your camera",
                                      preferredStyle: .alert)
        
        /// add cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completeHandler(self.status())
        }
        alert.addAction(cancelAction)
        
        /// add jump set action
        let setAction = UIAlertAction(title: "Set", style: .default) { (_) in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                print("set url error")
                return
            }
            if !UIApplication.shared.canOpenURL(url) {
                print("can't open url: (url)")
                return
            }
            /// jump to set page
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        alert.addAction(setAction)
        
        /// present alert
        getTopVC()?.present(alert, animated: true, completion: nil)
    }
    
    func status() -> MOAuthorizeStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined: return .unauthorized
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        default: return .denied
        }
    }

}

