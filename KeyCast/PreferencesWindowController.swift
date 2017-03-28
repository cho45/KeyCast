//
//  PreferencesWindowController.swift
//  KeyCast
//

import Cocoa

class PreferencesWindow: NSWindow, SRRecorderControlDelegate {
    @IBOutlet weak var textSelectedFont: NSTextField!
    @IBOutlet weak var inputWidth: NSTextField!
    @IBOutlet weak var inputHeight: NSTextField!
    @IBOutlet weak var inputShadow: NSSlider!
    @IBOutlet weak var inputOpacity: NSSlider!
    @IBOutlet weak var inputLines: NSTextField!
    @IBOutlet weak var inputHideInputAutomaticaly: NSButton!
    @IBOutlet weak var inputHideNativePasswordInput: NSButton!
    @IBOutlet weak var inputHideSudoInProcessList: NSButton!
    @IBOutlet weak var inputHotkey: SRRecorderControl!
    
    let userDefaultsController = NSUserDefaultsController.shared()
    var font = NSFont.boldSystemFont(ofSize: 24)
    
    var width : Int {
        get {
            return (userDefaultsController.values as AnyObject).value(forKey: "width") as! Int
        }
    }
    
    var height : Int {
        get {
            return (userDefaultsController.values as AnyObject).value(forKey: "height") as! Int
        }
    }
    
    var lines : Int {
        get {
            return (userDefaultsController.values as AnyObject).value(forKey: "lines") as! Int
        }
    }
    
    var shadow : Int {
        get {
            return (userDefaultsController.values as AnyObject).value(forKey: "shadow") as! Int
        }
    }
    
    var opacity : Int {
        get {
            return (userDefaultsController.values as AnyObject).value(forKey: "opacity")as! Int
        }
    }
    
    var hideInputAutomaticaly : Bool {
        get {
            return (userDefaultsController.values as AnyObject).value(forKey: "hideInputAutomaticaly") as! Bool
        }
    }
    var hideNativePasswordInput : Bool {
        get {
            return hideInputAutomaticaly && (userDefaultsController.values as AnyObject).value(forKey: "hideNativePasswordInput") as! Bool
        }
    }
    var hideSudoInProcessList : Bool {
        get {
            return hideInputAutomaticaly &&  (userDefaultsController.values as AnyObject).value(forKey: "hideSudoInProcessList") as! Bool
        }
    }
    
    var hotkey : (UInt16, NSEventModifierFlags)? {
        get {
            if let key = (userDefaultsController.values as AnyObject).value(forKey: "hotkey") as? Dictionary<String, AnyObject> {
                let keyCode : UInt16 = numericCast(key["keyCode"]! as! UInt)
                let modifierFlags = NSEventModifierFlags(rawValue: key["modifierFlags"] as! UInt)
                return (keyCode, modifierFlags)
            } else {
                return nil
            }
        }
    }
    
    override func awakeFromNib() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "width": 800,
            "height": 600,
            "shadow": 5,
            "lines": 5,
            "opacity": 90,
            "hideInputAutomaticaly": true,
            "hideNativePasswordInput": true,
            "hideSudoInProcessList": true,
        ])
        defaults.synchronize()
        
        inputWidth.bind("value", to: userDefaultsController, withKeyPath: "values.width", options: [ "NSContinuouslyUpdatesValue": true ])
        inputHeight.bind("value", to: userDefaultsController, withKeyPath: "values.height", options: [ "NSContinuouslyUpdatesValue": true ])
        inputLines.bind("value", to: userDefaultsController, withKeyPath: "values.lines", options: [ "NSContinuouslyUpdatesValue": true ])
        inputShadow.bind("value", to: userDefaultsController, withKeyPath: "values.shadow", options: [ "NSContinuouslyUpdatesValue": true ])
        inputOpacity.bind("value", to: userDefaultsController, withKeyPath: "values.opacity", options: [ "NSContinuouslyUpdatesValue": true ])
        inputHotkey.bind("value", to: userDefaultsController, withKeyPath: "values.hotkey", options: nil )
        inputHotkey.delegate = self
        inputHotkey.allowsEscapeToCancelRecording = true
        let mask: NSEventModifierFlags = [.shift, .control, .option, .command]
        inputHotkey.setAllowedModifierFlags(mask, requiredModifierFlags: [], allowsEmptyModifierFlags: false)
        inputHotkey.isEnabled = true
        
        inputHideInputAutomaticaly.bind("value", to: userDefaultsController, withKeyPath: "values.hideInputAutomaticaly", options: [ "NSContinuouslyUpdatesValue": true ])
        inputHideNativePasswordInput.bind("value", to: userDefaultsController, withKeyPath: "values.hideNativePasswordInput", options: [ "NSContinuouslyUpdatesValue": true ])
        inputHideSudoInProcessList.bind("value", to: userDefaultsController, withKeyPath: "values.hideSudoInProcessList", options: [ "NSContinuouslyUpdatesValue": true ])
        
        let fontName = (userDefaultsController.values as AnyObject).value(forKey: "fontName") as! String?
        let pointSize = (userDefaultsController.values as AnyObject).value(forKey: "pointSize") as! Float?
        if fontName != nil && pointSize != nil {
            let font_ = NSFont(name: fontName!, size: CGFloat(pointSize!))
            if font_ != nil {
                font = font_!
            }
        }
        updateFontInfo(font)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(PreferencesWindow.userDefaultsDidChange(_:)),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
        userDefaultsDidChange(nil)
    }
    
    func userDefaultsDidChange(_ aNotification: Notification!) {
        print("changed")
        
        if hideInputAutomaticaly {
            inputHideNativePasswordInput.isEnabled = true
            inputHideSudoInProcessList.isEnabled = true
        } else {
            inputHideNativePasswordInput.isEnabled = false
            inputHideSudoInProcessList.isEnabled = false
        }
        
        // SRRecorderControl の bind を読むとなぜか無限ループになるのでここでは触らないようにしなければならない…
    }
    
    func shortcutRecorderDidEndRecording(_ sr: SRRecorderControl) {
    }
    
    override func cancelOperation(_ sender: Any?) {
        close()
    }
    
    func updateFontInfo(_ f: NSFont) {
        font = f
        textSelectedFont.stringValue = String(format: "%@ %.0fpt", font.displayName!, Float(font.pointSize))
        (userDefaultsController.values as AnyObject).setValue(font.fontName, forKey: "fontName")
        (userDefaultsController.values as AnyObject).setValue(Float(font.pointSize), forKey: "pointSize")
    }
    
    @IBAction func setScreenWidth(_ sender: AnyObject) {
        if let width = screen?.visibleFrame.size.width {
            (userDefaultsController.values as AnyObject).setValue(width, forKey: "width")
        }
    }
}

