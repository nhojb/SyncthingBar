//
//  PreferencesWindowController.swift
//  SyncthingBar
//
//  Created by John on 22/11/2016.
//  Copyright © 2016 Olive Toast Software Ltd. All rights reserved.
//

import Cocoa

extension PreferencesWindowController {

    static let preferencesDidCloseNotification = Notification.Name("PreferencesDidCloseNotification")

}

class PreferencesWindowController: NSWindowController {

    @IBOutlet weak var urlTextField: NSTextField!

    @IBOutlet weak var apiKeyTextField: NSTextField!

    @IBOutlet weak var syncthingPathTextField: NSTextField!

    @objc
    func windowWillClose(_ notification: Notification) {
        // Ensure we sync UserDefaults: bindings do not update when the window closes.
        UserDefaults.standard.set(self.urlTextField.stringValue, forKey: kSyncthingURLDefaultsKey)
        UserDefaults.standard.set(self.apiKeyTextField.stringValue, forKey: kSyncthingAPIKeyDefaultsKey)
        UserDefaults.standard.set(self.syncthingPathTextField.stringValue, forKey: kSyncthingPathDefaultsKey)

        NotificationCenter.default.post(name: Self.preferencesDidCloseNotification, object: self)
    }

    @IBAction func chooseSyncthingPath(_ sender: Any?) {
        guard let window = self.window else {
            return
        }

        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.resolvesAliases = false
        openPanel.title = "Choose syncthing path"
        openPanel.prompt = "Choose"

        if let path = UserDefaults.standard.string(forKey: kSyncthingPathDefaultsKey) {
            openPanel.directoryURL = URL(fileURLWithPath: path).deletingLastPathComponent()
        }

        openPanel.beginSheetModal(for: window) { response in
            guard response == .OK,
                  let url = openPanel.urls.first else {
                return
            }

            UserDefaults.standard.set(url.path, forKey: kSyncthingPathDefaultsKey)
        }
    }

}
