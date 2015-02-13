//
//  PreferencesWindowController.swift
//  KeyCast
//

import Cocoa

class PreferencesWindow: NSWindow {
    @IBOutlet weak var textSelectedFont: NSTextField!
    @IBOutlet weak var inputWidth: NSTextField!
    @IBOutlet weak var inputHeight: NSTextField!
    @IBOutlet weak var inputShadow: NSSlider!
    @IBOutlet weak var inputOpacity: NSSlider!
    @IBOutlet weak var inputLines: NSTextField!
    @IBOutlet weak var inputHideInputAutomaticaly: NSButton!
    @IBOutlet weak var inputHideNativePasswordInput: NSButton!
    @IBOutlet weak var inputHideSudoInProcessList: NSButton!
    
    let userDefaultsController = NSUserDefaultsController.sharedUserDefaultsController()
    var font = NSFont.boldSystemFontOfSize(24)
    
    var width : Int {
        get {
            return userDefaultsController.values.valueForKey("width") as Int
        }
    }
    
    var height : Int {
        get {
            return userDefaultsController.values.valueForKey("height") as Int
        }
    }
    
    var lines : Int {
        get {
            return userDefaultsController.values.valueForKey("lines") as Int
        }
    }
    
    var shadow : Int {
        get {
            return userDefaultsController.values.valueForKey("shadow") as Int
        }
    }
    
    var opacity : Int {
        get {
            return userDefaultsController.values.valueForKey("opacity") as Int
        }
    }
    
    var hideInputAutomaticaly : Bool {
        get {
            return userDefaultsController.values.valueForKey("hideInputAutomaticaly") as Bool
        }
    }
    var hideNativePasswordInput : Bool {
        get {
            return hideInputAutomaticaly && userDefaultsController.values.valueForKey("hideNativePasswordInput") as Bool
        }
    }
    var hideSudoInProcessList : Bool {
        get {
            return hideInputAutomaticaly &&  userDefaultsController.values.valueForKey("hideSudoInProcessList") as Bool
        }
    }
    
    override func awakeFromNib() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.registerDefaults([
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
        
        inputWidth.bind("value", toObject: userDefaultsController, withKeyPath: "values.width", options: [ "NSContinuouslyUpdatesValue": true ])
        inputHeight.bind("value", toObject: userDefaultsController, withKeyPath: "values.height", options: [ "NSContinuouslyUpdatesValue": true ])
        inputLines.bind("value", toObject: userDefaultsController, withKeyPath: "values.lines", options: [ "NSContinuouslyUpdatesValue": true ])
        inputShadow.bind("value", toObject: userDefaultsController, withKeyPath: "values.shadow", options: [ "NSContinuouslyUpdatesValue": true ])
        inputOpacity.bind("value", toObject: userDefaultsController, withKeyPath: "values.opacity", options: [ "NSContinuouslyUpdatesValue": true ])
        
        inputHideInputAutomaticaly.bind("value", toObject: userDefaultsController, withKeyPath: "values.hideInputAutomaticaly", options: [ "NSContinuouslyUpdatesValue": true ])
        inputHideNativePasswordInput.bind("value", toObject: userDefaultsController, withKeyPath: "values.hideNativePasswordInput", options: [ "NSContinuouslyUpdatesValue": true ])
        inputHideSudoInProcessList.bind("value", toObject: userDefaultsController, withKeyPath: "values.hideSudoInProcessList", options: [ "NSContinuouslyUpdatesValue": true ])
        
        let fontName = userDefaultsController.values.valueForKey("fontName") as String?
        let pointSize = userDefaultsController.values.valueForKey("pointSize") as Float?
        if fontName != nil && pointSize != nil {
            let font_ = NSFont(name: fontName!, size: CGFloat(pointSize!))
            if font_ != nil {
                font = font_!
            }
        }
        updateFontInfo(font)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "userDefaultsDidChange:",
            name: NSUserDefaultsDidChangeNotification,
            object: nil
        )
        userDefaultsDidChange(nil)
    }
    
    func userDefaultsDidChange(aNotification: NSNotification!) {
        if hideInputAutomaticaly {
            inputHideNativePasswordInput.enabled = true
            inputHideSudoInProcessList.enabled = true
        } else {
            inputHideNativePasswordInput.enabled = false
            inputHideSudoInProcessList.enabled = false
        }
    }
    
    override func cancelOperation(sender: AnyObject?) {
        close()
    }
    
    func updateFontInfo(f: NSFont) {
        font = f
        textSelectedFont.stringValue = String(format: "%@ %.0fpt", font.displayName!, Float(font.pointSize))
        userDefaultsController.values.setValue(font.fontName, forKey: "fontName")
        userDefaultsController.values.setValue(Float(font.pointSize), forKey: "pointSize")
    }
    
    @IBAction func setScreenWidth(sender: AnyObject) {
        if let width = screen?.visibleFrame.size.width {
            userDefaultsController.values.setValue(width, forKey: "width")
        }
    }
}

