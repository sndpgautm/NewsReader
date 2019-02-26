//
//  NewsDetailViewController.swift
//  NewsReaderLAB12
//
//  Created by iosdev on 25/02/2019.
//  Copyright © 2019 san. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class NewsDetailViewController: UIViewController {
    
    //MARK: Properties
    @IBOutlet weak var newsWebView: WKWebView!
    var newsDetailURL: String?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Making the size of nav bar small for this view
        navigationItem.largeTitleDisplayMode = .never
        // Loading the news web view
        let url = URL(string: newsDetailURL!)
        let request = URLRequest(url: url!)
        newsWebView.load(request)
    }
    
    
}
