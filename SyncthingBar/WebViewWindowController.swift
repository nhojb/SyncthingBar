//
//  WebViewWindowController.swift
//  SyncthingBar
//
//  Created by John on 17/11/2016.
//  Copyright © 2016 Olive Toast Software Ltd. All rights reserved.
//

import Cocoa
import WebKit

class WebViewWindowController: NSWindowController, WebResourceLoadDelegate {
    @IBOutlet var webView: WebView?

    // WebResourceLoadDelegate
    func webView(_ sender: WebView!, resource identifier: Any!, didFinishLoadingFrom dataSource: WebDataSource!) {
        if let pageTitle = dataSource.pageTitle {
            if !pageTitle.contains("unknown device") {
                self.window?.title = pageTitle
            }
        }
    }
}
