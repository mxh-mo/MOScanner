//
//  MOScannerViewController.swift
//  MOScanner
//
//  Created by mikimo on 2023/4/1.
//

import UIKit

class MOScannerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Scanner"
        
        /// check authorization when back from background
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(checkAuthorization),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkAuthorization()
    }
    
    @objc func checkAuthorization() {
        MOAuthorizationManager.checkAuthorization(type: .camera) { status in
            if status != .authorized { /// haven't camera permission
                return
            }
            /// have camera permission
        }
    }
}
