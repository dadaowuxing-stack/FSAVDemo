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
        "pcm to wav 7",
        "play wav 8",
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let startBarItem = UIBarButtonItem(title: "开始", style: .plain, target: self, action: #selector(start))
        let stopBarItem = UIBarButtonItem(title: "结束", style: .plain, target: self, action: #selector(stop))
        navigationItem.rightBarButtonItems = [stopBarItem, startBarItem]
        
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
        
        let path = FSFileManager.documentsDirectory()
        
        let index = listView?.selectedIndex
        switch index {
        case 0: // 音频采集
            let queue = DispatchQueue.global()
            queue.async {
                FSBridgeFFmpeg.doRecord()
            }
            break
        case 1: // 音频重采样
            let srcpath = Bundle.main.path(forResource: "44100_s16le_2.pcm", ofType: nil) ?? ""
            let dstpath = path.appending("/48000_f32le_1.pcm")
            let isSuccess = FSFileManager.createFile(atPath: dstpath)
            if (isSuccess) {
                let queue = DispatchQueue.global()
                queue.async {
                    FSBridgeFFmpeg.doResample(srcpath, dst: dstpath);
                }
            }
            break
        case 2: // 音频编码(pcm -> aac)
            let queue = DispatchQueue.global()
            queue.async {
                FSBridgeFFmpeg.doPcm2AAC()
            }
            break
        case 3: // 音频封装
            
            break
        case 4: // 音频解封装
            
            break
        case 5: // 音频解码
            
            break
        case 6: // pcm 播放
            let queue = DispatchQueue.global()
            queue.async {
                FSBridgeFFmpeg.doPlayPcm()
            }
            break
        case 7: // pcm to wav
            let queue = DispatchQueue.global()
            queue.async {
                FSBridgeFFmpeg.doPcm2Wav()
            }
            break
        case 8: // wav 播放
            
            break
        default:
            break
        }
    }
    @objc func stop() {
        FSBridgeFFmpeg.testLib();
        let index = listView?.selectedIndex
        switch index {
        case 0: // 音频采集
            
            break
        case 1: // 音频重采样
            
            break
        case 2: // 音频编码(pcm -> aac)
            
            break
        case 3: // 音频封装
            
            break
        case 4: // 音频解封装
            
            break
        case 5: // 音频解码
            
            break
        case 6: // pcm 播放
            
            break
        case 7: // pcm to wav
            
            break
        case 8: // wav 播放
            
            break
        default:
            break
        }
    }
}
