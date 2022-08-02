//
//  FSAVDemoVC.swift
//  FSAVDemo
//
//  Created by louis on 2022/8/2.
//

import UIKit

class FSAVDemoVC : FSAVBaseVC {
    
    deinit {
        
    }
    
    lazy var avButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.frame = CGRect(x: 100, y: 80, width: 180, height: 50)
        button.setTitle("AVFoundation Demo", for: .normal)
        button.backgroundColor = .green
        button.titleLabel?.textColor = .white
        
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        
        button.addTarget(self, action: #selector(gotoAVFoundation(sender:)), for: .touchUpInside)
        
        return button;
    }()
    
    lazy var ffmpegButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.frame = CGRect(x: 100, y: 160, width: 180, height: 50)
        button.setTitle("FFmpeg Demo", for: .normal)
        button.backgroundColor = .green
        button.titleLabel?.textColor = .white
        
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        
        button.addTarget(self, action: #selector(gotoFFmpeg(sender:)), for: .touchUpInside)
        
        return button;
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "音视频示例"
        
        setupUI()
    }
    
    private func setupUI() {
        
        view.addSubview(avButton)
        view.addSubview(ffmpegButton)
    }
    
    @objc private func gotoAVFoundation(sender: UIButton) {
        let vc = FSAVFoundationVC()
        vc.title = "AVFoundation Demo"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func gotoFFmpeg(sender: UIButton) {
        let vc = FSFFmpegVC()
        vc.title = "FFmpeg Demo"
        navigationController?.pushViewController(vc, animated: true)
    }
}
