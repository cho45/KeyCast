//
//  AppDelegate.swift
//  KeyCast
//
//  Copyright (c) 2015年 cho45. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system().statusItem(withLength: -1)
    var enabled: Bool = true {
        didSet {
            menuEnabled.state = enabled ? 1 : 0
            updateMenuTitle()
            toast.toast(enabled ? "KeyCast is enabled" : "KeyCast is disabled")
        }
    }
    var window: NSWindow! = nil
    var view: MainView! = nil
    var prevKeyed: Date = Date()

    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var menuEnabled: NSMenuItem!
    @IBOutlet weak var preferences: PreferencesWindow!
    @IBOutlet weak var toast: ToastWindow!
    @IBOutlet weak var about: AboutWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        Accessibility.checkAccessibilityEnabled(self)
        print("launch")

        NSEvent.addGlobalMonitorForEvents(matching: NSEventMask.keyDown) { (e: NSEvent!) in
            if let (hotkey, hotkeyflags) = self.preferences.hotkey {
                // println("mod")
                // println(String(e.modifierFlags.rawValue & NSEventModifierFlags.DeviceIndependentModifierFlagsMask.rawValue, radix: 2))
                // println(String(hotkeyflags.rawValue, radix: 2))
                let sameKeyCode = e.keyCode == hotkey
                let sameModifiers = (e.modifierFlags.rawValue & NSEventModifierFlags.deviceIndependentFlagsMask.rawValue) == hotkeyflags.rawValue
                if sameKeyCode && sameModifiers {
                    self.toggleState(nil)
                }
            }
            
            if !self.canShowInput() {
                return
            }
            if e.type != NSEventType.keyDown {
                return
            }
            // println(e)
            
            
            for c in e.charactersIgnoringModifiers!.uppercased().unicodeScalars {
                print(NSString(format: "%08X", c.value));
            }
            
            let (mod, char) = Utils.keyStringFromEvent(e)

            if mod.isEmpty {
                let interval = Date().timeIntervalSince(self.prevKeyed)
                if interval > 1 {
                    self.view.appendLog("\n" + char)
                } else {
                    self.view.appendLog(char)
                }
            } else {
                self.view.appendLog("\n" + mod + char + " ")

            }
            
            self.prevKeyed = Date()
        }
        
        let rect = NSRect(x: 0, y: 0, width: 800, height: 500)
        window = NSWindow(contentRect: rect, styleMask: NSBorderlessWindowMask, backing: NSBackingStoreType.buffered, defer: false)
        window.isOpaque = false
        window.hasShadow = false
        window.level = 1000
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
        
        view.appendLog("KeyCast Initialized\nYou can drag this to the position you want")
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AppDelegate.userDefaultsDidChange(_:)),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
        userDefaultsDidChange(nil)
        
        
        /*
        let callback: AXObserverCallback = (AXObserver!, AXUIElement!, CFString!, UnsafeMutablePointer<Void>) -> Void) {
            
        }
        var observer: Unmanaged<AXObserver>?
        AXObserverCreate(NSProcessInfo.processInfo().processIdentifier, callback, &observer)
        AXObserverAddNotification(observer, AXUIElementCreateSystemWide().takeRetainedValue(), NSAccessibilityFocusedUIElementChangedNotification, &0)
*/
        
        enableGlobalAccessibilityFeatures()
        toast.toast("Initialized")
    }
    
    // VoiceOver が起動していない限りアクセシビリティオブジェクトを作らない一部アプリケーション用 (eg. Google Chrome) に
    // VoiceOver がセットする属性をセットする。VoiceOver 判定のため自プロセスには設定しない
    func enableGlobalAccessibilityFeatures() {
        print("enableGlobalAccessibilityFeatures")
        NSWorkspace.shared().notificationCenter.addObserver(
            self,
            selector: #selector(AppDelegate.enableAccessibilityForNewApplication(_:)),
            name: NSNotification.Name.NSWorkspaceDidLaunchApplication,
            object: nil
        )
        
        let ptr: UnsafeMutablePointer<AnyObject?> = UnsafeMutablePointer<AnyObject?>.allocate(capacity: 1)
        let pid = ProcessInfo.processInfo.processIdentifier
        for application in NSWorkspace.shared().runningApplications {
            if application.processIdentifier == pid {
                continue
            }
            let app: AXUIElement! = AXUIElementCreateApplication(application.processIdentifier)
            print("enableGlobalAccessibilityFeatures: \(app)")
            AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface" as NSString, ptr)
            AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as NSString, 1 as AnyObject)
        }
    }
    
    // callback
    func enableAccessibilityForNewApplication(_ aNotification: Notification) {
        let pid = aNotification.userInfo!["NSApplicationProcessIdentifier"] as! Int
        
        let ptr: UnsafeMutablePointer<AnyObject?> = UnsafeMutablePointer<AnyObject?>.allocate(capacity: 1)
        let app = AXUIElementCreateApplication(Int32(pid))
        print("NSWorkspaceWillLaunchApplicationNotification")
        print(app)
        
        AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface" as NSString, ptr)
        AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as NSString, 1 as AnyObject)
    }
    
    func disableGlobalAccessibilityFeatures() {
        NSWorkspace.shared().notificationCenter.removeObserver(self, name: NSNotification.Name.NSWorkspaceWillLaunchApplication, object: nil)
        
        if isVoiceOverRunning() {
            return
        }
        
        let ptr: UnsafeMutablePointer<AnyObject?> = UnsafeMutablePointer<AnyObject?>.allocate(capacity: 1)
        let pid = ProcessInfo.processInfo.processIdentifier
        for application in NSWorkspace.shared().runningApplications {
            if application.processIdentifier == pid {
                continue
            }
            let app = AXUIElementCreateApplication(application.processIdentifier)
            print(app)
            
            AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface" as NSString, ptr)
            AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as NSString, 0 as AnyObject)
        }
    }
    
    // 完全に起動したあとでなければ常に false を返す
    func isVoiceOverRunning()->Bool {
        let ptr: UnsafeMutablePointer<AnyObject?> = UnsafeMutablePointer<AnyObject?>.allocate(capacity: 1)
        let pid = ProcessInfo.processInfo.processIdentifier
        let app = AXUIElementCreateApplication(pid)
        AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface" as NSString, ptr)
        if let running = ptr.pointee as? Int {
            if running == 1 {
                return true
            }
        }
        return false
    }
    
    func userDefaultsDidChange(_ aNotification: Notification!) {
        window.alphaValue = CGFloat(preferences.opacity) / 100.0
        self.resize(preferences.width, height: preferences.height)
        view.shadowCount = preferences.shadow
        view.maxLine = preferences.lines
        view.needsDisplay = true
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        disableGlobalAccessibilityFeatures()
    }
    
    func resize (_ width: Int, height: Int) {
        let current = window.frame
        let rect = NSRect(x: Int(current.minX), y: Int(current.minY), width: width, height: height)
        window.setFrame(rect, display: true)
        view.setFrameSize(NSSize(width: rect.width, height: rect.height))
    }

    func updateMenuTitle() {
        statusItem.title = (enabled ? "\u{2713} " : "  ") + NSRunningApplication.current().localizedName!
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
        
        let ptr: UnsafeMutablePointer<AnyObject?> = UnsafeMutablePointer<AnyObject?>.allocate(capacity: 1)
        
        let system = AXUIElementCreateSystemWide()
        
        AXUIElementCopyAttributeValue(system, "AXFocusedApplication" as NSString, ptr)
        if ptr.pointee == nil {
            return true
        }
        let focusedApp = ptr.pointee! as! AXUIElement
        
        var pid: pid_t = 0
        AXUIElementGetPid(focusedApp, &pid)
        
        let bundleId_ = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
        if bundleId_ == nil {
            return true
        }
        let bundleId = bundleId_!
        
        
        AXUIElementCopyAttributeValue(focusedApp, NSAccessibilityFocusedUIElementAttribute as CFString, ptr)
        if ptr.pointee == nil {
            return true
        }
        let ui = ptr.pointee! as! AXUIElement
        
        
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
        
        AXUIElementCopyAttributeValue(ui, "AXSubrole" as CFString, ptr)
        if ptr.pointee != nil {
            let value = ptr.pointee! as! String
            if value == "AXSecureTextField" {
                return false
            }
        }
        
        // NSAccessibilityFocusedUIElementChangedNotification
        return true
    }
    
    
    @IBAction func toggleState(_ sender: AnyObject!) {
        enabled = !enabled
    }
    
    @IBAction func clearLog(_ sender: AnyObject) {
        view.clear()
    }
    
    @IBAction func openPreferencesWindow(_ sender: AnyObject) {
        preferences.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func chooseFont(_ sender: AnyObject) {
        let fontManager = NSFontManager.shared()
        fontManager.delegate = self
        fontManager.target = self
        fontManager.setSelectedFont(preferences.font, isMultiple: false)
        
        let fontPanel = fontManager.fontPanel(true)
        fontPanel?.makeKeyAndOrderFront(sender)
    }
    
    override func changeFont(_ sender: Any?) {
        let fontManager = sender! as! NSFontManager
        print("changeFont")
        print(fontManager)
        preferences.font = fontManager.convert(preferences.font)
        view.needsDisplay = true
        print(preferences.font.fontName)
        print(preferences.font.pointSize)
        
        preferences.updateFontInfo(preferences.font)
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
    override func application(_ sender: NSApplication, delegateHandlesKey key: String) -> Bool {
        if key == "enabled" {
            return true
        }
        return false
    }
    
    @IBAction func showAbout(_ sender: AnyObject) {
        about.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

