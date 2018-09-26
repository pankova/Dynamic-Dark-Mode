//
//  SettingsViewController.swift
//  Dynamic
//
//  Created by Apollo Zhu on 6/9/18.
//  Copyright © 2018 Dynamic Dark Mode. All rights reserved.
//

import Cocoa
import UserNotifications

extension NSStoryboard {
    static let main = NSStoryboard(name: "Main", bundle: nil)
}

class SettingsViewController: NSViewController {
    enum Style: Int {
        case rightClick
        case menu
    }
    private static weak var window: NSWindow? = nil
    @objc public static func show() {
        if window == nil {
            ValueTransformer.setValueTransformer(
                UsesCustomRange(), forName: .usesCustomRangeTransformerName
            )
            let windowController = NSStoryboard.main
                .instantiateController(withIdentifier: "window")
                as! NSWindowController
            windowController.showWindow(nil)
            window = windowController.window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    @IBAction func close(_ sender: Any) {
        SettingsViewController.window?.close()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // The following is required to attach touchbar to a view controller.
        // https://stackoverflow.com/questions/42342231/how-to-show-touch-bar-in-a-viewcontroller
        view.window?.unbind(NSBindingName(rawValue: #keyPath(touchBar)))
        view.window?.bind(NSBindingName(rawValue: #keyPath(touchBar)), to: self, withKeyPath: #keyPath(touchBar), options: nil)
        NSUserDefaultsController.shared.appliesImmediately = true
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        removeAllNotifications()
    }
}

class UsesCustomRange: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        return (value as? NSNumber)?.intValue == Zenith.custom.rawValue
    }
}

extension NSValueTransformerName {
    static let usesCustomRangeTransformerName
        = NSValueTransformerName(rawValue: "UsesCustomRange")
}

extension Preferences {    
    public static func setup() {
        preferences.adjustForBrightness = true
        preferences.brightnessThreshold = 0.5
        preferences.scheduleZenithType = .official
        preferences.scheduled = true
        preferences.opensAtLogin = true
        preferences.settingsStyle = .rightClick
    }
}
