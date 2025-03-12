//
//  FSAVDemoVC.swift
//  FSAVDemo
//
//  Created by louis on 2022/8/2.
//

import UIKit

class FSAVDemoVC: FSAVBaseVC, UITableViewDelegate, UITableViewDataSource {

    deinit {
        
    }

    // 列表数据
    let demoOptions = [
        "音频相关": [
            ("AVFoundation Demo", #selector(gotoAVFoundation)),
            ("FFmpeg Demo", #selector(gotoFFmpeg))
        ],
        "图形相关": [
            ("OpenGL Demo", #selector(gotoOpenGL)),
            ("Video Play Demo", #selector(gotoVideoPlay))
        ],
        "智能设备相关": [
            ("PassKit Demo", #selector(gotoPassKit))
        ]
    ]

    // 创建 UITableView
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "示例"
        
        setupUI()
    }

    private func setupUI() {
        view.addSubview(tableView)
    }

    // UITableViewDataSource 方法
    func numberOfSections(in tableView: UITableView) -> Int {
        return demoOptions.keys.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = Array(demoOptions.keys)[section]
        return demoOptions[key]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let key = Array(demoOptions.keys)[indexPath.section]
        cell.textLabel?.text = demoOptions[key]?[indexPath.row].0
        return cell
    }

    // UITableViewDelegate 方法
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Array(demoOptions.keys)[section]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = Array(demoOptions.keys)[indexPath.section]
        let selector = demoOptions[key]?[indexPath.row].1
        perform(selector!)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc private func gotoAVFoundation() {
        let vc = FSAVFoundationVC()
        vc.title = "AVFoundation Demo"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func gotoFFmpeg() {
        let vc = FSFFmpegVC()
        vc.title = "FFmpeg Demo"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func gotoOpenGL() {
        let vc = FSOpenGLVC()
        vc.title = "OpenGL Demo"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func gotoVideoPlay() {
        let path = Bundle.main.path(forResource: "test.flv", ofType: nil) ?? ""
        let vc = FSVideoPlayDemoVC.viewController(withContentPath: path, contentFrame: self.view.bounds, parameters: [:])
        navigationController?.pushViewController(vc as! UIViewController, animated: true)
    }
    
    @objc private func gotoPassKit() {
        let vc = FSPassKitVC()
        vc.title = "PassKit Demo"
        navigationController?.pushViewController(vc, animated: true)
    }
}

