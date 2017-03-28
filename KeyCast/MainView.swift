//
//  MainView.swift
//  KeyCast
//

import Cocoa
import Foundation


class MainView : NSView {
    internal var log = ""
    var font = NSFont.boldSystemFont(ofSize: 24)
    var shadowCount = 10
    var maxLine : Int = 5
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.clear.set()
        NSRectFill(self.bounds)
        
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = NSSize(width: 0, height: 0)
        let attrs = [
            NSForegroundColorAttributeName: NSColor.white,
            NSFontAttributeName: font,
            NSShadowAttributeName: shadow,
        ] as [String : Any]
        
        var y = 0
        let lines = log.components(separatedBy: "\n").reversed()
        for line in lines {
            let storage = NSTextStorage(string: line, attributes: attrs)
            let manager = NSLayoutManager()
            let container = NSTextContainer()
            
            manager.addTextContainer(container)
            storage.addLayoutManager(manager)
            
            let range = manager.glyphRange(for: container)
            for _ in 1...shadowCount {
                manager.drawGlyphs(forGlyphRange: range, at: NSPoint(x: 0, y: y))
            }
            let rect = manager.boundingRect(forGlyphRange: NSRange(location: 0, length: manager.numberOfGlyphs), in: container)
            y += Int(rect.size.height)
        }
    }
    
    func appendLog(_ str: String) {
        log += str
        let lines = log.components(separatedBy: "\n" )
        if lines.count > maxLine {
            log = lines[lines.count - maxLine ..< lines.count].joined(separator: "\n")
        }
        self.needsDisplay = true
    }
    
    func clear() {
        log = ""
        self.needsDisplay = true
    }
}
