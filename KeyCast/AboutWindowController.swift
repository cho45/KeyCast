import Cocoa
import WebKit

class AboutWindow: NSWindow, WKNavigationDelegate {
    @IBOutlet weak var webview: WebView!
    @IBOutlet weak var labelVersion: NSTextField!
    
    let aboutURL = NSBundle.mainBundle().pathForResource("Credits", ofType: "html")!
    
    override func awakeFromNib() {
        webview.mainFrameURL = aboutURL
        webview.policyDelegate = self
        
        let info = NSBundle.mainBundle().infoDictionary!
        let appVersion = info["CFBundleShortVersionString"] as! String
        let buildVersion = info["CFBundleVersion"] as! String
        labelVersion.stringValue = "v\(appVersion) build \(buildVersion)"
    }
    
    override func webView(sender: WebView!, decidePolicyForNavigationAction actionInformation: [NSObject : AnyObject]!, request: NSURLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {

        if actionInformation["WebActionOriginalURLKey"] != nil {
            listener.ignore()
            NSWorkspace.sharedWorkspace().openURL(request.URL!)
        } else {
            listener.use()
        }
    }
}