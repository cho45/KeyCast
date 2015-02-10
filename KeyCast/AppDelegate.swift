//
//  AppDelegate.swift
//  KeyCast
//
//  Copyright (c) 2015年 cho45. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let REPLACE_MAP: Dictionary<String, String> = [
        "\r"   : "↵\n",
        "\u{1B}"   : "⎋",
        "\t"   : "⇥",
        "\u{19}" : "⇤",
        " "    : "␣",
        "\u{7f}" : "⌫",
        "\u{03}" : "⌤",
        "\u{10}" : "⏏",
        "\u{F728}" : "⌦",
        "\u{F739}" : "⌧",
        "\u{F704}" : "[F1]",
        "\u{F705}" : "[F2]",
        "\u{F706}" : "[F3]",
        "\u{F707}" : "[F4]",
        "\u{F708}" : "[F5]",
        "\u{F709}" : "[F6]",
        "\u{F70A}" : "[F7]",
        "\u{F70B}" : "[F8]",
        "\u{F70C}" : "[F9]",
        "\u{F70D}" : "[F10]",
        "\u{F70E}" : "[F11]",
        "\u{F70F}" : "[F12]",

        "\u{F700}" : "↑",
        "\u{F701}" : "↓",
        "\u{F702}" : "←",
        "\u{F703}" : "→",
        "\u{F72C}" : "⇞",
        "\u{F72D}" : "⇟",
        "\u{F729}" : "↖",
        "\u{F72B}" : "↘",
    ]
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    var enabled: Bool = true
    var window: NSWindow! = nil
    var view: MainView! = nil
    var prevKeyed: NSDate = NSDate()

    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var preferences: PreferencesWindow!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        Accessibility.checkAccessibilityEnabled(self)

        NSEvent.addGlobalMonitorForEventsMatchingMask(NSEventMask.KeyDownMask) { (e: NSEvent!) in
            if !self.canShowInput() {
                return
            }
            if e.type != NSEventType.KeyDown {
                return
            }
            // println(e)
            
            var mod = ""
            if e.modifierFlags.rawValue &  NSEventModifierFlags.ControlKeyMask.rawValue != 0 {
                mod += "⌃"
            }
            if e.modifierFlags.rawValue &  NSEventModifierFlags.AlternateKeyMask.rawValue != 0 {
                mod += "⌥"
            }
            if e.modifierFlags.rawValue &  NSEventModifierFlags.ShiftKeyMask.rawValue != 0 {
                mod += "⇧"
            }
            if e.modifierFlags.rawValue &  NSEventModifierFlags.CommandKeyMask.rawValue != 0 {
                mod += "⌘"
            }
            
            
            for c in e.charactersIgnoringModifiers!.uppercaseString.unicodeScalars {
                print(NSString(format: "%08X", c.value)); print(" ")
            }
            

            let char = self.keyToReadableString(e.charactersIgnoringModifiers!.uppercaseString)
            if mod.isEmpty {
                let interval = NSDate().timeIntervalSinceDate(self.prevKeyed)
                println(interval)
                if interval > 1 {
                    self.view.appendLog("\n" + char)
                } else {
                    self.view.appendLog(char)
                }
            } else {
                self.view.appendLog("\n" + mod + char + " ")

            }
            
            self.prevKeyed = NSDate()
        }
        
        preferences.initControls()
        
        let rect = NSRect(x: 0, y: 0, width: 800, height: 500)
        window = NSWindow(contentRect: rect, styleMask: NSBorderlessWindowMask, backing: NSBackingStoreType.Buffered, defer: false)
        window.opaque = false
        window.hasShadow = false
        window.level = 1000
        window.movableByWindowBackground = true
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
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "userDefaultsDidChange:",
            name: NSUserDefaultsDidChangeNotification,
            object: nil
        )
        self.userDefaultsDidChange(NSNotification())
        
        
        enableGlobalAccessibilityFeatures()
    }
    
    // VoiceOver が起動していない限りアクセシビリティオブジェクトを作らない一部アプリケーション用 (eg. Google Chrome) に
    // VoiceOver がセットする属性をセットする。VoiceOver 判定のため自プロセスには設定しない
    func enableGlobalAccessibilityFeatures() {
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(
            self,
            selector: "enableAccessibilityForNewApplication:",
            name: NSWorkspaceDidLaunchApplicationNotification,
            object: nil
        )
        
        var ptr: Unmanaged<AnyObject>?
        let pid = NSProcessInfo.processInfo().processIdentifier
        for application in NSWorkspace.sharedWorkspace().runningApplications {
            if application.processIdentifier == pid {
                continue
            }
            let app = AXUIElementCreateApplication(application.processIdentifier).takeRetainedValue()
            
            AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface", &ptr)
            AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface", 1)
        }
    }
    
    // callback
    func enableAccessibilityForNewApplication(aNotification: NSNotification) {
        let pid = aNotification.userInfo!["NSApplicationProcessIdentifier"] as Int
        
        var ptr: Unmanaged<AnyObject>?
        let app = AXUIElementCreateApplication(Int32(pid)).takeRetainedValue()
        println("NSWorkspaceWillLaunchApplicationNotification")
        println(app)
        
        AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface", &ptr)
        AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface", 1)
    }
    
    func disableGlobalAccessibilityFeatures() {
        NSWorkspace.sharedWorkspace().notificationCenter.removeObserver(self, name: NSWorkspaceWillLaunchApplicationNotification, object: nil)
        
        if isVoiceOverRunning() {
            return
        }
        
        var ptr: Unmanaged<AnyObject>?
        let pid = NSProcessInfo.processInfo().processIdentifier
        for application in NSWorkspace.sharedWorkspace().runningApplications {
            if application.processIdentifier == pid {
                continue
            }
            let app = AXUIElementCreateApplication(application.processIdentifier).takeRetainedValue()
            println(app)
            
            AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface", &ptr)
            AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface", 0)
        }
    }
    
    // 完全に起動したあとでなければ常に false を返す
    func isVoiceOverRunning()->Bool {
        var ptr: Unmanaged<AnyObject>?
        let pid = NSProcessInfo.processInfo().processIdentifier
        let app = AXUIElementCreateApplication(pid).takeRetainedValue()
        AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface", &ptr)
        if let running = ptr?.takeRetainedValue() as? Int {
            if running == 1 {
                return true
            }
        }
        return false
    }
    
    func userDefaultsDidChange(aNotification: NSNotification) {
        window.alphaValue = CGFloat(preferences.opacity) / 100.0
        self.resize(preferences.width, height: preferences.height)
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

    func keyToReadableString (string: String)-> String {
        var str = string
        for (k, v) in self.REPLACE_MAP {
            str = str.stringByReplacingOccurrencesOfString(k, withString: v)
        }
        return str
    }

    
    func updateMenuTitle() {
        statusItem.title = (enabled ? "\u{2713} " : "  ") + NSRunningApplication.currentApplication().localizedName!
    }
    
    func canShowInput()-> Bool {
        return enabled && canShowInputByFocusedUIElement()
    }
    
    func canShowInputByFocusedUIElement()->Bool {
        var ptr: Unmanaged<AnyObject>?
        
        let system = AXUIElementCreateSystemWide().takeRetainedValue()
        
        AXUIElementCopyAttributeValue(system, "AXFocusedApplication", &ptr)
        if ptr == nil {
            return true
        }
        let focusedApp = ptr!.takeRetainedValue() as AXUIElement
        println("focusedApp")
        println(focusedApp)
        
        var pid: pid_t = 0
        AXUIElementGetPid(focusedApp, &pid)
        
        let bundleId_ = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
        if bundleId_ == nil {
            return true
        }
        let bundleId = bundleId_!
        
        
        AXUIElementCopyAttributeValue(focusedApp, NSAccessibilityFocusedUIElementAttribute, &ptr)
        if ptr == nil {
            return true
        }
        let ui = ptr!.takeRetainedValue() as AXUIElement
        println("ui")
        println(ui)
        
        
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
        
        AXUIElementCopyAttributeValue(ui, "AXSubrole", &ptr)
        if ptr != nil {
            let value = ptr!.takeRetainedValue() as String
            println(value)
            if value == "AXSecureTextField" {
                return false
            }
        }
        
        // NSAccessibilityFocusedUIElementChangedNotification
        return true
    }
    
    
    @IBAction func toggleState(sender: NSMenuItem) {
        enabled = !enabled
        sender.state = enabled ? 1 : 0
        println(enabled)
        updateMenuTitle()
    }
    
    @IBAction func openPreferencesWindow(sender: AnyObject) {
        preferences.orderFrontRegardless()
    }
    
    @IBAction func chooseFont(sender: AnyObject) {
        let fontManager = NSFontManager.sharedFontManager()
        fontManager.delegate = self
        fontManager.target = self
        fontManager.setSelectedFont(preferences.font, isMultiple: false)
        
        let fontPanel = fontManager.fontPanel(true)
        fontPanel?.makeKeyAndOrderFront(sender)
    }
    
    override func changeFont(sender: AnyObject?) {
        let fontManager = sender! as NSFontManager
        println("changeFont")
        println(fontManager)
        preferences.font = fontManager.convertFont(preferences.font)
        view.needsDisplay = true
        println(preferences.font.fontName)
        println(preferences.font.pointSize)
        
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
}

