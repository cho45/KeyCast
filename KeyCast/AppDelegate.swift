//
//  AppDelegate.swift
//  KeyCast
//
//  Copyright (c) 2015年 cho45. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSFontChanging {
    let statusItem = NSStatusBar.system.statusItem(withLength: -1)
    var enabled: Bool = true {
        didSet {
            menuEnabled.state = NSControl.StateValue(rawValue: enabled ? 1 : 0)
            updateMenuTitle()
            toast.toast(str: enabled ? "KeyCast is enabled" : "KeyCast is disabled")
        }
    }
    var window: NSWindow! = nil
    var view: MainView! = nil
    var prevKeyed: NSDate = NSDate()

    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var menuEnabled: NSMenuItem!
    @IBOutlet weak var preferences: PreferencesWindow!
    @IBOutlet weak var toast: ToastWindow!
    @IBOutlet weak var about: AboutWindow!
    
    @objc func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        Accessibility.checkAccessibilityEnabled(app: self)

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { (e: NSEvent!) in
            if let (hotkey, hotkeyflags) = self.preferences.hotkey {
                // println("mod")
                // println(String(e.modifierFlags.rawValue & NSEventModifierFlags.DeviceIndependentModifierFlagsMask.rawValue, radix: 2))
                // println(String(hotkeyflags.rawValue, radix: 2))
                let sameKeyCode = e.keyCode == hotkey
                let sameModifiers = (e.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == hotkeyflags.rawValue
                if sameKeyCode && sameModifiers {
                    self.toggleState(sender: nil)
                }
            }
            
            if !self.canShowInput() {
                return
            }
            if e.type != .keyDown {
                return
            }
            // println(e)
            
            
            for c in e.charactersIgnoringModifiers!.uppercased().unicodeScalars {
                print(NSString(format: "%08X", c.value));
            }
            
            let (mod, char) = Utils.keyStringFromEvent(e: e)

            if mod.isEmpty {
                let interval = NSDate().timeIntervalSince(self.prevKeyed as Date)
                if interval > 1 {
                    self.view.appendLog(str: "\n" + char)
                } else {
                    self.view.appendLog(str: char)
                }
            } else {
                self.view.appendLog(str: "\n" + mod + char + " ")

            }
            
            self.prevKeyed = NSDate()
        }
        
        let rect = NSRect(x: 0, y: 0, width: 800, height: 500)
        window = NSWindow(contentRect: rect, styleMask: .borderless, backing: NSWindow.BackingStoreType.buffered, defer: false)
        window.isOpaque = false
        window.hasShadow = false
        window.level = NSWindow.Level(rawValue: 1000)
        window.isMovableByWindowBackground = true
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        
        view = MainView(frame: rect)
        view.font = preferences.font
        
        window.contentView = view
        
        statusItem.menu = menu
        // statusItem.image = NSImage(named: "icon-menu")
        statusItem.highlightMode = true
        updateMenuTitle()
        
        view.appendLog(str: "KeyCast Initialized\nYou can drag this to the position you want")
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange(aNotification:)),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
        userDefaultsDidChange(aNotification: nil)
        
        
        /*
        let callback: AXObserverCallback = (AXObserver!, AXUIElement!, CFString!, UnsafeMutablePointer<Void>) -> Void) {
            
        }
        var observer: Unmanaged<AXObserver>?
        AXObserverCreate(NSProcessInfo.processInfo().processIdentifier, callback, &observer)
        AXObserverAddNotification(observer, AXUIElementCreateSystemWide().takeRetainedValue(), NSAccessibilityFocusedUIElementChangedNotification, &0)
*/
        
        enableGlobalAccessibilityFeatures()
        toast.toast(str: "Initialized")
    }
    
    // VoiceOver が起動していない限りアクセシビリティオブジェクトを作らない一部アプリケーション用 (eg. Google Chrome) に
    // VoiceOver がセットする属性をセットする。VoiceOver 判定のため自プロセスには設定しない
    func enableGlobalAccessibilityFeatures() {
        print("enableGlobalAccessibilityFeatures")
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(enableAccessibilityForNewApplication(aNotification:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        
        var ptr: CFTypeRef?
        let pid = ProcessInfo.processInfo.processIdentifier
        for application in NSWorkspace.shared.runningApplications {
            if application.processIdentifier == pid {
                continue
            }
            let app = AXUIElementCreateApplication(application.processIdentifier)
            print("enableGlobalAccessibilityFeatures: \(app)")
            AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface" as CFString, &ptr)
            AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, 1 as CFTypeRef)
        }
    }
    
    // callback
    @objc func enableAccessibilityForNewApplication(aNotification: NSNotification) {
        let pid = aNotification.userInfo!["NSApplicationProcessIdentifier"] as! Int
        
        var ptr: CFTypeRef?
        let app = AXUIElementCreateApplication(Int32(pid))
        print("NSWorkspaceWillLaunchApplicationNotification")
        print(app)
        
        AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface" as CFString, &ptr)
        AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, 1 as CFTypeRef)
    }
    
    func disableGlobalAccessibilityFeatures() {
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.willLaunchApplicationNotification, object: nil)
        
        if isVoiceOverRunning() {
            return
        }
        
        var ptr: CFTypeRef?
        let pid = ProcessInfo.processInfo.processIdentifier
        for application in NSWorkspace.shared.runningApplications {
            if application.processIdentifier == pid {
                continue
            }
            let app = AXUIElementCreateApplication(application.processIdentifier)
            print(app)
            
            AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface" as CFString, &ptr)
            AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, 0 as CFTypeRef)
        }
    }
    
    // 完全に起動したあとでなければ常に false を返す
    func isVoiceOverRunning()->Bool {
        var ptr: CFTypeRef?
        let pid = ProcessInfo.processInfo.processIdentifier
        let app = AXUIElementCreateApplication(pid)
        AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface" as CFString, &ptr)
        if let running = ptr as? Int {
            if running == 1 {
                return true
            }
        }
        return false
    }
    
    @objc func userDefaultsDidChange(aNotification: NSNotification!) {
        window.alphaValue = CGFloat(preferences.opacity) / 100.0
        self.resize(width: preferences.width, height: preferences.height)
        view.shadowCount = preferences.shadow
        view.maxLine = preferences.lines
        view.needsDisplay = true
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        disableGlobalAccessibilityFeatures()
    }
    
    func resize (width: Int, height: Int) {
        let current = window.frame
        let rect = NSRect(x: Int(current.minX), y: Int(current.minY), width: width, height: height)
        window.setFrame(rect, display: true)
        view.setFrameSize(NSSize(width: rect.width, height: rect.height))
    }

    func updateMenuTitle() {
        statusItem.title = (enabled ? "\u{2713} " : "  ") + NSRunningApplication.current.localizedName!
    }
    
    func canShowInput()-> Bool {
        return enabled && canShowInputByRunningProcesses() && canShowInputByFocusedUIElement()
    }
    
    func canShowInputByRunningProcesses()->Bool {
        if !preferences.hideSudoInProcessList {
            return true
        }
        
        // sudo 実行中は入力を表示しない
        return !IsInBSDProcessList("sudo")
    }
    
    func canShowInputByFocusedUIElement()->Bool {
        if !preferences.hideNativePasswordInput {
            return true
        }
        
        var ptr: CFTypeRef?
        
        let system = AXUIElementCreateSystemWide()
        
        AXUIElementCopyAttributeValue(system, "AXFocusedApplication" as CFString, &ptr)
        if ptr == nil {
            return true
        }
        let focusedApp = ptr as! AXUIElement
        
        var pid: pid_t = 0
        AXUIElementGetPid(focusedApp, &pid)
        
        let bundleId_ = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
        if bundleId_ == nil {
            return true
        }
        _ = bundleId_!
        
        
        AXUIElementCopyAttributeValue(focusedApp, NSAccessibility.Attribute.focusedUIElement as CFString, &ptr)
        if ptr == nil {
            return true
        }
        let ui = ptr as! AXUIElement
        
        
        /*
        let target = focusedApp
        var arrayPtr: Unmanaged<CFArray>?
        AXUIElementCopyAttributeNames(target, &arrayPtr)
        if let array = arrayPtr?.takeRetainedValue() {
            for var i = 0, len = CFArrayGetCount(array); i < len; i++ {
                let name = unsafeBitCast(CFArrayGetValueAtIndex(array, i), CFString.self)
                AXUIElementCopyAttributeValue(target, name, &ptr)
                let value = ptr?.takeRetainedValue()
                if value != nil {
                    println(name)
                    println(value)
                    println("")
                }
            }
        }
        */
        
        /*
        if bundleId == "com.apple.Terminal" {
            AXUIElementCopyAttributeValue(ui, "AXValue", &ptr)
            if ptr != nil {
                let value = ptr!.takeRetainedValue() as String
                
                // Terminal.app で sudo っぽいことが起きていたらタイプを表示しない
                // (screen の中だと意味がない) sudo のラッパを書いたほうがいいかも
                let re = NSRegularExpression(pattern: "Password:\\s*$", options: .CaseInsensitive, error: nil)!
                let matches = re.matchesInString(value, options: nil, range: NSMakeRange(0, countElements(value)))
                if matches.count > 0 {
                    return false
                }
            }
        }
        */
        
        AXUIElementCopyAttributeValue(ui, "AXSubrole" as CFString, &ptr)
        if ptr != nil {
            let value = ptr as! String
            if value == "AXSecureTextField" {
                return false
            }
        }
        
        // NSAccessibilityFocusedUIElementChangedNotification
        return true
    }
    
    
    @IBAction func toggleState(sender: AnyObject!) {
        enabled = !enabled
    }
    
    @IBAction func clearLog(sender: AnyObject) {
        view.clear()
    }
    
    @IBAction func openPreferencesWindow(sender: AnyObject) {
        preferences.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction @objc func chooseFont(sender: AnyObject) {
        let fontManager = NSFontManager.shared
        fontManager.target = self
        fontManager.delegate = self
        fontManager.setSelectedFont(preferences.font, isMultiple: false)
        
        let fontPanel = fontManager.fontPanel(true)
        fontPanel?.makeKeyAndOrderFront(sender)
    }
    
    @objc func changeFont(sender: AnyObject?) {
        let fontManager = sender! as! NSFontManager
        print("changeFont")
        print(fontManager)
        preferences.font = fontManager.convert(preferences.font)
        view.needsDisplay = true
        print(preferences.font.fontName)
        print(preferences.font.pointSize)
        
        preferences.updateFontInfo(f: preferences.font)
        view.font = preferences.font
    }
    
    /* wait for Xcode 6.3...
    func processList() {
        // https://developer.apple.com/legacy/library/qa/qa2001/qa1123.html
        
        var err : Int32
        var nullpo = UnsafeMutablePointer<Void>.null()
        
        var names: [Int32] = [ CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 ]
        var length: UInt = 0
        var namelen: u_int = u_int(names.count)
        err = sysctl(&names, namelen, nullpo, &length, nullpo, 0)
        if (err == -1) {
            println("error")
            return
        }
        println(length)
        
        var result = UnsafeMutablePointer<kinfo_proc>.alloc(Int(length))
        err = sysctl(&names, namelen, result, &length, nullpo, 0)
        if (err == -1) {
            println("error")
            return
        }
        
        println(result)
   rkkkgg}
    */
    
    // osascript -e 'tell application "KeyCast"' -e 'set enabled to true' -e 'end tell'
    // osascript -e 'tell application "KeyCast"' -e 'set enabled to false' -e 'end tell'
    func application(_ sender: NSApplication, delegateHandlesKey key: String) -> Bool {
        if key == "enabled" {
            return true
        }
        return false
    }
    
    @IBAction func showAbout(sender: AnyObject) {
        about.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

