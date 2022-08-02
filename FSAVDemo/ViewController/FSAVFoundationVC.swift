//
//  FSAVFoundationVC.swift
//  FSAVDemo
//
//  Created by louis on 2022/8/2.
//

import UIKit

let tableCellIdentifier = "tableCellIdentifier"

class FSAVFoundationVC: FSAVBaseVC {
    
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
        let audioItems = FSSectionItem(title: "Audio Demos", items: audioItems())
        let videoItems = FSSectionItem(title: "Video Demos", items: videoItems())
        
        dataSource = [audioItems, videoItems]
    }
    
    func setupUI() {
        view.addSubview(tableView)
    }
    
    func audioItems() -> [FSItem] {
        let capture = FSItem(title: "Audio Capture", subTitle: "音频采集", path: "FSAudioCaptureVC", opType: .audioCapture)
        let encoder = FSItem(title: "Audio Encoder", subTitle: "音频编码", path: "FSAudioEncoderVC", opType: .audioEncoder)
        let muxer = FSItem(title: "Audio Muxer", subTitle: "音频封装", path: "FSAudioMuxerVC", opType: .audioMuxer)
        let demuxer = FSItem(title: "Audio Demuxer", subTitle: "音频解封装", path: "FSAudioDemuxerVC", opType: .audioDemuxer)
        let decoder = FSItem(title: "Audio Decoder", subTitle: "音频解码", path: "FSAudioDecoderVC", opType: .audioDecoder)
        let render = FSItem(title: "Audio Render", subTitle: "音频渲染", path: "FSAudioRenderVC", opType: .audioRender)
        
        return [capture, encoder, muxer, demuxer, decoder, render]
    }
    
    func videoItems() -> [FSItem] {
        let capture = FSItem(title: "Video Capture", subTitle: "视频采集", path: "FSVideoCaptureVC", opType: .videoCapture)
        let encoder = FSItem(title: "Video Encoder", subTitle: "视频编码", path: "FSVideoEncoderVC", opType: .videoEncoder)
        let muxer = FSItem(title: "Video Muxer", subTitle: "视频采集", path: "FSVideoMuxerVC", opType: .videoMuxer)
        let demuxer = FSItem(title: "Video Demuxer", subTitle: "视频编码", path: "FSVideoDemuxerVC", opType: .videoDemuxer)
        let avDemuxer = FSItem(title: "AV Demuxer", subTitle: "视频采集", path: "FSAVDemuxerVC", opType: .avDemuxer)
        let decoder = FSItem(title: "Video Decoder", subTitle: "视频编码", path: "FSVideoDecoderVC", opType: .videoDecoder)
        let render = FSItem(title: "Video Render", subTitle: "视频采集", path: "FSVideoRenderVC", opType: .videoRender)
        
        return [capture, encoder, muxer, demuxer, avDemuxer, decoder, render]
    }
}

extension FSAVFoundationVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionItem = dataSource[section]
        return sectionItem.items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: tableCellIdentifier)
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
            let aClass = NSClassFromString(name) as! FSBaseVC.Type
            let vc = aClass.init()
            vc.title = item.title
            vc.opType = item.opType
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
