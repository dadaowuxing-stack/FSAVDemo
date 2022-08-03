//
//  FSDropdownListView.swift
//  FSAVDemo
//
//  Created by louis on 2022/8/3.
//

import UIKit

let kItemCellHeight: CGFloat = 45.0
let kArrowIconHeight = 10.0
let kArrowIconWidth = 15.0
let kTextLabelX = 5.0

class FSDropdownListView : UIView {
    var textColor: UIColor = .black {
        didSet {
            textLabel.textColor = textColor
        }
    }
    var font: UIFont = UIFont(name: "PingFangSC-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14) {
        didSet {
            textLabel.font = font
        }
    }
    var dataSource: [FSDropdownListItem] = [] {
        didSet {
            if dataSource.count > 0 {
                selectedItemAtIndex(index: selectedIndex)
            }
        }
    }
    var selectedIndex: Int = 0
    var selectedItem: FSDropdownListItem?
    var selectedBlock: ((FSDropdownListView) -> Void)?
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var arrowIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "dropdown"))
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    lazy var backgroundView: UIView = {
        let view = UIView(frame: UIScreen.main.bounds)
        return view
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: Int(CGFloat.leastNormalMagnitude)))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: Int(CGFloat.leastNormalMagnitude)))
        tableView.headerView(forSection: Int(CGFloat.leastNormalMagnitude))
        tableView.footerView(forSection: Int(CGFloat.leastNormalMagnitude))
        tableView.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = kItemCellHeight
        return tableView
    }()
    
    convenience init(dataSource: [FSDropdownListItem]) {
        self.init(frame: CGRect.zero)
        self.dataSource = dataSource
        selectedItemAtIndex(index: 0)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
        addGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let viewWidth = self.bounds.width
        let viewHeight = self.bounds.height
        textLabel.frame = CGRect(x: kTextLabelX, y: 0, width: viewWidth - kTextLabelX - kArrowIconWidth, height: viewHeight)
        arrowIcon.frame = CGRect(x: textLabel.frame.width, y: viewHeight / 2 - kArrowIconHeight / 2, width: kArrowIconWidth, height: kArrowIconHeight)
    }
    
    private func setupView() {
        addSubview(textLabel)
        addSubview(arrowIcon)
    }
    
    private func addGesture() {
        let tapLabel = UITapGestureRecognizer(target: self, action: #selector(tapViewExpand(sender:)))
        textLabel.addGestureRecognizer(tapLabel)
        let tapImageView = UITapGestureRecognizer(target: self, action: #selector(tapViewExpand(sender:)))
        arrowIcon.addGestureRecognizer(tapImageView)
    }
    
    private func selectedItemAtIndex(index: Int) {
        selectedIndex = index
        if index < dataSource.count {
            let item = dataSource[index]
            selectedItem = item
            textLabel.text = item.itemName
        }
    }
    
    private func removeBackgroundView() {
        rotateArrowImage()
        backgroundView.removeFromSuperview()
        tableView.removeFromSuperview()
    }
    
    private func rotateArrowImage() {
        arrowIcon.transform = arrowIcon.transform.rotated(by: CGFloat.pi)
    }
    
    @objc private func tapViewExpand(sender: UITapGestureRecognizer) {
        rotateArrowImage()
        
        let window = UIApplication.shared.windows.first{$0.isKeyWindow}
        window?.addSubview(backgroundView)
        window?.addSubview(tableView)
        
        let frame = convert(self.bounds, to: window)
        let tableViewY = frame.origin.y + frame.size.height
        let tableViewH = 6 * kItemCellHeight
        let tableViewFrame = CGRect(x: frame.origin.x, y: tableViewY, width: frame.size.width, height: tableViewH)
        
        tableView.frame = tableViewFrame
        
        let tapBackground = UITapGestureRecognizer(target: self, action: #selector(tapViewDismiss(sender:)))
        backgroundView.addGestureRecognizer(tapBackground)
    }
    
    @objc private func tapViewDismiss(sender: UITapGestureRecognizer) {
        removeBackgroundView()
    }
}

extension FSDropdownListView : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: tableCellIdentifier)
        let item = dataSource[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = item.itemName ?? ""
        content.textProperties.color = textColor
        content.textProperties.font = font
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        selectedItemAtIndex(index: indexPath.row)
        removeBackgroundView()
        selectedBlock?(self)
    }
}
