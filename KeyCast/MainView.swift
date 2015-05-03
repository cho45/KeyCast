//
//  MainView.swift
//  KeyCast
//

import Cocoa

class MainView : NSView {
    internal var log = ""
    var font = NSFont.boldSystemFontOfSize(24)
    var shadowCount = 10
    var maxLine : Int = 5
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        NSColor.clearColor().set()
        NSRectFill(self.bounds)
        
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.blackColor()
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = NSSize(width: 0, height: 0)
        let attrs = [
            NSForegroundColorAttributeName: NSColor.whiteColor(),
            NSFontAttributeName: font,
            NSShadowAttributeName: shadow,
        ]
        
        var y = 0
        let lines = split(log, isSeparator: { $0 == "\n" }).reverse()
        for line in lines {
            let storage = NSTextStorage(string: line, attributes: attrs)
            let manager = NSLayoutManager()
            let container = NSTextContainer()
            
            manager.addTextContainer(container)
            storage.addLayoutManager(manager)
            
            let range = manager.glyphRangeForTextContainer(container)
            for i in 1...shadowCount {
                manager.drawGlyphsForGlyphRange(range, atPoint: NSPoint(x: 0, y: y))
            }
            let rect = manager.boundingRectForGlyphRange(NSRange(location: 0, length: manager.numberOfGlyphs), inTextContainer: container)
            y += Int(rect.size.height)
        }
    }
    
    func appendLog(str: String) {
        log += str
        let lines = split(log, isSeparator: { $0 == "\n" })
        if lines.count > maxLine {
            log = join("\n", lines[lines.count - maxLine ..< lines.count])
        }
        self.needsDisplay = true
    }
    
    func clear() {
        log = ""
        self.needsDisplay = true
    }
}
