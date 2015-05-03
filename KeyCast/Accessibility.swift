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
    optional var panes: SBElementArray {get}
    func activate()
}


@objc protocol SBSystemPreferencesPane {
    optional var anchors: SBElementArray {get}
    optional var id: NSString {get}
    
}

@objc protocol SBSystemPreferencesAnchor {
    optional var name: NSString {get}
    optional func reveal() -> id_t
}

// protocol 定義を無理矢理使えるようにする
extension SBApplication : SBSystemPreferencesApplication {}
extension SBObject : SBSystemPreferencesPane, SBSystemPreferencesAnchor {}

struct Accessibility {
    static func checkAccessibilityEnabled(app: NSApplicationDelegate) {
        if AXIsProcessTrusted() != 1 {
            let alert = NSAlert()
            alert.messageText = "Require accessibility setting"
            alert.alertStyle = NSAlertStyle.CriticalAlertStyle
            alert.addButtonWithTitle("Open System Preference")
            alert.addButtonWithTitle("Quit")
            if alert.runModal() == 1000 {
                openSecurityPane()
                NSApplication.sharedApplication().terminate(app)
            } else {
                NSApplication.sharedApplication().terminate(app)
            }
        }
    }
    
    static func openSecurityPane() {
        // openURL 使うのが最も簡単だが、アクセシビリティの項目まで選択された状態で開くことができない
        // NSWorkspace.sharedWorkspace().openURL( NSURL.fileURLWithPath("/System/Library/PreferencePanes/Security.prefPane")! )
        
        // ScriptingBridge を使い、表示したいところまで自動で移動させる
        // open System Preference -> Security and Privacy -> Accessibility
        let prefs = SBApplication.applicationWithBundleIdentifier("com.apple.systempreferences")! as! SBSystemPreferencesApplication
        prefs.activate()
        for pane_ in prefs.panes! {
            let pane = pane_ as! SBSystemPreferencesPane
            if pane.id == "com.apple.preference.security" {
                for anchor_ in pane.anchors! {
                    let anchor = anchor_ as! SBSystemPreferencesAnchor
                    if anchor.name == "Privacy_Accessibility" {
                        println(pane, anchor)
                        anchor.reveal!()
                        break
                    }
                }
                break
            }
        }
    }
}