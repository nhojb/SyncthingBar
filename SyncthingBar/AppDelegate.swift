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
let SyncthingLaunchDefaultsKey = "LaunchAtStartup"
let SyncthingNotifyLaunchDefaultsKey = "LaunchNotifyAtStartup"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    @IBOutlet weak var statusMenu: NSMenu!

    @IBOutlet weak var connectedMenuItem: NSMenuItem!

    lazy var webViewWindowController : WebViewWindowController = WebViewWindowController(windowNibName:NSNib.Name("WebViewWindow"))

    lazy var preferencesWindowController : PreferencesWindowController = PreferencesWindowController(windowNibName:NSNib.Name("PreferencesWindow"))

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    var client : SyncthingClient?
    var syncthing : Process?
    var notify : Process?

    var connected : Bool = false {
        didSet {
            if connected {
                self.statusItem.image = NSImage(named: NSImage.Name("SyncthingEnabled"))!
                self.connectedMenuItem.title = "Connected - \(self.client!.url)"
            }
            else {
                self.statusItem.image = NSImage(named: NSImage.Name("SyncthingDisabled"))!
                self.connectedMenuItem.title = "Not Connected"
            }
        }
    }

    func registerDefaults() {
        UserDefaults.standard.register(defaults: [SyncthingURLDefaultsKey: "http://127.0.0.1:8384",
                                                  SyncthingLaunchDefaultsKey: true,
                                                  // syncthing-inotify is only required if not using syncthing's built-in file watcher.
                                                  // See https://docs.syncthing.net/users/syncing.html#scanning
                                                  SyncthingNotifyLaunchDefaultsKey: false])
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
        self.registerDefaults()

        self.copySyncthing()

        self.statusItem.menu = self.statusMenu
        self.statusItem.image = NSImage(named: NSImage.Name("SyncthingDisabled"))!

        self.updateClient()
        self.updateSyncthing()

        if self.client == nil {
            self.openPreferences(self)
        }

        NotificationCenter.default.addObserver(forName:UserDefaults.didChangeNotification,
                                               object:UserDefaults.standard,
                                               queue:nil) { [unowned self] (notification) in
            self.updateClient()
            self.updateSyncthing()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.notify?.terminate()
        self.syncthing?.terminate()
    }

    func updateClient() {
        guard let url = UserDefaults.standard.url(forKey:SyncthingURLDefaultsKey) else {
            return
        }

        // TODO: Store in keychain?
        guard let apiKey = UserDefaults.standard.object(forKey:SyncthingAPIKeyDefaultsKey) as? String else {
            return
        }

        self.client = SyncthingClient(url:url, apiKey:apiKey)

        self.client?.ping() { [unowned self] (ok, error) in
            self.connected = ok
        }
    }

    func updateSyncthing() {
        guard UserDefaults.standard.bool(forKey:SyncthingLaunchDefaultsKey) else {
            self.stopSyncthing()
            return
        }

        self.startSyncthing()

        if UserDefaults.standard.bool(forKey:SyncthingNotifyLaunchDefaultsKey) {
            self.startSyncthingNotify()
        } else {
            self.notify?.terminate()
        }
    }

    func startSyncthing() {
        guard self.syncthing == nil else {
            return
        }

        // syncthing -no-browser
        if Processes.find(processName:"syncthing") == nil {
            if let url = self.applicationSupportURLFor(binary:"syncthing") {
                self.syncthing = Process.launchedProcess(launchPath:url.path, arguments:["-no-browser"])
            }
        }
        else {
            print("syncthing already running!")
        }

        // Poll until the server is launched:
        self.client?.checkConnection(repeating:5) { [unowned self] (ok, error) in
            self.connected = ok
        }
    }

    func startSyncthingNotify() {
        guard self.notify == nil else {
            return
        }

        // syncthing-inotify
        if Processes.find(processName:"syncthing-inotify") == nil {
            if let url = self.applicationSupportURLFor(binary:"syncthing-inotify") {
                self.notify = Process.launchedProcess(launchPath:url.path, arguments:[])
            }
        }
        else {
            print("syncthing-inotify already running!")
        }

    }

    func stopSyncthing() {
        self.syncthing?.terminate()
        self.notify?.terminate()

        self.client?.ping() { [unowned self] (ok, error) in
            self.connected = ok
        }
    }

    @IBAction func openPreferences(_ sender: Any) {
        NSApplication.shared.activate(ignoringOtherApps: true)

        self.preferencesWindowController.showWindow(self)
    }

    @IBAction func openSyncthing(_ sender: Any) {
        // User UserDefaults url in case the API key has not yet been set (user can still connect via browser).
        if let url = UserDefaults.standard.url(forKey:SyncthingURLDefaultsKey) {
            NSApplication.shared.activate(ignoringOtherApps: true)

            self.webViewWindowController.showWindow(self)

            self.webViewWindowController.webView?.mainFrame.load(URLRequest(url:url))
        }
    }

    // NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        self.client?.ping() { [unowned self] (ok, error) in
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
