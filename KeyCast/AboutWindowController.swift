import Cocoa
import WebKit

class AboutWindow: NSWindow, WebPolicyDelegate {
    @IBOutlet weak var webview: WebView!
    @IBOutlet weak var labelVersion: NSTextField!
    
    let aboutURL = Bundle.main.path(forResource: "Credits", ofType: "html")!
    
    override func awakeFromNib() {
        webview.mainFrameURL = aboutURL
        webview.policyDelegate = self
        
        let info = Bundle.main.infoDictionary!
        let appVersion = info["CFBundleShortVersionString"] as! String
        let buildVersion = info["CFBundleVersion"] as! String
        labelVersion.stringValue = "v\(appVersion) build \(buildVersion)"
    }
    
    internal func webView(_ webView: WebView!, decidePolicyForNavigationAction actionInformation: [AnyHashable : Any]!, request: URLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {

        if actionInformation?["WebActionOriginalURLKey"] != nil {
            listener.ignore()
            NSWorkspace.shared.open(request.url!)
        } else {
            listener.use()
        }
    }
}
