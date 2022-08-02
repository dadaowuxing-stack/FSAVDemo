//
//  FSAVBaseVC.swift
//  FSAVDemo
//
//  Created by louis on 2022/8/2.
//

import UIKit

class FSAVBaseVC : UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = UIRectEdge.all
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = UIColor.white;
    }
    
}
