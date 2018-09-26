//
//  AppDelegate.swift
//  Dynamic
//
//  Created by Apollo Zhu on 6/6/18.
//  Copyright © 2018 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import UserNotifications
import os.log
import ServiceManagement
#if canImport(LetsMove)
import LetsMove
#endif

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var statusBarItem = NSStatusBar.system
        .statusItem(withLength: NSStatusItem.squareLength)
    private var token: NSKeyValueObservation?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        #if canImport(LetsMove) && !DEBUG
        PFMoveToApplicationsFolderIfNecessary()
        #endif

        if #available(OSX 10.14, *) {
            UNUserNotificationCenter.current().delegate = Scheduler.shared
        } else {
            NSUserNotificationCenter.default.delegate = Scheduler.shared
        }

        // MARK: - Menu Bar Item Setup
        
        statusBarItem.button?.image = #imageLiteral(resourceName: "status_bar_icon")
        statusBarItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusBarItem.button?.action = #selector(handleEvent)
        token = preferences.observe(\.rawSettingsStyle, options: [.initial, .new])
        { [weak self] _, change in
            guard let self = self else { return }
            if change.newValue == 1 {
                self.statusBarItem.menu = self.buildMenu()
            } else {
                self.statusBarItem.menu = nil
            }
        }

        DispatchQueue.global(qos: .userInteractive).async(execute: setup)
        DispatchQueue.global(qos: .userInitiated).async(execute: setupTouchBar)
    }

    @objc private func handleEvent() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            SettingsViewController.show()
        } else {
            AppleInterfaceStyle.toggle()
        }
    }

    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        let toggleItem = NSMenuItem(
            title: NSLocalizedString(
                "Menu.toggle",
                value: "Toggle Dark Mode",
                comment: "Action item to toggle in from menu bar"),
            action: #selector(toggleInterfaceStyle),
            keyEquivalent: "\u{000d}" // return
        )
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        let preferencesItem = NSMenuItem(
            title: NSLocalizedString(
                "Menu.preferences",
                value: "Preferences…",
                comment: "Settings"),
            action: #selector(SettingsViewController.show),
            keyEquivalent: ","
        )
        preferencesItem.keyEquivalentModifierMask = .command
        preferencesItem.target = SettingsViewController.self
        menu.addItem(preferencesItem)
        let quitItem = NSMenuItem(
            title: NSLocalizedString(
                "Menu.quit",
                value: "Quit",
                comment: "Use system translation for quit"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "Q"
        )
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)
        return menu
    }

    // MARK: - Control Strip Setup

    private func setupTouchBar() {
        #if Masless
        #warning("TODO: Add option to disable displaying toggle button in Control Strip")
        DFRSystemModalShowsCloseBoxWhenFrontMost(false)
        let identifier = NSTouchBarItem.Identifier(rawValue: "io.github.apollozhu.Dynamic.switch")
        let item = NSCustomTouchBarItem(identifier: identifier)
        #warning("TODO: Redesign icon for toggle button")
        let button = NSButton(image: #imageLiteral(resourceName: "status_bar_icon"), target: self, action: #selector(toggleInterfaceStyle))
        item.view = button
        NSTouchBarItem.addSystemTrayItem(item)
        DFRElementSetControlStripPresenceForIdentifier(identifier, true)
        #endif
    }

    @objc private func toggleInterfaceStyle() {
        AppleInterfaceStyle.toggle()
    }

    // MARK: - Other Setup

    private func setup() {
        if preferences.hasLaunchedBefore {
            start()
        } else {
            Preferences.setup()
            DispatchQueue.main.async(execute: Welcome.show)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        token?.invalidate()
        Preferences.removeObservers()
        Scheduler.shared.cancel()
    }
}

func start() {
    DispatchQueue.main.async {
        Preferences.setupObservers()
        AppleScript.setupIfNeeded()
        _ = ScreenBrightnessObserver.shared
    }
}
