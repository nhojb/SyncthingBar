//
//  AppDelegate.swift
//  SyncthingBar
//
//  Created by John on 11/11/2016.
//  Copyright © 2016 Olive Toast Software Ltd. All rights reserved.
//

import Cocoa

let kSyncthingURLDefaultsKey = "SyncthingURL"
let kSyncthingAPIKeyDefaultsKey = "SyncthingAPIKey"
let kSyncthingPathDefaultsKey = "SyncthingPath"
let kSyncthingLaunchDefaultsKey = "LaunchAtStartup"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    @IBOutlet weak var statusMenu: NSMenu!

    @IBOutlet weak var connectedMenuItem: NSMenuItem!

    var connected: Bool = false {
        didSet {
            if let client = self.client, connected {
                self.statusItem.image = NSImage(named: "SyncthingEnabled")
                self.connectedMenuItem.title = "Connected - \(client.url)"
            } else {
                self.statusItem.image = NSImage(named: "SyncthingDisabled")
                self.connectedMenuItem.title = "Not Connected"
            }
        }
    }

    private lazy var webViewWindowController: WebViewWindowController = WebViewWindowController(windowNibName: "WebViewWindow")

    private lazy var preferencesWindowController: PreferencesWindowController = PreferencesWindowController(windowNibName: "PreferencesWindow")

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    private var client: SyncthingClient?

    private var syncthing: Process?

    private var syncthingPath: String?

    private var launchSyncthing = true

    func registerDefaults() {
        UserDefaults.standard.register(defaults: [kSyncthingURLDefaultsKey: "http://127.0.0.1:8384",
                                                  kSyncthingPathDefaultsKey: "/usr/local/bin/syncthing",
                                                  kSyncthingLaunchDefaultsKey: true])
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.registerDefaults()

        self.statusItem.menu = self.statusMenu
        self.statusItem.image = NSImage(named: "SyncthingDisabled")

        self.launchSyncthing = UserDefaults.standard.bool(forKey: kSyncthingLaunchDefaultsKey)
        self.syncthingPath = UserDefaults.standard.string(forKey: kSyncthingPathDefaultsKey)

        self.updateClient()
        self.updateSyncthing()

        if self.client == nil {
            self.openPreferences(self)
        }

        _ = NotificationCenter.default.addObserver(forName: PreferencesWindowController.preferencesDidCloseNotification,
                                                   object: nil,
                                                   queue: nil) { [weak self] notification in
            self?.updateClient()
            self?.updateSyncthing()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.syncthing?.terminate()
    }

    func updateClient() {
        guard let url = UserDefaults.standard.url(forKey: kSyncthingURLDefaultsKey) else {
            return
        }

        // TODO: Store in keychain?
        guard let apiKey = UserDefaults.standard.object(forKey: kSyncthingAPIKeyDefaultsKey) as? String else {
            return
        }

        self.client = SyncthingClient(url: url, apiKey: apiKey)

        self.client?.ping { [weak self] ok, error in
            assert(Thread.isMainThread)
            self?.connected = ok
        }
    }

    func updateSyncthing() {
        let launchSyncthing = UserDefaults.standard.bool(forKey: kSyncthingLaunchDefaultsKey)
        let syncthingPath = UserDefaults.standard.string(forKey: kSyncthingPathDefaultsKey)

        if launchSyncthing != self.launchSyncthing || syncthingPath != self.syncthingPath {
            self.stopSyncthing()
        }

        self.launchSyncthing = launchSyncthing
        self.syncthingPath = syncthingPath

        if launchSyncthing {
            self.startSyncthing()
        }
    }

    func startSyncthing() {
        guard self.syncthing == nil else {
            return
        }

        guard let syncthingPath = self.syncthingPath else {
            return
        }

        // syncthing -no-browser
        if Processes.find(processName: "syncthing") == nil {
            self.syncthing = Process.launchedProcess(launchPath: syncthingPath, arguments: ["-no-browser"])
        } else {
            print("syncthing already running!")
        }

        // Poll until the server is launched:
        self.client?.checkConnection(repeating: 5) { [weak self] ok, error in
            assert(Thread.isMainThread)
            self?.connected = ok
        }
    }

    func stopSyncthing() {
        guard self.syncthing != nil else {
            return
        }

        self.syncthing?.terminate()
        self.syncthing?.waitUntilExit()
        self.syncthing = nil

        self.client?.ping { [weak self] ok, error in
            assert(Thread.isMainThread)
            self?.connected = ok
        }
    }

    @IBAction func openPreferences(_ sender: Any) {
        NSApplication.shared.activate(ignoringOtherApps: true)

        self.preferencesWindowController.showWindow(self)
    }

    @IBAction func openSyncthing(_ sender: Any) {
        // User UserDefaults url in case the API key has not yet been set (user can still connect via browser).
        if let url = UserDefaults.standard.url(forKey: kSyncthingURLDefaultsKey) {
            NSApplication.shared.activate(ignoringOtherApps: true)

            self.webViewWindowController.showWindow(self)

            self.webViewWindowController.webView?.mainFrame.load(URLRequest(url: url))
        }
    }

    // NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        self.client?.ping { [weak self] ok, error in
            assert(Thread.isMainThread)
            self?.connected = ok
        }
    }

}
