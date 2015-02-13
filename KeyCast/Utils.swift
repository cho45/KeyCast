import Cocoa

struct Utils {
    static let REPLACE_MAP: Dictionary<String, String> = [
        "\r"   : "↵\n",
        "\u{1B}"   : "⎋",
        "\t"   : "⇥",
        "\u{19}" : "⇤",
        " "    : "␣",
        "\u{7f}" : "⌫",
        "\u{03}" : "⌤",
        "\u{10}" : "⏏",
        "\u{F728}" : "⌦",
        "\u{F739}" : "⌧",
        "\u{F704}" : "[F1]",
        "\u{F705}" : "[F2]",
        "\u{F706}" : "[F3]",
        "\u{F707}" : "[F4]",
        "\u{F708}" : "[F5]",
        "\u{F709}" : "[F6]",
        "\u{F70A}" : "[F7]",
        "\u{F70B}" : "[F8]",
        "\u{F70C}" : "[F9]",
        "\u{F70D}" : "[F10]",
        "\u{F70E}" : "[F11]",
        "\u{F70F}" : "[F12]",

        "\u{F700}" : "↑",
        "\u{F701}" : "↓",
        "\u{F702}" : "←",
        "\u{F703}" : "→",
        "\u{F72C}" : "⇞",
        "\u{F72D}" : "⇟",
        "\u{F729}" : "↖",
        "\u{F72B}" : "↘",
    ]
    
    static func keyStringFromEvent(e: NSEvent)->(String, String) {
        var mod = ""
        if e.modifierFlags.rawValue &  NSEventModifierFlags.ControlKeyMask.rawValue != 0 {
            mod += "⌃"
        }
        if e.modifierFlags.rawValue &  NSEventModifierFlags.AlternateKeyMask.rawValue != 0 {
            mod += "⌥"
        }
        if e.modifierFlags.rawValue &  NSEventModifierFlags.ShiftKeyMask.rawValue != 0 {
            mod += "⇧"
        }
        if e.modifierFlags.rawValue &  NSEventModifierFlags.CommandKeyMask.rawValue != 0 {
            mod += "⌘"
        }
        
        let char = keyToReadableString(e.charactersIgnoringModifiers!.uppercaseString)
        
        return (mod, char)
    }
    
    static func keyToReadableString (string: String)-> String {
        var str = string
        for (k, v) in REPLACE_MAP {
            str = str.stringByReplacingOccurrencesOfString(k, withString: v)
        }
        return str
    }
}