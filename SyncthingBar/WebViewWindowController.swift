//
//  WebViewWindowController.swift
//  SyncthingBar
//
//  Created by John on 17/11/2016.
//  Copyright © 2016 Olive Toast Software Ltd. All rights reserved.
//

import Cocoa
import WebKit

class WebViewWindowController : NSWindowController, WebResourceLoadDelegate {
    @IBOutlet var webView : WebView?

    // NSResponder
    override func keyDown(with event: NSEvent) {
        if !self.performKeyEquivalent(with: event) {
            super.keyDown(with: event)
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Filter out device independent flags so we can check for .command only.
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command else {
            return false
        }

        guard let chars = event.charactersIgnoringModifiers else {
            return false
        }

        switch chars {
        case "q":
            NSApplication.shared().terminate(self)
            return true
        case "w":
            self.window?.performClose(self)
            return true
        case "m":
            self.window?.miniaturize(self)
            return true
        default:
            return false
        }
    }

    // WebResourceLoadDelegate
    func webView(_ sender: WebView!, resource identifier: Any!, didFinishLoadingFrom dataSource: WebDataSource!) {
        if let pageTitle = dataSource.pageTitle {
            if !pageTitle.contains("unknown device") {
                self.window?.title = pageTitle
            }
        }
    }
}
