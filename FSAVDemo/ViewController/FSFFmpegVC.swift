//
//  FSFFmpegVC.swift
//  FSAVDemo
//
//  Created by louis on 2022/8/2.
//

import UIKit

class FSFFmpegVC : FSAVBaseVC {
    
    var listView: FSDropdownListView?
    
    var itemsForFFmpeg: [String] = [
        "audio capture 0",
        "audio resample 1",
        "audio encode 2",
        "audio muxer 3",
        "audio demuxer 4",
        "audio decode 5",
        "play pcm 6",
        "play wav 7",
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let barItem = UIBarButtonItem(title: "开始", style: .plain, target: self, action: #selector(start))
        
        var selectedItems: [FSDropdownListItem] = []
        for item in itemsForFFmpeg {
            let index = itemsForFFmpeg.firstIndex(of: item) ?? 0
            let selectedItem = FSDropdownListItem(itemId: String(index), itemName: item)
            selectedItems.append(selectedItem)
        }
        listView = FSDropdownListView(dataSource: selectedItems)
        guard let dropdownListView = listView else { return }
        dropdownListView.selectedIndex = 0
        dropdownListView.frame = CGRect(x: 20, y: 350, width: 320, height: 30)
        dropdownListView.layer.borderColor = UIColor.gray.cgColor
        dropdownListView.layer.cornerRadius = 2
        dropdownListView.layer.borderWidth = 0.5
        view.addSubview(dropdownListView)
    }
    
    @objc func start() {
        let index = listView?.selectedIndex
        switch index {
        case 0: 
            break
        default:
            break
        }
    }
}
