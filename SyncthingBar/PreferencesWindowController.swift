//
//  PreferencesWindowController.swift
//  SyncthingBar
//
//  Created by John on 22/11/2016.
//  Copyright © 2016 Olive Toast Software Ltd. All rights reserved.
//

import Cocoa

class PreferencesWindowController : NSWindowController {

    @IBOutlet weak var urlTextField : NSTextField!

    @IBOutlet weak var apiKeyTextField : NSTextField!

    func windowWillClose(_ notification: Notification) {
        // Ensure we sync UserDefaults: bindings do not update when the window closes.
        UserDefaults.standard.set(self.urlTextField.stringValue, forKey:SyncthingURLDefaultsKey)
        UserDefaults.standard.set(self.apiKeyTextField.stringValue, forKey:SyncthingAPIKeyDefaultsKey)
    }
}
