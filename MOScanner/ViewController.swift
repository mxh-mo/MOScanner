//
//  ViewController.swift
//  MOScanner
//
//  Created by mikimo on 2023/4/1.
//
//  Add these key-values to in Info.plist to describe the request permission
//  Privacy - Camera Usage Description
//  Privacy - Photo Library Usage Description

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let btn = UIButton(type: .custom)
        btn.setTitle("Start Scanning", for: .normal)
        btn.setTitleColor(.cyan, for: .normal)
        let originX = self.view.bounds.width / 2.0 - 100
        btn.frame = CGRect(x: originX, y: 100, width: 200, height: 50)
        btn.addTarget(self, action: #selector(didClickBtn), for: .touchUpInside)
        self.view.addSubview(btn)
    }

    @objc func didClickBtn() {
        self.navigationController?.pushViewController(MOScannerViewController(), animated: true)
    }
}

