//
//  FSOpenGLVC.swift
//  FSAVDemo
//
//  Created by louis on 2022/10/8.
//

import UIKit

let openGLTableCellIdentifier = "openGLTableCellIdentifier"

class FSOpenGLVC: FSAVBaseVC {
    
    var dataSource: [FSSectionItem] = []
    
    lazy var tableView: UITableView = {
        let tableView: UITableView = UITableView(frame: view.bounds, style: .grouped)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 50
        
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        
        
        return tableView;
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configData()
        setupUI()
    }
    
    func configData() {
        let openGLItems = FSSectionItem(title: "OpenGL Render Demos", items: openGLItems())
        
        dataSource = [openGLItems]
    }
    
    func setupUI() {
        view.addSubview(tableView)
    }
    
    func openGLItems() -> [FSItem] {
        let triangleRender = FSItem(title: "OpenGL Render", subTitle: "1-图形渲染", path: "FSOpenGLTriangleRenderVC", opType: .openGLTriangleRender)
        let videoRender = FSItem(title: "OpenGL Video Render", subTitle: "2-视频渲染", path: "FSOpenGLVideoRenderVC", opType: .openGLVideoRender)
        let gaussianBlur = FSItem(title: "Gaussian Blur", subTitle: "3-高斯模糊", path: "FSGaussianBlurVC", opType: .openGLGaussianBlur)
        
        return [triangleRender, videoRender, gaussianBlur]
    }
}

extension FSOpenGLVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionItem = dataSource[section]
        return sectionItem.items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: openGLTableCellIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: openGLTableCellIdentifier)
        let sectionItem = dataSource[indexPath.section]
        var content = cell.defaultContentConfiguration()
        if let items = sectionItem.items {
            let item = items[indexPath.row]
            content.text = item.title
            content.secondaryText = item.subTitle
        }
        
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionItem = dataSource[section]
        return sectionItem.title
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sectionItem = dataSource[indexPath.section]
        if let items = sectionItem.items {
            let item = items[indexPath.row]
            guard let name = item.path else { return }
            let aClass = NSClassFromString(name) as? FSBaseVC.Type
            guard let vc = aClass?.init() else {
                return
            }
            vc.title = item.title
            vc.opType = item.opType
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
