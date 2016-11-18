//
//  AppDelegate.swift
//  SyncthingBar
//
//  Created by John on 11/11/2016.
//  Copyright © 2016 Olive Toast Software Ltd. All rights reserved.
//

import Cocoa

let SyncthingURLDefaultsKey = "SyncthingURL"
let SyncthingAPIKeyDefaultsKey = "SyncthingAPIKey"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    @IBOutlet weak var statusMenu: NSMenu!

    @IBOutlet weak var connectedMenuItem: NSMenuItem!

    lazy var webViewWindowController : WebViewWindowController = WebViewWindowController(windowNibName:"WebView")

    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)

    var client : SyncthingClient?
    var syncthing : Process?
    var notify : Process?

    func registerDefaults() {
        UserDefaults.standard.register(defaults: [SyncthingURLDefaultsKey: "http://127.0.0.1:8384"])
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("applicationDidFinishLaunching")

        self.registerDefaults()

        // TMP
        UserDefaults.standard.set("Aw0vS4JkRkID0qOe3hug7dvoBgRtmhPR", forKey:SyncthingAPIKeyDefaultsKey)
        //UserDefaults.standard.set("eg0yTcbb8KnpQMvDXOP60xPwgyq-KczN", forKey:SyncthingAPIKeyDefaultsKey)
        // TMP

        self.statusItem.menu = self.statusMenu
        self.statusItem.image = NSImage(named: "SyncthingDisabled")!

        guard let urlString = UserDefaults.standard.object(forKey:SyncthingURLDefaultsKey) as? String else {
            self.openPreferences(self)
            return
        }

        // TODO: Store in keychain?
        guard let apiKey = UserDefaults.standard.object(forKey:SyncthingAPIKeyDefaultsKey) as? String else {
            self.openPreferences(self)
            return
        }

        if let url = URL(string:urlString) {
            self.client = SyncthingClient(url:url, apiKey:apiKey)
        }

        if self.client != nil {
            // Start syncthing process
            self.startSyncthing()
        }
        else {
            self.openPreferences(self)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application

        // TODO: Kill processes...
    }

    func startSyncthing() {
        print("startSyncthing")
        // TODO
        // syncthing -no-browser
        // syncthing-inotify

        self.client?.ping() { (ok, error) in
            print("ping: \(ok)")
            if ok {
                self.statusItem.image = NSImage(named: "SyncthingEnabled")!
            }
            else {
                self.statusItem.image = NSImage(named: "SyncthingDisabled")!
            }
        }
    }

    func stopSyncthing() {


    }

    @IBAction func openPreferences(_ sender: Any) {

    }

    @IBAction func openSyncthing(_ sender: Any) {
        NSApplication.shared().activate(ignoringOtherApps: true)

        self.webViewWindowController.showWindow(self)

        if let url = self.client?.url {
            self.webViewWindowController.webView?.mainFrame.load(URLRequest(url:url))
        }
    }

    // NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        self.client?.fetchEvent(lastId:0, limit:1) { (info, error) in
            print("fetchEvent: \(info), \(error)")

            if error != nil {
                self.connectedMenuItem.title = "Not Connected"
            }
            else {
                self.connectedMenuItem.title = "Connected - \(self.client!.url)"
            }
        }
    }
}
