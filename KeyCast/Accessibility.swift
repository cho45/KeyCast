//
//  Accessibility.swift
//  KeyCast
//
//  Created by Satoh on 2015/02/08.
//  Copyright (c) 2015年 cho45. All rights reserved.
//

import Cocoa
import ScriptingBridge

// 元にないやつは optional にしないと extension でエラーになる
@objc protocol SBSystemPreferencesApplication {
    @objc optional var panes: SBElementArray {get}
    func activate()
}


@objc protocol SBSystemPreferencesPane {
    @objc optional var anchors: SBElementArray {get}
    @objc optional var id: NSString {get}
    
}

@objc protocol SBSystemPreferencesAnchor {
    @objc optional var name: NSString {get}
    @objc optional func reveal() -> id_t
}

// protocol 定義を無理矢理使えるようにする
extension SBApplication : SBSystemPreferencesApplication {}
extension SBObject : SBSystemPreferencesPane, SBSystemPreferencesAnchor {}

struct Accessibility {
    static func checkAccessibilityEnabled(app: NSApplicationDelegate) {
        if !AXIsProcessTrusted() {
            let alert = NSAlert()
            alert.messageText = "Require accessibility setting"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Open System Preference")
            alert.addButton(withTitle: "Quit")
            if alert.runModal() ==  .OK {
                openSecurityPane()
                NSApplication.shared.terminate(app)
            } else {
                NSApplication.shared.terminate(app)
            }
        }
    }
    
    static func openSecurityPane() {
        // openURL 使うのが最も簡単だが、アクセシビリティの項目まで選択された状態で開くことができない
        // NSWorkspace.sharedWorkspace().openURL( NSURL.fileURLWithPath("/System/Library/PreferencePanes/Security.prefPane")! )
        
        // ScriptingBridge を使い、表示したいところまで自動で移動させる
        // open System Preference -> Security and Privacy -> Accessibility
        let prefs = SBApplication(bundleIdentifier: "com.apple.systempreferences")! as SBSystemPreferencesApplication
        prefs.activate()
        for pane_ in prefs.panes! {
            let pane = pane_ as! SBSystemPreferencesPane
            if pane.id == "com.apple.preference.security" {
                for anchor_ in pane.anchors! {
                    let anchor = anchor_ as! SBSystemPreferencesAnchor
                    if anchor.name == "Privacy_Accessibility" {
                        print(pane, anchor)
                        anchor.reveal!()
                        break
                    }
                }
                break
            }
        }
    }
}
