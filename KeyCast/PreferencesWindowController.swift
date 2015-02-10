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
    
    func initControls() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.registerDefaults([
            "width": 800,
            "height": 600,
            "shadow": 5,
            "lines": 5,
            "opacity": 90,
        ])
        defaults.synchronize()
        
        inputWidth.bind("value", toObject: userDefaultsController, withKeyPath: "values.width", options: [ "NSContinuouslyUpdatesValue": true ])
        inputHeight.bind("value", toObject: userDefaultsController, withKeyPath: "values.height", options: [ "NSContinuouslyUpdatesValue": true ])
        inputLines.bind("value", toObject: userDefaultsController, withKeyPath: "values.lines", options: [ "NSContinuouslyUpdatesValue": true ])
        inputShadow.bind("value", toObject: userDefaultsController, withKeyPath: "values.shadow", options: [ "NSContinuouslyUpdatesValue": true ])
        inputOpacity.bind("value", toObject: userDefaultsController, withKeyPath: "values.opacity", options: [ "NSContinuouslyUpdatesValue": true ])
        
        let fontName = userDefaultsController.values.valueForKey("fontName") as String?
        let pointSize = userDefaultsController.values.valueForKey("pointSize") as Float?
        if fontName != nil && pointSize != nil {
            let font_ = NSFont(name: fontName!, size: CGFloat(pointSize!))
            if font_ != nil {
                font = font_!
            }
        }
        updateFontInfo(font)
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
}

