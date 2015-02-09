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
        /*
        "\xEF701F\x9C\xAC" : "⇞",
        "\xEF\x9C\xAD" : "⇟",
        "\xEF\x9C\xA9" : "↖",
        "\xEF\x9C\xAB" : "↘",
        */
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

        // AXSecureTextField については送られてこないので大丈夫
        // ブラウザとかは AXSecureTextField を使っていないので、表示されることがある。自動的に判定することができない
        // ターミナルも同様
        NSEvent.addGlobalMonitorForEventsMatchingMask(NSEventMask.KeyDownMask) { (e: NSEvent!) in
            if !self.canShowInput() {
                return
            }
            if e.type != NSEventType.KeyDown {
                return
            }
            // println(e)
            
            var mod = ""
            if e.modifierFlags.rawValue &  NSEventModifierFlags.ShiftKeyMask.rawValue != 0 {
                mod += "⇧"
            }
            if e.modifierFlags.rawValue &  NSEventModifierFlags.ControlKeyMask.rawValue != 0 {
                mod += "⌃"
            }
            if e.modifierFlags.rawValue &  NSEventModifierFlags.AlternateKeyMask.rawValue != 0 {
                mod += "⌥"
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
        
        statusItem.title = "KeyCast"
        statusItem.menu = menu
        statusItem.highlightMode = true
        
        view.appendLog("KeyCast Initialized\nYou can drag this to the position you wish")
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "userDefaultsDidChange:",
            name: NSUserDefaultsDidChangeNotification,
            object: nil
        )
        self.resize(preferences.width, height: preferences.height)
    }
    
    func userDefaultsDidChange(aNotification: NSNotification) {
        window.alphaValue = CGFloat(preferences.opacity) / 100.0
        self.resize(preferences.width, height: preferences.height)
        view.shadowCount = preferences.shadow
        view.needsDisplay = true
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
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
        var focusedApp = ptr!.takeRetainedValue() as AXUIElement
        
        AXUIElementCopyAttributeValue(focusedApp, NSAccessibilityFocusedUIElementAttribute, &ptr)
        if ptr == nil {
            return true
        }
        var ui = ptr!.takeRetainedValue() as AXUIElement
        
        AXUIElementCopyAttributeValue(ui, "AXValue", &ptr)
        if ptr == nil {
            return true
        }
        let value = ptr!.takeRetainedValue() as String
        
        // Terminal.app で sudo っぽいことが起きていたらタイプを表示しない
        // (screen の中だと意味がない)
        let re = NSRegularExpression(pattern: "Password:\\s*$", options: .CaseInsensitive, error: nil)!
        let matches = re.matchesInString(value, options: nil, range: NSMakeRange(0, countElements(value)))
        if matches.count > 0 {
            return false
        }
        // NSAccessibilityFocusedUIElementChangedNotification
        return true
    }
    
    
    @IBAction func toggleState(sender: NSMenuItem) {
        enabled = !enabled
        sender.state = enabled ? 1 : 0
        println(enabled)
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
}

