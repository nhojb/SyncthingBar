//
//  WebViewWindowController.swift
//  SyncthingBar
//
//  Created by John on 17/11/2016.
//  Copyright © 2016 Olive Toast Software Ltd. All rights reserved.
//

import Cocoa
import WebKit

class WebViewWindowController: NSWindowController, WKNavigationDelegate {

    @IBOutlet var webView: WKWebView?

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        print("\(self) title:", self.webView?.title ?? "nil")

        guard let title = self.webView?.title, !title.contains("unknown device") else {
            self.window?.title = "Syncthing"
            return
        }

        self.window?.title = title
    }

}
