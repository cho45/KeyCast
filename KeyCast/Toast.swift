import Cocoa


class ToastView : NSView {
    override func drawRect(dirtyRect: NSRect) {
        NSColor.clearColor().set()
        NSRectFill(bounds)
        
        let path = NSBezierPath(roundedRect: bounds, xRadius: 10.0, yRadius: 10.0)
        NSColor(calibratedWhite: 0.0, alpha: 0.5).set()
        path.fill()
    }
}

class ToastWindow : NSWindow {
    @IBOutlet weak var label: NSTextField!
    
    var timer: NSTimer!
    
    func toast(str: String) {
        println("toast \(str)")
        label.stringValue = str
        alphaValue = 1.0
        if timer != nil {
            timer.invalidate()
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "fadeOut", userInfo: nil, repeats: false)
        makeKeyAndOrderFront(nil)
    }
    
    override func awakeFromNib() {
        hasShadow = true
        opaque = false
        level = 10000
        movable = false
        movableByWindowBackground = false
    }
    
    func fadeOut() {
        animator().alphaValue = 0.0
        NSTimer.scheduledTimerWithTimeInterval(NSAnimationContext.currentContext().duration + 0.1, target: self, selector: "orderOut:", userInfo: nil, repeats: false)
    }
}