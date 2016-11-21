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

    var connected : Bool = false {
        didSet {
            if connected {
                self.statusItem.image = NSImage(named: "SyncthingEnabled")!
                self.connectedMenuItem.title = "Connected - \(self.client!.url)"
            }
            else {
                self.statusItem.image = NSImage(named: "SyncthingDisabled")!
                self.connectedMenuItem.title = "Not Connected"
            }
        }
    }

    func registerDefaults() {
        UserDefaults.standard.register(defaults: [SyncthingURLDefaultsKey: "http://127.0.0.1:8384"])
    }

    func applicationSupportURLFor(binary name: String) -> URL? {
        if var syncthingBarUrl = try? FileManager.default.url(for:.applicationSupportDirectory,
                                                              in:.userDomainMask,
                                                              appropriateFor:nil,
                                                              create:false) {
            // The isDirectory:true is important - otherwise appending file names will fail.
            syncthingBarUrl.appendPathComponent("SyncthingBar", isDirectory:true)
            return URL(string:name, relativeTo:syncthingBarUrl)
        }
        return nil
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("applicationDidFinishLaunching")

        self.registerDefaults()

        self.copySyncthing()

        // TMP
        //UserDefaults.standard.set("Aw0vS4JkRkID0qOe3hug7dvoBgRtmhPR", forKey:SyncthingAPIKeyDefaultsKey)
        UserDefaults.standard.set("eg0yTcbb8KnpQMvDXOP60xPwgyq-KczN", forKey:SyncthingAPIKeyDefaultsKey)
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
        print("applicationWillTerminate")
        self.notify?.terminate()
        self.syncthing?.terminate()
    }

    func startSyncthing() {
        print("startSyncthing")
        // syncthing -no-browser
        // syncthing-inotify

        if self.syncthing == nil && Processes.find(processName:"syncthing") == nil {
            if let url = self.applicationSupportURLFor(binary:"syncthing") {
                print("Launching: \(url)")
                self.syncthing = Process.launchedProcess(launchPath:url.path, arguments:["-no-browser"])
            }
        }
        else {
            print("syncthing already running!")
        }

        if self.notify == nil && Processes.find(processName:"syncthing-inotify") == nil {
            if let url = self.applicationSupportURLFor(binary:"syncthing-inotify") {
                print("Launching: \(url)")
                self.notify = Process.launchedProcess(launchPath:url.path, arguments:[])
            }
        }
        else {
            print("syncthing-inotify already running!")
        }

        print("self.syncthing: \(self.syncthing)")
        print("self.notify: \(self.notify)")

        // Poll until the server is launched:
        self.client?.checkConnection(repeating:5) { (ok, error) in
            print("connect: \(ok)")
            self.connected = ok
        }
    }

    func stopSyncthing() {
        self.syncthing?.terminate()
        self.notify?.terminate()
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
        self.client?.ping() { (ok, error) in
            self.connected = ok
        }
    }

    func copySyncthing() {
        let fileManager = FileManager.default

        func copyBinary(_ name: String) -> Bool {
            guard let src = Bundle.main.url(forResource:name , withExtension: nil) else {
                return false
            }

            guard let dst = self.applicationSupportURLFor(binary:name) else {
                return false
            }

            // If dst exists, check if it is older:
            let srcAttrs = try! fileManager.attributesOfItem(atPath: src.path)
            let dstAttrs = try? fileManager.attributesOfItem(atPath: dst.path)

            if let dstAttrs = dstAttrs {
                if dstAttrs[.modificationDate] as! Date >= srcAttrs[.modificationDate] as! Date {
                    print("copySyncthing: \(name) already up-to-date")
                    return true
                }

                // else remove the older binary
                do {
                    try fileManager.removeItem(at:dst)
                }
                catch {
                    return false
                }
            }

            do {
                print("copySyncthing: copying \(name)")
                try fileManager.copyItem(at:src, to:dst)
                return true
            }
            catch {
                return false
            }
        }

        do {
            var syncthingBarUrl = try fileManager.url(for:.applicationSupportDirectory,
                                                      in:.userDomainMask,
                                                      appropriateFor:nil,
                                                      create:false)

            // The isDirectory:true is important - otherwise appending file names will fail.
            syncthingBarUrl.appendPathComponent("SyncthingBar", isDirectory:true)

            // withIntermediateDirectories: true will ensure createDirectory succeeds, even if syncthingBarUrl already exists
            try fileManager.createDirectory(at: syncthingBarUrl, withIntermediateDirectories: true)

            if !copyBinary("syncthing") {
                print("Warning, copy syncthing failed!")
            }

            if !copyBinary("syncthing-inotify") {
                print("Warning, copy syncthing-inotify failed")
            }
        }
        catch {
            print("Warning, copySyncthing failed")
        }
    }
}
