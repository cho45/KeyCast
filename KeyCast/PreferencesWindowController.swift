//
//  PreferencesWindowController.swift
//  KeyCast
//

import Cocoa

class PreferencesWindow: NSWindow, RecorderControlDelegate {
    @IBOutlet weak var textSelectedFont: NSTextField!
    @IBOutlet weak var inputWidth: NSTextField!
    @IBOutlet weak var inputHeight: NSTextField!
    @IBOutlet weak var inputShadow: NSSlider!
    @IBOutlet weak var inputOpacity: NSSlider!
    @IBOutlet weak var inputLines: NSTextField!
    @IBOutlet weak var inputHideInputAutomaticaly: NSButton!
    @IBOutlet weak var inputHideNativePasswordInput: NSButton!
    @IBOutlet weak var inputHideSudoInProcessList: NSButton!
    @IBOutlet weak var inputHotkey: RecorderControl!
    
    let userDefaultsController = NSUserDefaultsController.shared
    var font = NSFont.boldSystemFont(ofSize: 24)
    
    var width : Int {
        get {
            return userDefaultsController.value(forKey: "width") as! Int
        }
    }
    
    var height : Int {
        get {
            return userDefaultsController.value(forKey: "height") as! Int
        }
    }
    
    var lines : Int {
        get {
            return userDefaultsController.value(forKey: "lines") as! Int
        }
    }
    
    var shadow : Int {
        get {
            return userDefaultsController.value(forKey: "shadow") as! Int
        }
    }
    
    var opacity : Int {
        get {
            return userDefaultsController.value(forKey: "opacity") as! Int
        }
    }
    
    var hideInputAutomaticaly : Bool {
        get {
            return userDefaultsController.value(forKey: "hideInputAutomaticaly") as! Bool
        }
    }
    var hideNativePasswordInput : Bool {
        get {
            return hideInputAutomaticaly && userDefaultsController.value(forKey: "hideNativePasswordInput") as! Bool
        }
    }
    var hideSudoInProcessList : Bool {
        get {
            return hideInputAutomaticaly &&  userDefaultsController.value(forKey: "hideSudoInProcessList") as! Bool
        }
    }
    
    var hotkey : (UInt16, NSEvent.ModifierFlags)? {
        get {
            if let key = userDefaultsController.value(forKey: "hotkey") as? Dictionary<String, AnyObject> {
                let keyCode : UInt16 = numericCast(key["keyCode"]! as! UInt)
                let modifierFlags = NSEvent.ModifierFlags(rawValue: key["modifierFlags"] as! UInt)
                return (keyCode, modifierFlags)
            } else {
                return nil
            }
        }
    }
    
    override func awakeFromNib() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "fontName": "",
            "pointSize": 16,
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
        
        inputWidth.bind(NSBindingName.value, to: userDefaultsController, withKeyPath: "values.width", options:  [ NSBindingOption.continuouslyUpdatesValue: true ])
        inputHeight.bind(NSBindingName.value, to: userDefaultsController, withKeyPath: "values.height", options: [ NSBindingOption.continuouslyUpdatesValue: true ])
        inputLines.bind(NSBindingName.value, to: userDefaultsController, withKeyPath: "values.lines", options: [ NSBindingOption.continuouslyUpdatesValue: true ])
        inputShadow.bind(NSBindingName.value, to: userDefaultsController, withKeyPath: "values.shadow", options: [ NSBindingOption.continuouslyUpdatesValue: true ])
        inputOpacity.bind(NSBindingName.value, to: userDefaultsController, withKeyPath: "values.opacity", options: [ NSBindingOption.continuouslyUpdatesValue: true ])
        inputHotkey.bind(NSBindingName.value, to: userDefaultsController, withKeyPath: "values.hotkey", options: nil )
        inputHotkey.delegate = self
        inputHotkey.allowsEscapeToCancelRecording = true
        inputHotkey.set(allowedModifierFlags: [.shift, .command, .control, .option], requiredModifierFlags: [], allowsEmptyModifierFlags: false)
        inputHotkey.isEnabled = true
        
        inputHideInputAutomaticaly.bind(NSBindingName.value, to: userDefaultsController, withKeyPath: "values.hideInputAutomaticaly", options: [ NSBindingOption.continuouslyUpdatesValue: true ])
        inputHideNativePasswordInput.bind(NSBindingName.value, to: userDefaultsController, withKeyPath: "values.hideNativePasswordInput", options: [ NSBindingOption.continuouslyUpdatesValue: true ])
        inputHideSudoInProcessList.bind(NSBindingName.value, to: userDefaultsController, withKeyPath: "values.hideSudoInProcessList", options: [ NSBindingOption.continuouslyUpdatesValue: true ])
        
        print(userDefaultsController.values)
        let fontName = userDefaultsController.value(forKey:"fontName") as! String?
        let pointSize = userDefaultsController.value(forKey:"pointSize") as! Float?
        if fontName != nil && pointSize != nil {
            let font_ = NSFont(name: fontName!, size: CGFloat(pointSize!))
            if font_ != nil {
                font = font_!
            }
        }
        updateFontInfo(f: font)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange(aNotification:)),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
        userDefaultsDidChange(aNotification: nil)
    }
    
    @objc func userDefaultsDidChange(aNotification: NSNotification!) {
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
    
    func shortcutRecorderDidEndRecording(sr: RecorderControl) {
    }
    
    func cancelOperation(sender: AnyObject?) {
        close()
    }
    
    func updateFontInfo(f: NSFont) {
        font = f
        textSelectedFont.stringValue = String(format: "%@ %.0fpt", font.displayName!, Float(font.pointSize))
        userDefaultsController.setValue(font.fontName, forKey: "fontName")
        userDefaultsController.setValue(Float(font.pointSize), forKey: "pointSize")
    }
    
    @IBAction func setScreenWidth(sender: AnyObject) {
        if let width = screen?.visibleFrame.size.width {
            userDefaultsController.setValue(width, forKey: "width")
        }
    }
}

