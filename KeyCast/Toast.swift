import Cocoa


class ToastView : NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        bounds.fill()
        
        let path = NSBezierPath(roundedRect: bounds, xRadius: 10.0, yRadius: 10.0)
        NSColor(calibratedWhite: 0.0, alpha: 0.5).set()
        path.fill()
    }
}

class ToastWindow : NSWindow {
    @IBOutlet weak var label: NSTextField!
    
    var timer: Timer!
    
    func toast(str: String) {
        print("toast \(str)")
        label.stringValue = str
        alphaValue = 1.0
        if timer != nil {
            timer.invalidate()
        }
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(fadeOut), userInfo: nil, repeats: false)
        makeKeyAndOrderFront(nil)
    }
    
    override func awakeFromNib() {
        hasShadow = true
        isOpaque = false
        level = NSWindow.Level(rawValue: 10000)
        isMovable = false
        isMovableByWindowBackground = false
    }
    
    @objc func fadeOut() {
        animator().alphaValue = 0.0
        Timer.scheduledTimer(timeInterval: NSAnimationContext.current.duration + 0.1, target: self, selector: #selector(orderOut(_:)), userInfo: nil, repeats: false)
    }
}
